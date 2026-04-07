# ---------------------------------------------
# Terraform configuration
# ---------------------------------------------

terraform {
  required_version = ">= 1.11.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "nagoyameshi-tfstate-bucket-motokisato" # ご自身のバケット名に書き換えてください
    key    = "network/nagoyameshi-network.tfstate"
    region = "ap-northeast-1"
  }
}

