terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "terraform_lab1" {
    source = "./modules/terraform_lab1"
    vpc-cidr_block= "10.0.0.0/16"
    vpc-name= "vpc-devops"
    public-security_group-name= "public-security-group-devops"
    public-ip-ssh-ping= "0.0.0.0/0"
    public-subnet-cidr_block= "10.0.0.0/24"
    public-subnet-name= "public-subnet-devops"
    aws-ami-id = "ami-04680790a315cd58d"
    aws-instance_type = "t3.micro"
    aws-public-ec2-name = "public-ec2-devops"
    aws-private-ip-public-ec2 = "10.0.0.4"
    public-key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCpfQ74yUjx0V4B9ZA/gef5K+4SnK2BwnY/Ii7vuc5iXZ0mPp67BalDtnN3Mo4GaODm/9pBl0bZPkHi0TUErMXSksa2zymTVx4YNR2tRAFOLw45PzhQ44lx3TWDAntrfA5GgUMki6f93yoaRQ2tY+Ez2BpaCMxdF/xlqQSmUWmv4wg+nf2XcvXU2dhSwn8Xtt+BCVSScB0xF/f8CgxE7kQEFyJqZ7aJEBrSRWVEXRRubE2s4M7Y/GsR0uyHUrkPZxIGJ4/UsqC7XlB9gDX7fhspnrmgrsQfYPM3G/VRKNodatTomR9t88tU9e+oMczdsotE+yaHWS06PrIP1K62QAPl"
    public-key-name = "key-pair-devops"
    nat-gateway-name = "nat-private-devops"
    private-subnet-cidr_block = "10.0.1.0/24"
    private-subnet-name = "private-subnet-devops"
    private-security_group-name="private-security-group-devops"
    aws-private-ec2-name = "private-ec2-devops"
    aws-private-ip-private-ec2 = "10.0.1.8"
}