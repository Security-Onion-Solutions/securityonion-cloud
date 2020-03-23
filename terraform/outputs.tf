output "Region" {
  value = var.region
}

output "securityonion_public_ips" {
  description = "Security Onion Training IP Addresses"
  value = aws_instance.securityonion[*].public_ip
}
