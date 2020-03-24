# Security Onion in the Cloud
**NOTE: The Security Onion AMI and associated scripts are still in testing, and are NOT recommended for production use.**

The following components are currently supported and are in testing:

- Security Onion AMI (AWS)
- Security Onion Terraform Configuration 

### Security Onion AMI   
The latest version available can be located under the AWS Community AMIs, titled:

`Security-Onion-16.04-2020-03-24-1209`   

- us-east-1   
`ami-01ace718c1a93684e`   
- us-east-2   
`ami-0177df706d9ec9e38`   


### Configuring the Security Onion AMI and VPC Traffic Mirroring with Terraform
Special thanks goes to Jonathan Johnson (@jsecurity101) and Dustin Lee (@dlee35),for their existing work on the base Terraform configuration and Security Onion additions!

By using Terraform, one can quickly spin up Security Onion in AWS, provided you have an existing AWS account.

**PLEASE NOTE**: The default size EC2 instance used by the Terraform scripts is `t3.medium`, which is the **minimum** recommended size (2 cores/4GB RAM) to use while testing Security Onion in AWS.  Given that this instance is not free-tier eligible, you or your organization may be charged by AWS as a result of using an instance of this size or VPC mirroring -- we do not charge anything for the use of the Security Onion AMI itself.

#### Clone repo
`git clone -b dev https://github.com/Security-Onion-Solutions/securityonion-cloud
&& cd securityonion-cloud/terraform`

#### Install Terraform and AWS CLI
##### Linux (recommended Ubuntu 18.04 or higher) or Mac:
`./install-terraform-awscli.sh`
##### Windows
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html#cliv2-windows-prereq   
https://www.terraform.io/downloads.html   
https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows   

#### Configure AWS details
See the following for more details:   
https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html#cli-quick-configuration


`aws configure` (Provide secret/access key, etc)

#### Create public/private keypair for use with instance
`ssh-keygen -b 2048 -f ~/.ssh/securityonion`

#### Get your external IP (to allow access to your AWS instance)
`dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'`

#### Modify config file with external IP for whitelist
Edit `terraform.tfvars` with external IP/netmask (gathered above) for whitelist 

`Ex. "192.168.1.1/32"`

#### Initialize Terraform
`terraform init`

#### Build VPC Infrastructure and Instance
`terraform apply --auto-approve`   

The output from this command should provide you with the public IP address of your EC2 instance.

#### SSH into instance
`ssh -i ~/.ssh/securityonion onion@$instanceip`  

#### Run Setup   
Run setup with `sosetup-minimal` to configure Security Onion on smaller-sized instances.   

Otherwise, run setup with `sosetup` as you normally would.   

Alternatively, if you simply want to verify VXLAN traffic is being mirrored to the Security Onion sniffing interface, do something like the following once logged in:   

`ifconfig ens6 up`   
`tcpdump -nni ens6`

#### Note
Currently, only the traffic of the primary interface of the Security Onion instance is mirrored to the sniffing interface (to illustrate collection of VXLAN traffic, etc).  You may consider setting up additional mirror sessions if you wish to mirror traffic from other instances.

#### Tear it down
The instance and VPC configuration can quickly be destroyed with the following:   
`terraform destroy --auto-approve`
