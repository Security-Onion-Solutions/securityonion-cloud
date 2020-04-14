# Originally Written by: Jonathan Johnson
# Updated by: Dustin Lee for Security Onion
# Additions and updates by Wes Lambert for Security Onion and VPC Mirroring

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

# Security Group for Security Onion
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

resource "aws_key_pair" "auth" {
  key_name   = var.public_key_name
  public_key = file(var.public_key_path)
}

resource "aws_network_interface" "securityonion" {
  count           = var.onions
  subnet_id       = aws_subnet.default.id
  private_ips     = ["172.16.163.2${count.index}"]
  security_groups = [aws_security_group.securityonion_sniffing.id]
}

resource "aws_instance" "securityonion" {
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
  depends_on = [
    aws_network_interface_attachment.securityonion
  ]
}

resource "aws_ec2_traffic_mirror_filter" "so_mirror_filter" {
  description = "Security Onion Mirror Filter - Allow All"
  tags = {
    Name = "SO Mirror Filter"
  }
}

resource "aws_ec2_traffic_mirror_filter_rule" "so_outbound" {
  description = "SO Mirror Outbound Rule"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.so_mirror_filter.id
  destination_cidr_block = "0.0.0.0/0"
  source_cidr_block = "0.0.0.0/0"
  rule_number = 1
  rule_action = "accept"
  traffic_direction = "egress"
  protocol = 6
}

resource "aws_ec2_traffic_mirror_filter_rule" "so_inbound" {
  description = "SO Mirror Inbound Rule"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.so_mirror_filter.id
  destination_cidr_block = "0.0.0.0/0"
  source_cidr_block = "0.0.0.0/0"
  rule_number = 1
  rule_action = "accept"
  traffic_direction = "ingress"
  protocol = 6

  destination_port_range {
    from_port = 1
    to_port = 65535
  }
  source_port_range {
    from_port = 1
    to_port = 65535
  }
}

// The following implements AutoMirror functionality https://github.com/3CORESec/AWS-AutoMirror

resource "aws_iam_role_policy" "auto_mirror_policy" {
  name = "auto_mirror_policy"
  role = aws_iam_role.auto_mirror_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Sid": "AutoMirrorExecutionPolicy",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeTrafficMirrorFilters",
                "ec2:DescribeTrafficMirrorTargets",
                "ec2:CreateTags",
                "ec2:CreateTrafficMirrorSession",
                "ec2:DescribeTrafficMirrorSessions",
                "ec2:createTrafficMirrorFilterRule",
                "ec2:createTrafficMirrorFilter"
            ],
            "Resource": "*"
        }
    ]
  }
  EOF
}

resource "aws_iam_role" "auto_mirror_role" {
  name = "auto_mirror_role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "./AutoMirror/auto_mirror_lambda.js"
  output_path = "./AutoMirror/auto_mirror_lambda.zip"
}

resource "aws_lambda_function" "auto_mirror_lambda" {
  filename      = "${data.archive_file.zip.output_path}"
  function_name = "auto_mirror_lambda"
  role          = "${aws_iam_role.auto_mirror_role.arn}"
  handler       = "auto_mirror_lambda.handler"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"
  runtime          = "nodejs12.x"
  timeout = 30
}

resource "aws_cloudwatch_event_rule" "auto_mirror_rule" {
  name        = "auto_mirror_rule"
  description = "Configure mirror"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "detail": {
    "state": [
      "pending"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "auto_mirror_lambda" {
  rule      = "${aws_cloudwatch_event_rule.auto_mirror_rule.name}"
  target_id = "auto_mirror_lambda"
  arn       = "${aws_lambda_function.auto_mirror_lambda.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.auto_mirror_lambda.function_name}"
  principal     = "events.amazonaws.com"
  source_arn     = "${aws_cloudwatch_event_rule.auto_mirror_rule.arn}"
}
