############################################
# TERRAFORM CONFIGURATION
############################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

############################################
# AWS PROVIDER
############################################
provider "aws" {
  region = "us-east-1"
}

############################################
# SECURITY GROUP
############################################
resource "aws_security_group" "app_sg" {
  name        = "jenkins-app-sg"
  description = "Security group for Jenkins deployed app"

  # SSH Access (Ansible / Jenkins)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application Access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Internet Access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "jenkins-app-sg"
    Environment = "dev"
  }
}

############################################
# EC2 INSTANCE
############################################
resource "aws_instance" "app_server" {
  ami                    = "ami-0fc5d935ebf8bc3bc"   # Ubuntu 22.04 (us-east-1)
  instance_type          = "t2.micro"
  key_name               = "keypair"
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name        = "jenkins-app-server"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

############################################
# OUTPUT VALUES
############################################
output "instance_public_ip" {
  description = "Public IP of the application server"
  value       = aws_instance.app_server.public_ip
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.app_server.id
}
