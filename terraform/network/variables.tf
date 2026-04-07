# ---------------------------------------------
# Variables
# ---------------------------------------------

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "az_1a" {
  type    = string
  default = "ap-northeast-1a"
}

variable "az_1c" {
  type    = string
  default = "ap-northeast-1c"
}

variable "public_subnet_1a_cidr" {
  type = string
}

variable "public_subnet_1c_cidr" {
  type = string
}

variable "private_subnet_1a_cidr" {
  type = string
}

variable "private_subnet_1c_cidr" {
  type = string
}

variable "db_subnet_1a_cidr" {
  type = string
}

variable "db_subnet_1c_cidr" {
  type = string
}

variable "domain" {
  type = string
}

variable "natgw_count" {
  description = "NATゲートウェイの作成数 (0: なし, 1: 1aのみ, 2: 1aと1c)"
  type        = number
  default     = 0 # 検証作業を行わない場合は0, 検証用環境：1, 本番用環境：2
}
