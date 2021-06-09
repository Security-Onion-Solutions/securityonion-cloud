
data "google_compute_image" "so_image" {
  family  = "${var.so_image_family}"
  project = "${var.so_image_project}"
}

resource "google_compute_instance" "sensor" {
  name          = "${var.so_machine_name}"
  machine_type  = "${var.so_machine_type}"
  zone          =   "${var.zone}"
  tags          = ["securityonion-sensor"]
  boot_disk {
    initialize_params {
      image = data.google_compute_image.so_image.self_link
      size  = "${var.so_image_size}"
      type  = "pd-ssd" 
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.host_subnet.name}"
    access_config {
      // Ephemeral IP
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.so_subnet.name}"
  }

  metadata = {
    sshKeys = "${var.so_username}:${file(var.public_key_path)}"
  }
}

resource "null_resource" "configure_so" {
  depends_on = [ google_compute_instance.sensor ]
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y git",
      "git clone https://github.com/security-onion-solutions/securityonion",
    ]
    connection {
     type     = "ssh"
     user     = "${var.so_username}"
     host        = google_compute_instance.sensor.network_interface[0].access_config[0].nat_ip
     private_key = file(var.private_key_path)
    }
 }

}

resource "google_compute_instance_group" "sensors" {
  depends_on = [ google_compute_instance.sensor ]
  name        = "securityonion-sensors"
  description = "Security Onion instance group"
  zone = "${var.zone}"
  instances = [
    google_compute_instance.sensor.self_link
  ]
}


