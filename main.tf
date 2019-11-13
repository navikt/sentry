variable {
  name = "dbpassword"
}

provider "google" {
  credentials = "${file("navikt-sentry-5e28d3138dff.json")}"
  project     = "navikt-sentry"
  region      = "europe-north1"
  zone        = "europe-north1-b"
}

resource "google_redis_instance" "sentry-cache" {
  name               = "memory-cache"
  memory_size_gb     = 10
}

resource "google_compute_instance" "sentry-instance" {
  count        = 1
  name         = "sentry-instance-${count.index + 1}"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = "default"
    subnetwork = "default"

    access_config {
      // Ephemeral IP
    }
  }
}

data "null_data_source" "auth_netw_postgres_allowed_1" {
  count = "${length(google_compute_instance.sentry-instance.*.self_link)}"

  inputs = {
    name  = "sentry-instance-${count.index + 1}"
    value = "${element(google_compute_instance.sentry-instance.*.network_interface.0.access_config.0.nat_ip, count.index)}"
  }
}

resource "google_sql_database_instance" "sentry-database-instance" {
  name             = "sentry-database-instance"
  database_version = "POSTGRES_9_6"
  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled = true
    }
  }
}

resource "google_sql_database" "sentry-database" {
  name      = "sentry-database"
  charset   = "UTF8"
  collation = "en_US.UTF8"
  instance  = "${google_sql_database_instance.sentry-database-instance.name}"
}

resource "google_sql_user" "sentry-sql-user" {
  name     = "sentry"
  instance = "${google_sql_database_instance.sentry-database-instance.name}"
  host     = "${element(google_compute_instance.sentry-instance.0.network_interface.0.access_config.0.nat_ip)}"
  password = "${var.dbpassword}"
}