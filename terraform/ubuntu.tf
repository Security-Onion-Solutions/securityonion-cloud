// This section is for the creation of Ubuntu hosts

resource "aws_instance" "ubuntu_instance" {
  depends_on = [ null_resource.mirror_session_del_wait, aws_lambda_function.auto_mirror_lambda ]
  count         = var.ubuntu_hosts != 0 ? var.ubuntu_hosts : 0
  instance_type = var.ubuntu_instance_type
  ami           = var.ubuntu_instance_ami

  tags = var.auto_mirror ? { Name = "ubuntu-${count.index}", Mirror = "True" } : { Name = "ubuntu-${count.index}" }

  subnet_id              = aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.securityonion.id]
  key_name               = aws_key_pair.auth.key_name
  private_ip             = "172.16.163.3${count.index}"
  root_block_device {
    delete_on_termination = true
    volume_size           = 30
  }
}

