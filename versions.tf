terraform {
  backend "s3" { # Storing state file in S3 bucket to avoid drift
    bucket = "saanvisood-terraform-state"
    key    = "ollama/terraform.tfstate"
    region = "ca-central-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = local.latest_aws_provider
    }

    terracurl = {
      source  = "devops-rob/terracurl"
      version = local.latest_terracurl_v
    }

    random = {
      source  = "hashicorp/random"
      version = local.latest_random_v
    }

  }
}
