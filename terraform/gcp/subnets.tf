// Create Security Onion Subnet
resource "google_compute_subnetwork" "so_subnet" {
 name          = "securityonion-subnet"
 ip_cidr_range = "${var.so_subnet_cidr}"
 network       = "${var.so_vpc_name}"
 depends_on    = ["google_compute_network.so_vpc"]
 region      = "${var.region}"
}

// Create host subnet
resource "google_compute_subnetwork" "host_subnet" {
 name          = "host--subnet"
 ip_cidr_range = "${var.host_subnet_cidr}"
 network       = "${var.host_vpc_name}"
 depends_on    = ["google_compute_network.host_vpc"]
 region      = "${var.region}"
}
