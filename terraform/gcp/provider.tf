// Configure the Google Cloud provider
provider "google" {
 credentials = "${file("${var.shared_credentials_file}")}"
 project     = "${var.project}"
 region      = "${var.region}"
}

// Configure the Google Cloud Beta provider
provider "google-beta" {
 credentials = "${file("${var.shared_credentials_file}")}"
 project     = "${var.project}"
 region      = "${var.region}"
}

