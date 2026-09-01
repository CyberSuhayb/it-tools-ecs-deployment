# IT Tools ECS Deployment

Self-hosted IT Tools (https://github.com/CorentinTh/it-tools), containerised and deployed on AWS ECS Fargate with HTTPS and a custom domain.

## Architecture Diagram 
## Architecture

```mermaid
flowchart TD
    U[Internet users] --> R53[Route53 + ACM<br/>tm.awslabpro.uk / HTTPS]
    R53 --> ALB[Application Load Balancer<br/>Public subnet]

    subgraph VPC["VPC — 10.0.0.0/16"]
        subgraph PUB["Public subnets (2 AZs)"]
            ALB
            NAT[NAT Gateway]
        end
        subgraph PRIV["Private subnets (2 AZs)"]
            ECS[ECS Fargate task<br/>IT Tools :8080<br/>No public IP]
        end
        ALB --> ECS
        ECS --> NAT
    end

    NAT --> ECR[ECR repository]
    ECS --> CW[CloudWatch Logs]

    subgraph CICD["CI/CD — GitHub Actions (OIDC)"]
        GH[Push to main] --> BP[Build & push image]
        BP --> ECR
        BP --> DEP[Deploy: update ECS service]
        DEP --> ECS
        TFD[Terraform deploy] -.manages.-> VPC
    end
```

## HTTPS
TODO

## Health Check
See /docs

## CI/CD Pipelines


## Local Setup
#Prerequisites

## Project Structure


## Lessons Learned

## Future Improvements
