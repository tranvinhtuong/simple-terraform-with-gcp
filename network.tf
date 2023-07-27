#vpc network
resource "google_compute_network" "vpc_network" {
    name                = "vpcnet-group3"
    auto_create_subnetworks = false
    mtu                     = 1460
}

#server subnet
resource "google_compute_subnetwork" "first_private_subnet" {
    name                    = "server-subnet"
    ip_cidr_range           = "192.168.3.0/24"
    region                  = "asia-southeast1"
    network                 = google_compute_network.vpc_network.id
}

#sql subnet
resource "google_compute_subnetwork" "second_private_subnet" {
    name                    = "sql-subnet"
    ip_cidr_range           = "192.168.5.0/24"
    region                  = "asia-southeast1"
    network                 = google_compute_network.vpc_network.id
}

#bastion subnet
resource "google_compute_subnetwork" "bastion_subnet" {
    name                    = "bastion-subnet"
    ip_cidr_range = "192.168.1.0/24"
    region = "asia-southeast1"
    network = google_compute_network.vpc_network.id
  
}

#rule firewall to access bastion from internet
resource "google_compute_firewall" "allow_access_to_bastion_host" {
    name = "allow-access-to-bastion-host"
    network = google_compute_network.vpc_network.id

    allow {
      protocol = "tcp"
      ports    = ["22"]
    }
    source_ranges = ["0.0.0.0/0"]
    target_tags = ["bastionhost"]
  
}

#rule firewall to access server from bastionhost
resource "google_compute_firewall" "allow_access_to_webserver" {
    name = "allow-access-to-webserver"
    network = google_compute_network.vpc_network.id

    allow {
      protocol = "tcp"
      ports    = ["22"]
    }
    source_ranges = ["192.168.1.0/24"]
    source_tags = ["bastionhost"]
    target_tags =  ["webserver"]
}

#router
resource "google_compute_router" "router_nat" {
    name = "router-nat"
    network = google_compute_network.vpc_network.name
    region = "asia-southeast1"
    bgp {
      asn = 64512
      advertise_mode = "CUSTOM"
      advertised_ip_ranges {
        range = "192.168.3.0/24"
      }
    }
}

#nat

resource "google_compute_router_nat" "nat" {
    name = "cloud-nat"
    router = google_compute_router.router_nat.name
    region = google_compute_router.router_nat.region

    nat_ip_allocate_option = "AUTO_ONLY"

    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
    subnetwork {
      name = google_compute_subnetwork.first_private_subnet.id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  
}

#peering
resource "google_compute_global_address" "private_ip_network" {
  name = "private-ip-address"
  prefix_length = 16
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  network = google_compute_network.vpc_network.id
  
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network = google_compute_network.vpc_network.id
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_network.name]
  
}


#load balancing
#static ip loadbalancing
resource "google_compute_address" "lb_ip_static" {
  name =  "lb-ip-static"
  region = "asia-southeast1"
  
}
#healthcheck
resource "google_compute_http_health_check" "lb_healthcheck" {
  name =  "lb-healthcheck"
  request_path = "/"
  port = 80
  check_interval_sec = 10
  timeout_sec = 3
  
}

#target pool - backend
resource "google_compute_target_pool" "lb_target_pool" {
  name = "lb-target-pool"
  session_affinity = "NONE"
  region = "asia-southeast1"

  instances = [google_compute_instance.web_server.self_link]

  health_checks = [google_compute_http_health_check.lb_healthcheck.name]
    
}

resource "google_compute_forwarding_rule" "network_load_balancer" {
  name = "load-balancer"
  region = "asia-southeast1"
  target = google_compute_target_pool.lb_target_pool.self_link
  port_range = "80-443"
  ip_protocol = "TCP"
  ip_address = google_compute_address.lb_ip_static.id 
  load_balancing_scheme = "EXTERNAL"
  
}


#firewall

resource "google_compute_firewall" "rules_ssh" {
  name = "firewall-rules-ssh"
  project = "case-study3-393407"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports = ["22", "80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
}
