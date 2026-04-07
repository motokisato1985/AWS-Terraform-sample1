# ---------------------------------------------
# Subnet
# ---------------------------------------------
resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.az_1a
  cidr_block              = var.public_subnet_1a_cidr
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project}-${var.environment}-public-subnet-1a"
    Project = var.project
    Env     = var.environment
    Type    = "public"
  }
}

resource "aws_subnet" "public_subnet_1c" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.az_1c
  cidr_block              = var.public_subnet_1c_cidr
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project}-${var.environment}-public-subnet-1c"
    Project = var.project
    Env     = var.environment
    Type    = "public"
  }
}

resource "aws_subnet" "private_subnet_1a" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.az_1a
  cidr_block              = var.private_subnet_1a_cidr
  map_public_ip_on_launch = false

  tags = {
    Name    = "${var.project}-${var.environment}-private-subnet-1a"
    Project = var.project
    Env     = var.environment
    Type    = "private"
  }
}

resource "aws_subnet" "private_subnet_1c" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.az_1c
  cidr_block              = var.private_subnet_1c_cidr
  map_public_ip_on_launch = false

  tags = {
    Name    = "${var.project}-${var.environment}-private-subnet-1c"
    Project = var.project
    Env     = var.environment
    Type    = "private"
  }
}

resource "aws_subnet" "db_subnet_1a" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.az_1a
  cidr_block              = var.db_subnet_1a_cidr
  map_public_ip_on_launch = false

  tags = {
    Name    = "${var.project}-${var.environment}-db-subnet-1a"
    Project = var.project
    Env     = var.environment
    Type    = "private"
  }
}

resource "aws_subnet" "db_subnet_1c" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.az_1c
  cidr_block              = var.db_subnet_1c_cidr
  map_public_ip_on_launch = false

  tags = {
    Name    = "${var.project}-${var.environment}-db-subnet-1c"
    Project = var.project
    Env     = var.environment
    Type    = "private"
  }
}

#-----------------------------
# RDS subnet group
#-----------------------------
resource "aws_db_subnet_group" "mysql_subnetgroup" {
  name = "${var.project}-${var.environment}-mysql-subnetgroup"
  subnet_ids = [
    aws_subnet.db_subnet_1a.id,
    aws_subnet.db_subnet_1c.id
  ]

  tags = {
    Name    = "${var.project}-${var.environment}-mysql-subnetgroup"
    Project = var.project
    Env     = var.environment
  }
}
