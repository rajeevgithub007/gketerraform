provider "google" {
  credentials = file("C:\\Users\\rajee\\devops_workspace\\Nodejsdemo\\service-acount-gcp.json")
  project     = "neat-library-416712"
  region      = "us-central1"
  # Add other required configuration parameters as needed
}
