terraform {
  backend "gcs" {
    bucket = "terraform-navikt-sentry"
  }
}

provider "google" {
  project = "navikt-sentry"
  region  = "europe-north1"
  zone    = "europe-north1-b"
}

provider "google-beta" {
  project = "navikt-sentry"
  region  = "europe-north1"
  zone    = "europe-north1-b"
}

/* Network */
resource "google_compute_subnetwork" "sentry" {
  name          = "sentry"
  ip_cidr_range = "10.55.0.0/24"
  network       = google_compute_network.sentry.self_link
}

resource "google_compute_network" "sentry" {
  name                    = "sentry"
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = google_compute_network.sentry.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["allow-ssh"]
}

resource "google_compute_firewall" "allow-scaleft-to-sentry" {
  name    = "allow-scaleft-to-sentry"
  network = google_compute_network.sentry.self_link

  allow {
    protocol = "tcp"
    ports    = ["80", "9000"]
  }

  source_tags = ["scaleft-instance"]
  target_tags = ["sentry-instance"]
}

resource "google_compute_firewall" "allow-sentry-proxy-to-sentry" {
  name    = "allow-sentry-proxy-to-sentry"
  network = google_compute_network.sentry.self_link

  allow {
    protocol = "tcp"
    ports    = ["80", "9000"]
  }

  source_tags = ["sentry-proxy-instance"]
  target_tags = ["sentry-instance"]
}

data "google_compute_lb_ip_ranges" "ranges" {
}

resource "google_compute_firewall" "lb" {
  name    = "lb-firewall"
  network = google_compute_network.sentry.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = data.google_compute_lb_ip_ranges.ranges.network
  target_tags = [
    "sentry-proxy-instance",
  ]
}

resource "google_compute_address" "sentry-static-internal-ip" {
  name         = "sentry-static-internal-ip"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.sentry.self_link
}

resource "google_compute_global_address" "db_private_ip_address" {
  name          = "db-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.sentry.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.sentry.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.db_private_ip_address.name]
}

/* Database */
resource "google_sql_database_instance" "sentry-database-instance" {
  name             = "sentry-database-instance"
  database_version = "POSTGRES_9_6"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.sentry.self_link
    }
  }
}

resource "google_sql_database" "sentry-database" {
  name      = var.sentry_db_name
  charset   = "UTF8"
  collation = "en_US.UTF8"
  instance  = google_sql_database_instance.sentry-database-instance.name
}

resource "google_sql_user" "sentry-sql-user" {
  name     = var.sentry_db_user
  instance = google_sql_database_instance.sentry-database-instance.name
  password = var.sentry_db_password
}

/* Redis */
resource "google_redis_instance" "sentry-cache" {
  name               = "memory-cache"
  authorized_network = google_compute_network.sentry.self_link
  memory_size_gb     = 10
}

/* VMs */
resource "google_compute_instance" "sentry" {
  name                      = "sentry"
  machine_type              = "n1-standard-4"
  allow_stopping_for_update = true

  tags = ["sentry-instance", "allow-ssh"]
  metadata_startup_script = templatefile("${path.module}/startup_scripts/sentry.sh", {
    sentry_image                    = var.sentry_image
    sentry_secret_key               = var.sentry_secret_key
    sentry_postgres_host            = google_sql_database_instance.sentry-database-instance.first_ip_address
    sentry_postgres_port            = "5432"
    sentry_db_name                  = var.sentry_db_name
    sentry_db_user                  = var.sentry_db_user
    sentry_db_password              = var.sentry_db_password
    sentry_redis_host               = google_redis_instance.sentry-cache.host
    sentry_redis_port               = google_redis_instance.sentry-cache.port
    sentry_slack_client_id          = var.sentry_slack_client_id
    sentry_slack_client_secret      = var.sentry_slack_client_secret
    sentry_slack_verification_token = var.sentry_slack_verification_token
    github_api_secret               = var.github_api_secret
    github_app_client_id            = var.github_app_client_id
    github_app_client_secret        = var.github_app_client_secret
    github_app_id                   = var.github_app_id
    github_app_name                 = var.github_app_name
    github_app_webhook_secret       = var.github_app_webhook_secret
    github_app_private_key          = var.github_app_private_key
    sentry_external_url             = var.sentry_external_url
    }
  )

  boot_disk {
    initialize_params {
      image = "gce-uefi-images/cos-stable"
    }
  }

  network_interface {
    network    = google_compute_network.sentry.self_link
    subnetwork = google_compute_subnetwork.sentry.self_link
    network_ip = google_compute_address.sentry-static-internal-ip.address

    access_config {
    }
  }
}

