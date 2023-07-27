#additonal disk
resource "google_compute_disk" "data_disk" {
    name = "data-disk"
    type = "pd-ssd"
    zone = "asia-southeast1-a"
    size = 40
}

resource "google_compute_attached_disk" "default" {
    disk = google_compute_disk.data_disk.id
    instance = google_compute_instance.web_server.id
  
}

#webserver instance
resource "google_compute_instance" "web_server"{
    name        = "x-sin-wp-p-ap-8-s01"
    machine_type =  "e2-medium"
    zone         = "asia-southeast1-a"

    boot_disk {
         auto_delete = true
      initialize_params {
        image = "rocky-linux-9-v20230711"
        type = "pd-balanced"
        size = 20
      }
      mode = "READ_WRITE"
    }

    lifecycle {
      ignore_changes = [attached_disk]
    }

    network_interface {
      network = google_compute_network.vpc_network.id
      subnetwork = google_compute_subnetwork.first_private_subnet.id
      network_ip = "192.168.3.10"
    }

    tags = ["http-server", "https-server", "webserver"]

    metadata_startup_script = file("startup.sh")
}

#bastionhost instance
resource "google_compute_address" "ip_static_bastionhost" {
    name = "ipv4-address"
  
}
resource "google_compute_instance" "bastion_host"{
    name        = "x-sin-bs-p-ap-8-s01"
    machine_type =  "e2-medium"
    zone         = "asia-southeast1-a"

    boot_disk {
      initialize_params {
        image = "rocky-linux-9-v20230711"
        size = 20
      }
    }
    network_interface {
      network = google_compute_network.vpc_network.id
      subnetwork = google_compute_subnetwork.bastion_subnet.id
      network_ip = "192.168.1.10"
      access_config { //External IP
        network_tier = "PREMIUM"
        nat_ip = google_compute_address.ip_static_bastionhost.address
      }
    }

    tags = ["bastionhost"]
}