# AWSアカウントの情報を取得する
data "aws_caller_identity" "current" {}

# プロバイダーが実際に動いているリージョン情報を取ってくる
data "aws_region" "current" {}

# すでにnetworkフォルダに作成済みのVPC、サブネットの情報を取得する
data "aws_vpc" "vpc" {
  tags = {
    Name    = "nagoyameshi-common-vpc"
    Project = "nagoyameshi"
    Env     = "common"
  }
}

data "aws_subnet" "public_subnet_1a" {
  filter {
    name   = "tag:Name"
    values = ["nagoyameshi-common-public-subnet-1a"]
  }
}

data "aws_subnet" "public_subnet_1c" {
  filter {
    name   = "tag:Name"
    values = ["nagoyameshi-common-public-subnet-1c"]
  }
}

data "aws_subnet" "private_subnet_1a" {
  filter {
    name   = "tag:Name"
    values = ["nagoyameshi-common-private-subnet-1a"]
  }
}

data "aws_subnet" "private_subnet_1c" {
  filter {
    name   = "tag:Name"
    values = ["nagoyameshi-common-private-subnet-1c"]
  }
}

# CloudFrontのIP帯（プレフィックスリスト）を取得
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}
