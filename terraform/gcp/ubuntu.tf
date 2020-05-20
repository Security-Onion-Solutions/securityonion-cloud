resource "google_compute_instance" "host" {
  name          = "host1"
  machine_type  = "n1-standard-1"
  zone          =   "us-east1-b"
  tags          = ["mirror"]
  boot_disk {
    initialize_params {
      image     =  "ubuntu-os-cloud/ubuntu-1604-lts"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.host_subnet.name}"
    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    sshKeys = "ubuntu:${file(var.public_key_path)}"
  }
}
