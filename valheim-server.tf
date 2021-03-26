terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.61.0"
    }
  }
}

provider "google" {

  credentials = file("valheim-306722-2df11616a1bf.json")

  project = "valheim-306722"
  region  = "southamerica-east1"
  zone    = "southamerica-east1-a"
}

# Criação do ip externo
resource "google_compute_address" "static" {
  name = "valheim-terraform-ip"
  address_type = "EXTERNAL"
}

# Criação de regras do firewall
resource "google_compute_firewall" "default" {
  name    = "valheim-terraform-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["2456-2458"]
  }

  allow {
    protocol = "udp"
    ports    = ["2456-2458"]
  }

  source_tags = ["valheim-terraform"]
}

# Cria uma VM no Google Cloud
resource "google_compute_instance" "valheim-terraform" {
  name         = "valheim-terraform"
  machine_type = "e2-standard-2"
  tags         = ["valheim-terraform"]

  # Defini a Imagem da VM
  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20201014"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = "default"
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }
}
