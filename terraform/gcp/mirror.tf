resource "google_compute_forwarding_rule" "default" {
  depends_on = [ google_compute_region_backend_service.backend ]
  name                  = "lb-forwarding-rule"
  provider              = google-beta
  is_mirroring_collector = true
  ip_protocol            = "TCP"
  region                = "us-east1"
  load_balancing_scheme = "INTERNAL"
  backend_service       = "${google_compute_region_backend_service.backend.self_link}"
  all_ports             = true
  allow_global_access   = true
  network               = "${var.so_vpc_name}"
  subnetwork            = "${google_compute_subnetwork.so_subnet.name}"
}

resource "google_compute_packet_mirroring" "mirror_policy" {
  provider = google-beta
  name = "securityonion-mirroring"
  description = "Mirror Policy for SO"
  network {
    url = google_compute_network.host_vpc.self_link
  }
  collector_ilb {
    url = google_compute_forwarding_rule.default.self_link
  }
  mirrored_resources {
    tags = ["mirror"]
    //instances {
    //  url = google_compute_instance.host.self_link
    //}
  }
}
