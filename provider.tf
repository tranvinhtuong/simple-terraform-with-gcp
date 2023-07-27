# GCP Provider

provider "google"{
    project     = "case-study3-393407"
    credentials = file("credential.json")
    region      = "asia-southeast1"
    zone        = "asia-southeast1-a"
}