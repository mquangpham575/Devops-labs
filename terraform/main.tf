provider "aws" {
  region = "us-east-1"
}

module "terraform_lab1" {
    source = "./modules/terraform_lab1"
    vpc-cidr_block= "10.0.0.0/16"
    vpc-name= "vpc-devops"
    public-security_group-name= "public-security-group-devops"
    public-ip-ssh-ping= "171.246.207.64/32"
    public-subnet-cidr_block= "10.0.0.0/24"
    public-subnet-name= "public-subnet-devops"
    aws-ami-id = "ami-04680790a315cd58d"
    aws-instance_type = "t3.micro"
    aws-public-ec2-name = "public-ec2-devops"
    aws-private-ip-public-ec2 = "10.0.0.4"
    public-key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDyF0nd30kDBg0SxUCF0nPi14v6Tm3TCTj22pCp2RZ3mzJCyvQ8ToXVoHGf/XOQnEh2cyL52bt0aEbudeBTWwSM3yE78UoUW8odNu00DUtjCTu9Ve2GspLEJl7tE4iveqpAbc0wAmbaTLF54Hmu6F/F/a1W5eZC8Y/JVeU+ewiH0l7oOjnNpFnthd5Oe52oczvllJ5Y7J+TubHNArm6u3vVJ99eNQ1oLL2jEYE+OlNoCwMCxy10nvge1kiMbLpj4b+IHFyfW797OZhrdTEqyS7qt1L/9WFNJq1OHIQEEQR1FJJ/ll14j2ttNKOFNDPySUrk3V7ucR8mgwV3JbkrrG44R5NUs12uScB8UsnyK6T40W4OxO9XJkNM3JkodcWD3lm7XMPphz3f6gCSLda0i2kq66N3g8wQaQlVQz72KeOQ7b2yznVCkr9vSJmOlXOEMWEtD4cDccgsjDwPPcxKIe5jN5VxrcfxjdG5Pql6mzv0TQ9wKbs0PAm+MbgVRe31K8M= v1nh2oz4@vinh-MS-7C52"
    public-key-name = "key-pair-devops"
    nat-gateway-name = "nat-private-devops"
    private-subnet-cidr_block = "10.0.1.0/24"
    private-subnet-name = "private-subnet-devops"
    private-security_group-name="private-security-group-devops"
    aws-private-ec2-name = "private-ec2-devops"
    aws-private-ip-private-ec2 = "10.0.1.8"
}