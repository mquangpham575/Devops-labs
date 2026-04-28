provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc-devops" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-devops"
  }
}

resource "aws_security_group" "public-security-group-devops" {
  name = "public-security-group-devops"
  vpc_id = aws_vpc.vpc-devops.id

}

resource "aws_vpc_security_group_egress_rule" "outbound-public" {
  security_group_id = aws_security_group.public-security-group-devops.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

resource "aws_vpc_security_group_ingress_rule" "inbound-public" {
  security_group_id = aws_security_group.public-security-group-devops.id
  cidr_ipv4 = "171.246.207.64/32"
  ip_protocol = "tcp"
  from_port = 22
  to_port = 22
}

resource "aws_internet_gateway" "internet_gateway-devops" {
    vpc_id = aws_vpc.vpc-devops.id
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc-devops.id
  

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway-devops.id
  }

  route {
    cidr_block = aws_vpc.vpc-devops.cidr_block
    gateway_id = "local"
  }
}

resource "aws_subnet" "public-subnet-devops" {
  vpc_id = aws_vpc.vpc-devops.id
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "public-subnet-devops"
  }
}

resource "aws_route_table_association" "route-table-public-subnet" {
  subnet_id = aws_subnet.public-subnet-devops.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_instance" "public-ec2-devops" {
  ami = "ami-04680790a315cd58d"
  instance_type = "t3.micro"
  tags = {
    Name = "public-ec2-devops"
  }
  associate_public_ip_address = true
  key_name = aws_key_pair.key-pair-devops.key_name
  # primary_network_interface {
    # network_interface_id = aws_network_interface.public-network-interface.id
  # }
  private_ip = "10.0.0.4"
  vpc_security_group_ids = [aws_security_group.public-security-group-devops.id]
  subnet_id = aws_subnet.public-subnet-devops.id
}

resource "aws_key_pair" "key-pair-devops" {
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDyF0nd30kDBg0SxUCF0nPi14v6Tm3TCTj22pCp2RZ3mzJCyvQ8ToXVoHGf/XOQnEh2cyL52bt0aEbudeBTWwSM3yE78UoUW8odNu00DUtjCTu9Ve2GspLEJl7tE4iveqpAbc0wAmbaTLF54Hmu6F/F/a1W5eZC8Y/JVeU+ewiH0l7oOjnNpFnthd5Oe52oczvllJ5Y7J+TubHNArm6u3vVJ99eNQ1oLL2jEYE+OlNoCwMCxy10nvge1kiMbLpj4b+IHFyfW797OZhrdTEqyS7qt1L/9WFNJq1OHIQEEQR1FJJ/ll14j2ttNKOFNDPySUrk3V7ucR8mgwV3JbkrrG44R5NUs12uScB8UsnyK6T40W4OxO9XJkNM3JkodcWD3lm7XMPphz3f6gCSLda0i2kq66N3g8wQaQlVQz72KeOQ7b2yznVCkr9vSJmOlXOEMWEtD4cDccgsjDwPPcxKIe5jN5VxrcfxjdG5Pql6mzv0TQ9wKbs0PAm+MbgVRe31K8M= v1nh2oz4@vinh-MS-7C52"
  key_name = "key-pair-devops"
  
}

# resource "aws_network_interface" "public-network-interface" {
#   subnet_id = aws_subnet.public-subnet-devops.id
#   private_ips  = ["10.0.0.4"]
#   security_groups = [aws_security_group.public-security-group-devops.id]
# }