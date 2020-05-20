resource "google_compute_instance" "sensor" {
  name          = "sensor"
  machine_type  = "n1-standard-1"
  zone          =   "us-east1-b"
  tags          = ["securityonion-sensor"]
  boot_disk {
    initialize_params {
      image     =  "projects/thisismyrandomprojmkay/global/images/securityonion"
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
    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    sshKeys = "ubuntu:${file(var.public_key_path)}"
  }
}

resource "google_compute_instance_group" "sensors" {
  depends_on = [ google_compute_instance.sensor ]
  name        = "securityonion-sensors"
  description = "Security Onion instance group"
  zone = "us-east1-b"
  instances = [
    google_compute_instance.sensor.self_link
  ]
}
