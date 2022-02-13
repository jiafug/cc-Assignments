variable "gce_ssh_user" {}
variable "gce_ssh_pub_key_file" {}
variable "gce_project_id" {}

provider "google" {
  project = "${var.gce_project_id}"
  region = "europe-west4"
  zone = "europe-west4-a"
}

data "google_client_openid_userinfo" "me" {
}

resource "google_compute_network" "network" {
  name = "cc-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  name = "cc-subnetwork"
  ip_cidr_range = "10.10.0.0/24"
  network = google_compute_network.network.self_link
  region = "europe-west4"
}

resource "google_compute_firewall" "firewall" {
  name = "cc-external"
  network = google_compute_network.network.self_link
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["cc"]
}

resource "google_compute_firewall" "internal-firewall" {
  name = "cc-internal"
  network = google_compute_network.network.self_link
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.10.0.0/24"]
  target_tags = ["cc"]
}

# resource "google_compute_instance" "admin_instance" {
#   name = "admin-instance"
#   machine_type = "e2-micro"
#   tags = [ "cc" ]

#   boot_disk {
#     initialize_params {
#       image = "ubuntu-os-cloud/ubuntu-2004-lts"
#       size = 50
#     }
#   }

#   network_interface {
#     subnetwork = google_compute_subnetwork.subnetwork.self_link
#     network_ip = "10.10.0.10"

#     access_config {
#     }
#   }

#   metadata = {
#     ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
#   }
# }

resource "google_compute_instance" "vm_instance" {
  count = 4
  name = format("node%d", count.index+1)
  machine_type = "n2-standard-2"
  tags = [ "cc" ]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size = 100
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.self_link
    network_ip = format("10.10.0.1%d", count.index+1)

    access_config {
    }
  }

  metadata = {
    # ssh-keys = "${var.gce_ssh_user}:${file("admin-key.pub")}"
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }
}
