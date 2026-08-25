variable "aws_region" {
  type = string
}

variable "desired_count" {
  type = number
}

variable "task_memory" {
  type = number
}

variable "task_cpu" {
  type = number
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "ecr_repository_url" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "project_name" {
  type = string
}