resource "google_compute_instance" "scaleft" {
  name                      = "scaleft"
  machine_type              = "g1-small"
  allow_stopping_for_update = true

  network_interface {
    subnetwork = google_compute_subnetwork.sentry.self_link

    access_config {
    }
  }

  tags = ["scaleft-instance", "allow-ssh"]

  metadata_startup_script = templatefile("${path.module}/startup_scripts/scaleft.sh", {
    canonical_name   = "sentry"
    enrollment_token = var.scaleft_enrollment_token
    }
  )

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-minimal-1904"
    }
  }
}

resource "google_compute_instance" "sentry-proxy" {
  name                      = "sentry-proxy"
  machine_type              = "f1-micro"
  allow_stopping_for_update = true

  tags = ["sentry-proxy-instance", "allow-ssh"]
  metadata_startup_script = templatefile("${path.module}/startup_scripts/nginx.sh", {
    nginx_image         = var.nginx_image
    sentry_internal_ip  = google_compute_instance.sentry.network_interface.0.network_ip
    sentry_internal_url = var.sentry_internal_url
    }
  )

  boot_disk {
    initialize_params {
      image = "gce-uefi-images/cos-stable"
    }
  }

  network_interface {
    network    = google_compute_network.sentry.self_link
    subnetwork = google_compute_subnetwork.sentry.self_link

    access_config {
    }
  }
}

# Make sentry-proxy internet
resource "google_compute_instance_group" "sentry-proxy-instances" {
  name        = "sentry-proxy-instances"
  description = "Sentry-proxy instances"

  instances = [
    google_compute_instance.sentry-proxy.self_link
  ]

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "https"
    port = "443"
  }
}

resource "google_compute_managed_ssl_certificate" "sentry-gc-nav-no" {
  provider = google-beta

  name = "sentry-gc-nav-no-cert"
  managed {
    domains = [
      var.sentry_external_url
    ]
  }
}

resource "google_compute_target_https_proxy" "sentry-proxy" {
  name             = "sentry-proxy"
  url_map          = google_compute_url_map.sentry-proxy.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.sentry-gc-nav-no.self_link]
}

resource "google_compute_url_map" "sentry-proxy" {
  name        = "sentry-proxy-url-map"
  description = "Sentry proxy url map"

  default_service = google_compute_backend_service.sentry-proxy.self_link

  host_rule {
    hosts        = [var.sentry_external_url]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.sentry-proxy.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.sentry-proxy.self_link
    }
  }
}

resource "google_compute_backend_service" "sentry-proxy" {
  name        = "sentry-proxy"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_http_health_check.default.self_link]

  backend {
    group = google_compute_instance_group.sentry-proxy-instances.self_link
  }
}

resource "google_compute_http_health_check" "default" {
  name               = "http-health-check"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_global_address" "sentry-proxy" {
  name = "sentry-proxy"
}

resource "google_compute_global_forwarding_rule" "default" {
  provider = google-beta

  ip_address            = google_compute_global_address.sentry-proxy.address
  load_balancing_scheme = "EXTERNAL"
  name                  = "sentry-proxy-forwarding-rule"
  target                = google_compute_target_https_proxy.sentry-proxy.self_link
  port_range            = 443
}

/*
module "gce-lb-http" {
  source      = "github.com/GoogleCloudPlatform/terraform-google-lb-http"
  project     = "navikt-sentry"
  name        = "sentry-proxy-http-lb"
  target_tags = ["sentry-proxy-instance"]
  ssl         = true
  ssl_certificates = [
    google_compute_managed_ssl_certificate.sentry-gc-nav-no.self_link
  ]
  use_ssl_certificates = true
  backends = {
    "0" = [
      { group                        = google_compute_instance_group.sentry-proxy-instances
        balancing_mode               = null
        capacity_scaler              = null
        description                  = null
        max_connections              = null
        max_connections_per_instance = null
        max_rate                     = null
        max_rate_per_instance        = null
        max_utilization              = null
      }
    ]
  }
  backend_params = [
    # health check path, port name, port number, timeout seconds.
    "/,http,80,10"
  ]
}
*/
