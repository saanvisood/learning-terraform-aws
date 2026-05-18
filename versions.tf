terraform {
  backend "s3" { # Storing state file in S3 bucket to avoid drift
    bucket = "saanvisood-terraform-state"
    key    = "ollama/terraform.tfstate"
    region = "ca-central-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.44.0" # Latest AWS Terraform provider v.
    }

    terracurl = {
      source  = "devops-rob/terracurl"
      version = "2.2.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }

  }
}
