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

  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "tls_private_key" "valheim-ssh-key" {
  algorithm   = "RSA"
}

locals {
  ssh_pub_key_without_new_line = replace(tls_private_key.valheim-ssh-key.public_key_openssh, "\n", "")
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
  tags         = ["valheim-terraform","http-server","https-server"]


  # Defini a Imagem da VM
  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20201014"
    }

  }

  metadata = {
     ssh-keys = "${var.user}:${local.ssh_pub_key_without_new_line} ${var.user}"
  }

  network_interface {
    # A default network is created for all GCP projects
    network = "default"
    access_config {
      nat_ip = google_compute_address.static.address
    }

  }

  provisioner "remote-exec" {
    connection { 
      host = self.network_interface[0].access_config[0].nat_ip
      type    = "ssh"
      user    = var.user
      timeout = "500s"
      private_key = tls_private_key.valheim-ssh-key.private_key_pem
    }
    inline = ["touch teste.txt"]
   }

}
