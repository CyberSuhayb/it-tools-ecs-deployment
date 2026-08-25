variable "project_name" {
  description = "Name prefix used for tagging and naming ALB resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC where the ALB and target group will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener"
  type        = string
}

variable "container_port" {
  description = "Port the application container listens on"
  type        = number
}