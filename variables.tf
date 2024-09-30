# variables.tf

variable "instance_type" {
  default = "t2.micro"
  type = string
  description = "Instance type for the web servers"
}

variable "ami_id" {
  type = string
  description = "AMI ID for the web servers"
}

variable "aws_region" {
  type = string
  description = "AWS region to deploy in"
  default = "us-west-2"
}

# ... (Other variables you might need)