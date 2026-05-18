terraform {
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
