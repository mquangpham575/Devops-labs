variable "vpc-cidr_block" {
  description = "the ipv4 cidr block for the vpc"
}

variable "vpc-name" {
  description = "vpc name tag"
}

variable "public-security_group-name" {
  description = "public security group name"
}

variable "public-ip-ssh-ping" {
  description = "client ip to allow ssh, ping from"
}

variable "public-subnet-cidr_block" {
  description = "the ipv4 cidr block for the public subnet"
}

variable "public-subnet-name" {
  description = "public subnet name"
}

variable "aws-ami-id" {
  description = "ami id for the ec2"
}

variable "aws-instance_type" {
  description = "instance type for the ec2"
}

variable "aws-public-ec2-name" {
  description = "name for the ec2"
}

variable "aws-private-ip-public-ec2" {
  description = "private ip for the public ec2"
}

variable "public-key" {
  description = "public key for authentication"
}

variable "public-key-name" {
  description = "public key name"
}

variable "nat-gateway-name" {
  description = "name for the nat gateway"
}

variable "private-subnet-cidr_block" {
  description = "the ipv4 cidr block for the private subnet"
}

variable "private-subnet-name" {
  description = "private subnet name"
}

variable "private-security_group-name" {
  description = "private security group name"
}

variable "aws-private-ec2-name" {
  description = "name for the private ec2"
}

variable "aws-private-ip-private-ec2" {
  description = "private ip for the private ec2"
}