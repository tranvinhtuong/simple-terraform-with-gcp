resource "google_sql_database_instance" "sql_database" {
    name = "x-sin-db-p-ap-8-s01"
    database_version = "MYSQL_8_0"
    region = "asia-southeast1"
    root_password = "group3ACN!"
    deletion_protection = false 
    depends_on = [google_service_networking_connection.private_vpc_connection]
    settings {
      tier = "db-f1-micro"
      ip_configuration {
        ipv4_enabled = false #dont give the db a public IPv4
        private_network = google_compute_network.vpc_network.id
      }

      password_validation_policy {
        min_length = 6
        complexity = "COMPLEXITY_DEFAULT"
        reuse_interval = 2
        disallow_username_substring = true
        enable_password_policy = true
    }
  
}
}
#create database
resource "google_sql_database" "sql_db" {
  name = "database"
  instance = google_sql_database_instance.sql_database.name
  
}

#create user
resource "google_sql_user" "sql_user" {
  name = "group3"
  password = "Group3ACN!"
  instance = google_sql_database_instance.sql_database.name
  
}