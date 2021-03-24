region                  = "us-east-2"
profile                 = "terraform"
shared_credentials_file = "~/.aws/credentials"
public_key_name         = "securityonion"
public_key_path         = "~/.ssh/securityonion.pub"
private_key_path        = "~/.ssh/securityonion"
ip_whitelist            = ["0.0.0.0/32"] #Change this to your public ip/32
instance_type           = "t3a.xlarge"
auto_mirror             = true
ubuntu_hosts            = 0
windows_hosts           = 0
 
