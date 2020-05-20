# Originally Written by: Jonathan Johnson
# Updated by: Dustin Lee for Security Onion
# Additions and updates by Wes Lambert for Security Onion and VPC Mirroring

resource "aws_key_pair" "auth" {
  key_name   = var.public_key_name
  public_key = file(var.public_key_path)
}

# Provide Region
provider "aws" {
  region = var.region
}

# Inital VPC
resource "aws_vpc" "terraform" {
  cidr_block = "172.16.0.0/16"
  tags = {
    Name = "SO Terraform VPC"
  }
}

# Internet Gateway creation
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.terraform.id
}

# Route table to give VPC internet
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.terraform.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# subnet creation
resource "aws_subnet" "default" {
  vpc_id                  = aws_vpc.terraform.id
  cidr_block              = "172.16.163.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
}

resource "aws_vpc_dhcp_options" "default" {
  domain_name_servers = concat(var.external_dns_servers)
}

resource "aws_vpc_dhcp_options_association" "default" {
  vpc_id          = aws_vpc.terraform.id
  dhcp_options_id = aws_vpc_dhcp_options.default.id
}

