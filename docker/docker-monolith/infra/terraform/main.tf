terraform {
  # Версия terraform
  required_version = "~>0.12.19"
}
provider "google" {
  # Версия провайдера
  version = "~>2.5.0"
  # ID проекта
  project = var.project
  region  = var.region
}

resource "google_compute_instance" "app" {
  count = var.count_instance
  name         = "reddit-app-${count.index}"
  machine_type = "f1-micro"
  zone         = var.zone
  tags         = ["reddit-app", "docker-host"]
  boot_disk {
    initialize_params {
      image = var.disk_image
    }
  }
//  metadata = {
//    # путь до публичного ключа
//    ssh-keys = "appuser:${file(var.public_key_path)}"
//  }
  network_interface {
    network = "default"
    access_config {}
  }
  service_account {
    email = "236921286481-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-default"
  # Название сети, в которой действует правило
  network = "default"
  # Какой доступ разрешить
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }
  # Каким адресам разрешаем доступ
  source_ranges = ["0.0.0.0/0"]
  # Правило применимо для инстансов с перечисленными тэгами
  target_tags = ["reddit-app"]
}