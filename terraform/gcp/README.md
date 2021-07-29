# Security Onion in the Cloud
# DISCLAIMER: The following content was developed for usage with Security Onion 16.04 and has not yet been updated for Security Onion 2.

**NOTE: The Security Onion Google Image and associated scripts are still in testing, and are NOT recommended for production use.**

The following components are currently supported and are in testing:

- Security Onion Terraform Configuration 

### Configuring the Security Onion Instance and Packet Mirroring with Terraform

By using Terraform, one can quickly spin up Security Onion in Google Cloud, creating all the necessary components to faciliate packet mirroring.

#### Clone repo
`git clone https://github.com/Security-Onion-Solutions/securityonion-cloud
&& cd securityonion-cloud/terraform/gcp`

#### Install Terraform
##### Linux (recommended Ubuntu 18.04 or higher) or Mac (as root or with sudo privilieges):
`pip3 --upgrade pip`
`./install-terraform.sh`
##### Windows
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html#cliv2-windows-prereq   
https://www.terraform.io/downloads.html   
https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows   

#### Configure GCloud details
See the following for more details:   
https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu

#### Create public/private keypair for use with instance
`ssh-keygen -b 2048 -f ~/.ssh/securityonion`

#### Get your external IP (to allow access to your GCloud instance)
`dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'`

#### Modify config file with external IP for whitelist, and other details (like GCloud credentials file)
Edit `terraform.tfvars` with external IP/netmask (gathered above) for whitelist 

`Ex. "192.168.1.1/32"`

#### Initialize Terraform
`terraform init`

#### Build VPC Infrastructure and Instance
`terraform apply --auto-approve`   

The output from this command should provide you with the public IP address of your GCloud instance(s).

#### SSH into instance
`ssh -i ~/.ssh/securityonion onion@$instanceip`  

#### Run Setup   

`cd securityonion`
`sudo ./so-setup-network`

Follow the prompts in setup. When asked to choose the method for web access, choose `OTHER` and provide a name that can be mapped via a hosts file or resolvable via DNS.

##### Tear it down
The instance and VPC configuration can quickly be destroyed with the following:   
`terraform destroy --auto-approve`
