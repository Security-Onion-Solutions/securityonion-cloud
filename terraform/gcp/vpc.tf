// Create Host VPC
resource "google_compute_network" "host_vpc" {
 name                    = "${var.host_vpc_name}"
 auto_create_subnetworks = "false"
}

// Create SO VPC
resource "google_compute_network" "so_vpc" {
 name                    = "${var.so_vpc_name}"
 auto_create_subnetworks = "false"
}

resource "google_compute_network_peering" "peering1" {
  depends_on = [ google_compute_network.host_vpc, google_compute_network.so_vpc ]
  name         = "peering1"
  network      = google_compute_network.host_vpc.self_link
  peer_network = google_compute_network.so_vpc.self_link
}

resource "google_compute_network_peering" "peering2" {
  depends_on = [ google_compute_network.host_vpc, google_compute_network.so_vpc ]
  name         = "peering2"
  network      = google_compute_network.so_vpc.self_link
  peer_network = google_compute_network.host_vpc.self_link
}
