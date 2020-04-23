variable "region" {
  default = "us-east-1"
}

variable "onions" {
  default = 1
}

variable "onionuser" {
  default = "analyst"
}

variable "onionpass" {
  type    = list(string)
  default = [""]
}

variable "profile" {
  default = "terraform"
}

variable "availability_zone" {
  description = "https://www.terraform.io/docs/providers/aws/d/availability_zone.html"
  default     = ""
}

variable "shared_credentials_file" {
  description = "Path to your AWS credentials file"
  type        = string
  default     = "~/.aws/credentials"
}

variable "public_key_name" {
  description = "A name for AWS Keypair to use to auth to authenticate to Security Onion."
  default     = "securityonion"
}

variable "public_key_path" {
  description = "Path to the public key to be loaded into the Security Onion authorized_keys file"
  type        = string
  default     = "~/.ssh/securityonion.pub"
}

variable "private_key_path" {
  description = "Path to the private key to use to authenticate to Security Onion."
  type        = string
  default     = "~/.ssh/securityonion"
}

variable "ip_whitelist" {
  description = "A list of CIDRs that will be allowed to access the EC2 instances"
  type        = list(string)
  default     = [""]
}

variable "external_dns_servers" {
  description = "Configure lab to allow external DNS resolution"
  type        = list(string)
  default     = ["8.8.8.8"]
}

variable "ami" {
  type    = string
  default = "ami-023486790e5e80a3d"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "auto_mirror" {
  description = "If set to true, use 3CS AutoMirror to create sessions for eligible instances"
  type        = bool
}


variable "ubuntu_instance_ami" {
  type    = string
  default = "ami-03ffa9b61e8d2cfda"
}

variable "ubuntu_instance_type" {
  type    = string
  default = "t3.small"
}

variable "ubuntu_hosts" {
  default = 0
}

variable "windows_instance_ami" {
  type    = string
  default = "ami-08db69d5de9dc9245"
}

variable "windows_instance_type" {
  type    = string
  default = "t3.small"
}

variable "windows_hosts" {
  default = 0
}

