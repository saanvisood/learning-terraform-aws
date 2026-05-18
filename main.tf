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

# Configure the AWS Provider
provider "aws" {
  region = "ca-central-1"
}

variable "open_webui_user" {
  description = "Username to access Open WebUI"
  default     = "admin@demo.gs"
}

variable "openai_base" {
  description = "Optional base URL to use OpenAI API with Open WebUI"
  default     = "https://api.openai.com/v1"
}

variable "openai_key" {
  description = "Optional API key to use OpenAI API with Open WebUI"
  default     = ""
}
