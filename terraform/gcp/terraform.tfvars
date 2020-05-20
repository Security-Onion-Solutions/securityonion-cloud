project                 = "<enterprojecthere>"
host_vpc_name           = "hosts"     
so_vpc_name             = "securityonion"
so_subnet_cidr          = "172.16.163.0/24"
host_subnet_cidr        = "172.16.164.0/24"
region                  = "us-east1"
profile                 = "terraform"
shared_credentials_file = "<your_credentials_file>"
public_key_name         = "securityonion"
public_key_path         = "~/.ssh/securityonion.pub"
private_key_path        = "~/.ssh/securityonion"
ip_whitelist            = "0.0.0.0/0" #Change this to your public ip/32

