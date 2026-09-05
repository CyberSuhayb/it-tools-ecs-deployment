# IT Tools ECS Deployment

A production-style container deployment on AWS ECS Fargate, running [IT Tools](https://github.com/CorentinTh/it-tools) behind an Application Load Balancer in a secure Multi-AZ VPC with public and private subnets. Infrastructure is provisioned through modular Terraform with remote state and locking in Amazon S3, and GitHub Actions automates container builds and infrastructure deployment using OIDC with no long-lived AWS credentials stored anywhere.

The application runs as an ECS Fargate task inside private subnets with no public IP, reachable only through the ALB. Docker images are stored in Amazon ECR and versioned by commit SHA. HTTPS is provided through AWS Certificate Manager, with Route 53 handling DNS. Amazon CloudWatch collects application logs from the running ECS task.

The infrastructure was first built manually through the AWS Console (ClickOps) to understand how ECS, the ALB, and the surrounding networking actually fit together, then torn down and rebuilt entirely as Terraform, split across five reusable modules. Three separated GitHub Actions pipelines handle building and pushing the image, deploying it to ECS, and applying infrastructure changes that are each independently triggerable, so a routine app deploy never risks touching the VPC or ALB.

Live at: https://tm.awslabpro.uk

## Table of Contents
- The Big Four Questions
- Architecture
- HTTPS
- Health Check
- CI/CD Pipelines
- Key Decisions
- Local Setup
- Project Structure
- Lessons Learned
- Future Improvements

## The Big Four Questions

**What is this app?**

IT Tools is an open source collection of everyday utilities for developers. IT Tools contains things like UUID and token generators, JSON/YAML/XML converters and dozens of similar tools. It is a single page frontend application with no backend or database and everything runs on the clients side in the browser. The server's only job is to serve those files.

**Why did you choose this application?**

I chose this application because IT Tools is lightweight enough that I could spend all my time on the infrastructure and deployment side rather than debugging application code. This application allowed me to learn AWS, Docker, networking, Terraform, and CI/CD. 

**Why did you host it on ECS instead of a VM or a free host like Vercel or Netlify?**

Vercel or Netlify would have had this application online in minutes, which is exactly why I didn't use them. I wanted hands on experience with how containerised appliactions are really deployed and operated on cloud infrastructure. I chose ECS Fargate specifically so I could focus on container orchestration itself, without also having to patch, scale, or manage the underlying host. 

**How many users are there, or how many are you expecting?**

Currently there aren't any production users. This project was built to learn and demonstrate cloud deployment. As it is currently configured, a single ECS Fargate task should handle around 50 concurrent users without issue, though this is dependent on a number of factors, for example the exact number and the kind of requests that are coming in and how much load each on puts on the task. However if I required more resources I could scale up the task's CPU and memory, or I could simply run more tasks behind the same Application Load Balancer. This straightforward part of scaling is the main reason in choosing this setup in the first place.

## Architecture

![Architecture](docs/architecture-diagram.png)

The VPC spans two Availability Zones, eu-west-2a and eu-west-2b. The ALB and NAT Gateway sit in public subnets. The ECS task runs in a private subnet with no public IP and it has no direct route to or from the internet. Outbound traffic (pulling from ECR, sending logs to CloudWatch) goes through the NAT Gateway. The ALB is the only internet-facing component in the whole stack.

## HTTPS

- Certificate issued and DNS-validated via AWS Certificate Manager, against a Route53 hosted zone for awslabpro.uk
- Since the domain was registered through Cloudflare rather than Route53, I delegated just the tm subdomain to Route53 using NS records, rather than migrating the whole domain and the Route53 only needed to own DNS validation and routing for this one subdomain
- ALB listener on 443 forwards to the ECS target group
- ALB listener on 80 issues a permanent redirect to 443

![App running live over HTTPS](docs/https.png)

## Health Check

nginx serves a dedicated /health location returning a status of ok, independent of the app's static files. This is used by:
- The ALB target group's health check, which expects HTTP 200
- The CI/CD deploy pipeline's post-deploy verification step, which fails the pipeline if the app doesn't respond healthy after a deployment

![Health check response](docs/health-check.png)

## CI/CD Pipelines

Three separated GitHub Actions workflows, each usable manually via workflow dispatch, all authenticating to AWS through OIDC. GitHub issues a short-lived identity token per run, which AWS exchanges for temporary credentials scoped to a single IAM role trusted only by this specific repository. No AWS access keys exist in GitHub at all.

**1. Build and Push to ECR** — triggers on push to the app source, Dockerfile, or nginx config. Builds the Docker image, tags it with the commit SHA, pushes to ECR.

![Build and push workflow](docs/workflow-build-push.png)

**2. Deploy App to ECS** — chained to run automatically after Build and Push succeeds. Fetches the current task definition, swaps in the new image tag, registers it as a new revision, updates the ECS service, waits for the service to stabilize, then verifies the health endpoint.

![Deploy app workflow](docs/workflow-deploy-app.png)

**3. Terraform Deploy** — triggers only on changes inside the infra folder, kept deliberately separate from app deploys so a code change never risks touching live infrastructure. Runs a formatting check, validation, plan saved to a file, then apply on that exact saved plan.

![Terraform deploy workflow](docs/workflow-terraform-deploy.png)

**4. Terraform Destroy** — manual-only, gated behind typing "destroy" as an explicit workflow input. Never runs automatically.

![Terraform destroy workflow](docs/workflow-terraform-destroy.png)

## Key Decisions

- I put the ECS task in a private subnet with no public IP, so the ALB is the only way in from the internet. 
- I separated app-deploy and infra-deploy pipelines because real teams don't run a full Terraform apply on every app code change; infra changes are rarer and reviewed separately from routine app deploys. Coupling them risks an app change accidentally touching the VPC, ALB, or security groups.
- I created a remote Terraform state in S3 rather than leaving it on my local machine and if my laptop died or I lost the files, there'd be no way to recover the state, and there's also a real risk of accidentally committing sensitive state data to git if it's just sitting locally. I enabled versioning on the bucket and blocked all public access to it.
- I used immutable ECR tags with a lifecycle policy. Every image pushed gets a unique tag based on the commit SHA, so nothing ever gets silently overwritten. I also added a lifecycle policy that automatically cleans up old, untagged images so the repository dosen't just keep building up unused files over time.
- I chose pnpm instead of npm because the app's lockfile was built specifically for pnpm. When I first tried installing with plain npm, it quietly resolved a different, incompatible version of one dependency. The build failed, but the error didn't point anywhere near the real cause so I had to dig fairly deep into the stack trace before realizing it was actually a package manager mismatch.
## Local Setup

### Prerequisites
- Docker Desktop
- Terraform 1.5 or newer
- AWS CLI v2, authenticated with permissions to create the resources this project provisions
- An existing Route53 hosted zone or delegated subdomain for your domain

### Steps

1. Clone the repository and enter it.
2. Build and test the container locally and build the image, run it mapping port 80 to the container's 8080, then check that the health endpoint on localhost returns a status of ok.
3. Push the image to ECR once, before Terraform's ECS service can pull it, authenticate Docker to ECR, tag the local image, and push it.
4. From the infra folder, run terraform init, then plan and apply, supplying your Route53 zone ID and an image tag as variables.
5. Verify the live app by checking your domain's health endpoint over HTTPS.

For CI/CD, set two GitHub repository secrets: one holding the IAM role ARN, and one holding the Route53 zone ID.

## Project Structure

```
├── app/                     IT Tools application source
├── infra/                   Terraform
│   ├── main.tf                Root module, wires all modules together
│   ├── variables.tf
│   ├── output.tf
│   ├── provider.tf
│   ├── backend.tf             S3 remote state and locking
│   └── modules/
│       ├── vpc/                 VPC, public and private subnets, IGW, NAT
│       ├── ecr/                  Container registry, lifecycle policy
│       ├── acm/                   Certificate and DNS validation
│       ├── alb/                    Load balancer, listeners, target group
│       └── ecs/                     Cluster, task definition, service, IAM
├── .github/workflows/       CI/CD pipelines
├── docs/                    Screenshots and diagrams
├── Dockerfile                Multi-stage build, non-root nginx runtime
├── nginx.conf
└── README.md
```

## Lessons Learned

- GitHub's OIDC trust policy needs to account for numeric owner and repository IDs, not just names and the older wildcard pattern most docs show will fail with a vague "not authorized" error.
- The AWS credentials action also needs sts:TagSession trusted alongside the main assume-role permission, or the whole thing fails silently.
- The app's lockfile was pnpm-specific; installing with plain npm resolved a different dependency version and broke the build in a confusing way.
- A Terraform formatting check will fail CI on style alone, even when the code works so its worth running locally first.
- Changing a subnet's Availability Zone forces a destroy-and-recreate, and the ALB can take a while to release its old network interface before that can complete.

## Future Improvements

- Scope the CI/CD IAM role down to exact actions and resources instead of broad managed policies.
- Add a step that automatically checks the Terraform code for common mistakes before it runs, and a notification so I know a pipeline finished without having to check GitHub myself.
- Move account-specific values into AWS Systems Manager Parameter Store instead of passing them as plain Terraform variables.
- Add a second NAT Gateway, one per Availability Zone, for resilience across both Availability Zones.
- Add ECS auto-scaling based on CPU and memory utilization
