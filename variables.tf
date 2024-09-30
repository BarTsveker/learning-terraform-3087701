# variables.tf

variable "instance_type" {
  default = "t2.micro"
  type = string
  description = "Instance type for the web servers"
}

variable "ami_id" {
  type = string
  description = "AMI ID for the web servers"
  default = "ami-0e86e20dae9224db8" 
}

variable "aws_region" {
  type = string
  description = "AWS region to deploy in"
  default = "us-west-2"
}

# ... (Other variables you might need)