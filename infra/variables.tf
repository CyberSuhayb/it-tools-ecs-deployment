variable "project_name" {
  type    = string
  default = "it-tools"
}

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "domain_name" {
  type    = string
  default = "tm.awslabpro.uk"
}

variable "zone_id" {
  type    = string
  default = "Z10391493G1F374R4AXXZ"
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "default_cidr_block" {
  type    = string
  default = "0.0.0.0/0"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "Public subnet CIDR count must match the number of Availability Zones."
  }
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.azs)
    error_message = "Private subnet CIDR count must match the number of Availability Zones."
  }
}

variable "image_tag" {
  type    = string
  default = "b39dc66"

  validation {
    condition     = length(trimspace(var.image_tag)) > 0
    error_message = "Image tag must not be empty."
  }
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}