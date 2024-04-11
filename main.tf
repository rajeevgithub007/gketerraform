data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}
resource "google_compute_network" "us_central1_net" {
  name          = "vpc-01"
  # region        = "us-central1"
  # ip_cidr_range = "10.1.0.0/16"  # Adjust CIDR range as needed

  # Define the network for the subnetwork (replace with your existing network name)
  # network = "vpc-01"
}

resource "google_compute_subnetwork" "us_central1_subnet" {
  name          = "us-central1-01"
  region        = "us-central1"
  ip_cidr_range = "10.1.1.0/24"  # Adjust CIDR range as needed

  # Define the network for the subnetwork (replace with your existing network name)
  network = "vpc-01"
  secondary_ip_range {
    range_name    = "us-central1-01-gke-01-pods"
    ip_cidr_range = "10.1.2.0/24"  # Specify the secondary IP range for pods
  }
  secondary_ip_range {
    range_name    = "us-central1-01-gke-01-services"
    ip_cidr_range = "10.1.3.0/24"  # Specify the secondary IP range for pods
  }
}


module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = "neat-library-416712"
  name                       = "gke-test-1"
  region                     = "us-central1"
  zones                      = ["us-central1-a", "us-central1-b"]
  network                    = "vpc-01"
  subnetwork                 = "us-central1-01"
  ip_range_pods              = "us-central1-01-gke-01-pods"
  ip_range_services          = "us-central1-01-gke-01-services"
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = false
  filestore_csi_driver       = false

  node_pools = [
    {
      name                      = "default-node-pool"
      machine_type              = "e2-micro"
      min_count                 = 1
      max_count                 = 3
      spot                      = true
      disk_size_gb              = 100
      disk_type                 = "pd-standard"
      image_type                = "COS_CONTAINERD"
    #   enable_gcfs               = false
    #   enable_gvnic              = false
    #   logging_variant           = "DEFAULT"
    #   auto_repair               = true
    #   auto_upgrade              = true
      service_account           = "demoimgsvcaccount@neat-library-416712.iam.gserviceaccount.com"
      preemptible               = false
      initial_node_count        = 1
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}