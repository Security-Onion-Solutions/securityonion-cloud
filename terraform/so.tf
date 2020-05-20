# Originally Written by: Jonathan Johnson
# Updated by: Dustin Lee for Security Onion
# Additions and updates by Wes Lambert for Security Onion and VPC Mirroring

resource "aws_security_group" "securityonion" {
  name        = "securityonion_security_group"
  description = "SecurityOnion: Security Group"
  vpc_id      = aws_vpc.terraform.id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ip_whitelist
  }

  # Kibana Access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.ip_whitelist
  }

  # private subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.16.163.0/24"]
  }

  # Connect to Internet Gateway - internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Sniffing Group for Security Onion
resource "aws_security_group" "securityonion_sniffing" {
  name        = "securityonion_sniffing_security_group"
  description = "SecurityOnion: Sniffing Security Group"
  vpc_id      = aws_vpc.terraform.id


  # private subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.16.163.0/24"]
  }
}

resource "aws_network_interface" "securityonion" {
  count           = var.onions
  subnet_id       = aws_subnet.default.id
  private_ips     = ["172.16.163.2${count.index}"]
  security_groups = [aws_security_group.securityonion_sniffing.id]
}

resource "aws_instance" "securityonion" {
  depends_on = [ aws_internet_gateway.default ]
  count         = var.onions
  instance_type = var.instance_type
  ami           = var.ami

  tags = {
    Name = "security-onion-${count.index}"
  }

  subnet_id              = aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.securityonion.id]
  key_name               = aws_key_pair.auth.key_name
  private_ip             = "172.16.163.1${count.index}"

  provisioner "remote-exec" {
    inline = [
      "echo '127.0.0.1 securityonion-${count.index}' | sudo tee -a /etc/hosts",
      "sudo hostnamectl set-hostname securityonion-${count.index}",
    ]
    connection {
      host        = coalesce(self.public_ip, self.private_ip)
      type        = "ssh"
      user        = "onion"
      private_key = file(var.private_key_path)
    }
  }

  root_block_device {
    delete_on_termination = true
    volume_size           = 50
  }
}

resource "aws_network_interface_attachment" "securityonion" {
  depends_on = [ aws_instance.securityonion ]
  count                = var.onions
  instance_id          = aws_instance.securityonion[count.index].id
  network_interface_id = aws_network_interface.securityonion[count.index].id
  device_index         = 1
}

resource "aws_ec2_traffic_mirror_target" "security_onion_sniffing" {
  count                = var.onions
  description          = "SO Sniffing Interface Target"
  network_interface_id = aws_network_interface.securityonion[count.index].id
  tags = {
    Name = "SO Mirror Target"
  }

  depends_on = [ aws_network_interface_attachment.securityonion ]
}

resource "aws_ec2_traffic_mirror_filter" "so_mirror_filter" {
  depends_on = [ aws_ec2_traffic_mirror_target.security_onion_sniffing  ]
  description = "Security Onion Mirror Filter - Allow All"
  tags = {
    Name = "SO Mirror Filter"
  }
}

resource "aws_ec2_traffic_mirror_filter_rule" "so_outbound" {
  depends_on = [ aws_ec2_traffic_mirror_filter.so_mirror_filter ]
  description = "SO Mirror Outbound Rule"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.so_mirror_filter.id
  destination_cidr_block = "0.0.0.0/0"
  source_cidr_block = "0.0.0.0/0"
  rule_number = 1
  rule_action = "accept"
  traffic_direction = "egress"
}

resource "aws_ec2_traffic_mirror_filter_rule" "so_inbound" {
  depends_on = [ aws_ec2_traffic_mirror_filter.so_mirror_filter ]
  description = "SO Mirror Inbound Rule"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.so_mirror_filter.id
  destination_cidr_block = "0.0.0.0/0"
  source_cidr_block = "0.0.0.0/0"
  rule_number = 1
  rule_action = "accept"
  traffic_direction = "ingress"
}
