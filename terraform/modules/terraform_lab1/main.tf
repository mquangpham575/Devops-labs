provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc-devops" {
  cidr_block = var.vpc-cidr_block
  tags = {
    Name = var.vpc-name
  }
}

resource "aws_security_group" "public-security-group-devops" {
  name = var.public-security_group-name
  vpc_id = aws_vpc.vpc-devops.id

}

resource "aws_vpc_security_group_egress_rule" "outbound-public" {
  security_group_id = aws_security_group.public-security-group-devops.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

resource "aws_vpc_security_group_ingress_rule" "public-inbound-public-ssh" {
  security_group_id = aws_security_group.public-security-group-devops.id
  cidr_ipv4 = var.public-ip-ssh-ping
  ip_protocol = "tcp"
  from_port = 22
  to_port = 22
}

resource "aws_vpc_security_group_ingress_rule" "public-inbound-public-ping" {
  security_group_id = aws_security_group.public-security-group-devops.id
  cidr_ipv4 = var.public-ip-ssh-ping
  ip_protocol = "icmp"
  from_port = -1
  to_port = -1
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
  cidr_block = var.public-subnet-cidr_block
  tags = {
    Name = var.public-subnet-name
  }
}

resource "aws_route_table_association" "route-table-public-subnet" {
  subnet_id = aws_subnet.public-subnet-devops.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_instance" "public-ec2-devops" {
  ami = var.aws-ami-id
  instance_type = var.aws-instance_type
  tags = {
    Name = var.aws-public-ec2-name
  }
  associate_public_ip_address = true
  key_name = aws_key_pair.key-pair-devops.key_name
  # primary_network_interface {
    # network_interface_id = aws_network_interface.public-network-interface.id
  # }
  private_ip = var.aws-private-ip-public-ec2
  vpc_security_group_ids = [aws_security_group.public-security-group-devops.id]
  subnet_id = aws_subnet.public-subnet-devops.id
}

resource "aws_key_pair" "key-pair-devops" {
  public_key = var.public-key
  key_name = var.public-key-name
  
}

# resource "aws_network_interface" "public-network-interface" {
#   subnet_id = aws_subnet.public-subnet-devops.id
#   private_ips  = ["10.0.0.4"]
#   security_groups = [aws_security_group.public-security-group-devops.id]
# }

resource "aws_nat_gateway" "nat-private-devops" {
  tags = {
    Name = var.nat-gateway-name
  }
  availability_mode = "regional"
  connectivity_type = "public"
  vpc_id = aws_vpc.vpc-devops.id
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.vpc-devops.id
  

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-private-devops.id
  }

  route {
    cidr_block = aws_vpc.vpc-devops.cidr_block
    gateway_id = "local"
  }
}

resource "aws_subnet" "private-subnet-devops" {
  vpc_id = aws_vpc.vpc-devops.id
  cidr_block = var.private-subnet-cidr_block
  tags = {
    Name = var.private-subnet-name
  }
}

resource "aws_route_table_association" "route-table-private-subnet" {
  subnet_id = aws_subnet.private-subnet-devops.id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_security_group" "private-security-group-devops" {
  name = var.private-security_group-name
  vpc_id = aws_vpc.vpc-devops.id

}

resource "aws_vpc_security_group_egress_rule" "outbound-private" {
  security_group_id = aws_security_group.private-security-group-devops.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

resource "aws_vpc_security_group_ingress_rule" "inbound-private-ping" {
  security_group_id = aws_security_group.private-security-group-devops.id
  referenced_security_group_id = aws_security_group.public-security-group-devops.id
  ip_protocol = "icmp"
  from_port = -1
  to_port = -1
}

resource "aws_vpc_security_group_ingress_rule" "inbound-private-ssh" {
  security_group_id = aws_security_group.private-security-group-devops.id
  referenced_security_group_id = aws_security_group.public-security-group-devops.id
  ip_protocol = "tcp"
  from_port = 22
  to_port = 22
}

resource "aws_instance" "private-ec2-devops" {
  ami = var.aws-ami-id
  instance_type = var.aws-instance_type
  tags = {
    Name = var.aws-private-ec2-name
  }
  associate_public_ip_address = false
  key_name = aws_key_pair.key-pair-devops.key_name
  # primary_network_interface {
    # network_interface_id = aws_network_interface.private-network-interface.id
  # }
  private_ip = var.aws-private-ip-private-ec2
  vpc_security_group_ids = [aws_security_group.private-security-group-devops.id]
  subnet_id = aws_subnet.private-subnet-devops.id
}
# test 2