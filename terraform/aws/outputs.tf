output "Region" {
  value = var.region
}

output "securityonion_public_ips" {
  description = "Security Onion Public IP Address(es)"
  value = aws_instance.securityonion[*].public_ip
}

output "windows_public_ips" {
  description = "Windows Instance IP Address(es)"
  value = aws_instance.windows_instance[*].public_ip
}

output "ubuntu_public_ips" {
  description = "Ubuntu Instance IP Address(es)"
  value = aws_instance.ubuntu_instance[*].public_ip
}


