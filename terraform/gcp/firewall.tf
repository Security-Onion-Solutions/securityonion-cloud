// Host VPC firewall configuration
resource "google_compute_firewall" "host_firewall" {
  name    = "${var.host_vpc_name}-firewall"
  network = "${google_compute_network.host_vpc.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [ "${var.ip_whitelist}" ]
}

// SO VPC firewall configuration
resource "google_compute_firewall" "so_firewall" {
  name    = "${var.so_vpc_name}-firewall"
  network = "${google_compute_network.so_vpc.name}"

  allow {
    protocol = "tcp"
    ports = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports = ["0-65535"]
  }

  // Allow all traffic to be mirrored
  source_ranges = [ "0.0.0.0/0" ]
  
  //source_ranges = [ "${var._subnet_cidr}", "${var.ip_whitelist}" ]
}
