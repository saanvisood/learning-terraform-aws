terraform {
  backend "s3" {
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
      version = "1.2.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }

  }
}
