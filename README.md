# IT Tools ECS Deployment

A production-style container deployment on AWS ECS Fargate, running [IT Tools](https://github.com/CorentinTh/it-tools) behind an Application Load Balancer in a secure Multi-AZ VPC with public and private subnets. Infrastructure is provisioned through modular Terraform with remote state and locking in Amazon S3, and GitHub Actions automates container builds and infrastructure deployment using OIDC — no long-lived AWS credentials stored anywhere.

The application runs as an ECS Fargate task inside private subnets with no public IP, reachable only through the ALB. Docker images are stored in Amazon ECR and versioned by commit SHA. HTTPS is provided through AWS Certificate Manager, with Route 53 handling DNS. Amazon CloudWatch collects application logs from the running ECS task.

The infrastructure was first built manually through the AWS Console (ClickOps) to understand how ECS, the ALB, and the surrounding networking actually fit together, then torn down and rebuilt entirely as Terraform, split across five reusable modules. Three separated GitHub Actions pipelines handle building and pushing the image, deploying it to ECS, and applying infrastructure changes — each independently triggerable, so a routine app deploy never risks touching the VPC or ALB.

Live at: https://tm.awslabpro.uk

## Table of Contents
- Architecture
- What is this application?
- HTTPS
- Health Check
- CI/CD Pipelines
- Key Decisions
- Local Setup
- Project Structure
- Lessons Learned
- Future Improvements

## Architecture

![Architecture](docs/architecture.png)

The VPC spans two Availability Zones, eu-west-2a and eu-west-2c. The ALB and NAT Gateway sit in public subnets; the ECS task runs in a private subnet with no public IP — it has no direct route to or from the internet. Outbound traffic (pulling from ECR, sending logs to CloudWatch) goes through the NAT Gateway. The ALB is the only internet-facing component in the whole stack.

This goes beyond the project brief's minimum requirement of a VPC with public subnets — a service running with a public IP is a real exposure risk in production, so the private-subnet split was worth the extra NAT Gateway module.

## What is this application?

IT Tools is a free, open-source collection of everyday developer utilities (UUID generators, JSON formatters, encoders, hash generators, and more) served as a single static frontend. I picked it because it's lightweight, has no backend or database dependency, and let me focus entirely on the deployment and infrastructure side rather than debugging application code — the whole point of this project was learning ECS, Terraform, and CI/CD, not building an app.

## HTTPS

- Certificate issued and DNS-validated via AWS Certificate Manager, against a Route53 hosted zone for awslabpro.uk
- Since the domain was registered through Cloudflare rather than Route53, I delegated just the tm subdomain to Route53 using NS records, rather than migrating the whole domain — Route53 only needed to own DNS validation and routing for this one subdomain
- ALB listener on 443 forwards to the ECS target group
- ALB listener on 80 issues a permanent redirect to 443

![App running live over HTTPS](docs/https.png)

## Health Check

nginx serves a dedicated /health location returning a status of ok, independent of the app's static files. This is used by:
- The ALB target group's health check, which expects HTTP 200
- The CI/CD deploy pipeline's post-deploy verification step, which fails the pipeline if the app doesn't respond healthy after a deployment

![Health check response](docs/health-check.png)

## CI/CD Pipelines

Three separated GitHub Actions workflows, each usable manually via workflow dispatch, all authenticating to AWS through OIDC — GitHub issues a short-lived identity token per run, which AWS exchanges for temporary credentials scoped to a single IAM role trusted only by this specific repository. No AWS access keys exist in GitHub at all.

**1. Build and Push to ECR** — triggers on push to the app source, Dockerfile, or nginx config. Builds the Docker image, tags it with the commit SHA, pushes to ECR.

![Build and push workflow](docs/workflow-build-push.png)

**2. Deploy App to ECS** — chained to run automatically after Build and Push succeeds. Fetches the current task definition, swaps in the new image tag, registers it as a new revision, updates the ECS service, waits for the service to stabilize, then verifies the health endpoint.

![Deploy app workflow](docs/workflow-deploy-app.png)

**3. Terraform Deploy** — triggers only on changes inside the infra folder, kept deliberately separate from app deploys so a code change never risks touching live infrastructure. Runs a formatting check, validation, plan
