# Security Onion in the Cloud
**NOTE: The Security Onion Google Image and associated scripts are still in testing, and are NOT recommended for production use.**

The following components are currently supported and are in testing:

- Security Onion Google Image
- Security Onion Terraform Configuration 


### Configuring the Security Onion Image and Packet Mirroring with Terraform

By using Terraform, one can quickly spin up Security Onion in Google Cloud, creating all the necessary components to faciliate packet mirroring.


#### Clone repo
`git clone https://github.com/Security-Onion-Solutions/securityonion-cloud
&& cd securityonion-cloud/terraform/gcp`

#### Install Terraform
##### Linux (recommended Ubuntu 18.04 or higher) or Mac (as root or with sudo privilieges):
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

#### Enable additional monitored hosts
`ubuntu_hosts` is set to `0` by default in `terraform.tfvars`.

You can specify up to `10` host instances that will have packet mirroring automatically configured for them so they can be immediately monitored by Security Onion.  

Please note, typical GCloud infrastructure pricing still applies! 

#### Initialize Terraform
`terraform init`

#### Build VPC Infrastructure and Instance
`terraform apply --auto-approve`   

The output from this command should provide you with the public IP address of your GCloud instance(s).

#### SSH into instance
`ssh -i ~/.ssh/securityonion onion@$instanceip`  

#### Run Setup   
Run setup with `sosetup-minimal` to configure Security Onion on smaller-sized instances, choosing `Suricata` as the NIDS.   

Otherwise, run setup with `sosetup` as you normally would, choosing `Suricata` as the NIDS.   

Alternatively, if you simply want to verify VXLAN traffic is being mirrored to the Security Onion sniffing interface, do something like the following once logged in:   

`ifconfig ens6 up`   
`tcpdump -nni ens6`
##### MTU
After running setup, you may also want to alter the MTU of the sniffing interface to ensure you are able to capture all traffic you are expecting.

This can be done by running the following command...

`sudo ifconfig <sniffing int> mtu 1575`

...and modifying `/etc/network/interfaces` to contain the following line at the end of the sniffing interface block:

`mtu 1575`

##### Suricata VXLAN
Enable VXLAN decap for Suricata:

`Edit /etc/nsm/<sensorname-interface/suricata.yaml`

```
vxlan
  enabled: false
```

to 

```
vxlan
  enabled: true
```
Then run:

`sudo so-nids-restart`

##### Tear it down
The instance and VPC configuration can quickly be destroyed with the following:   
`terraform destroy --auto-approve`
