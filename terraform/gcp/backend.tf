// Backend service for relaying mirror packets to sensors
resource "google_compute_region_backend_service" "backend" {
  name                  = "lb-backend"
  region                = "us-east1"
  health_checks         = ["${google_compute_health_check.hc.self_link}"]
  network               = "${var.so_vpc_name}"
  backend {
    group = google_compute_instance_group.sensors.self_link
  }

}
resource "google_compute_health_check" "hc" {
  name               = "check-lb-backend"
  check_interval_sec = 1
  timeout_sec        = 1
  tcp_health_check {
    port = "80"
  }
}
