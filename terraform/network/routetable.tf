# ---------------------------------------------
# Route Table
# ---------------------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-public-rt"
    Project = var.project
    Env     = var.environment
    Type    = "public"
  }
}

resource "aws_route_table_association" "public_rt_1a" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet_1a.id
}
resource "aws_route_table_association" "public_rt_1c" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet_1c.id
}

# --- 1a用のルートテーブル ---
resource "aws_route_table" "private_rt_1a" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-private-rt-1a"
    Project = var.project
    Env     = var.environment
  }
}

# --- 1c用のルートテーブル ---
resource "aws_route_table" "private_rt_1c" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-private-rt-1c"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_route_table_association" "private_rt_1a" {
  route_table_id = aws_route_table.private_rt_1a.id
  subnet_id      = aws_subnet.private_subnet_1a.id
}

resource "aws_route_table_association" "private_rt_1c" {
  route_table_id = aws_route_table.private_rt_1c.id
  subnet_id      = aws_subnet.private_subnet_1c.id
}

resource "aws_route_table_association" "db_rt_1a" {
  route_table_id = aws_route_table.private_rt_1a.id
  subnet_id      = aws_subnet.db_subnet_1a.id
}

resource "aws_route_table_association" "db_rt_1c" {
  route_table_id = aws_route_table.private_rt_1c.id
  subnet_id      = aws_subnet.db_subnet_1c.id
}

# ---------------------------------------------
# Route Table (NAT用)
# ---------------------------------------------

resource "aws_route" "private_rt_1a_nat_route" {
  count                  = var.natgw_count > 0 ? 1 : 0
  route_table_id         = aws_route_table.private_rt_1a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw[0].id
}

resource "aws_route" "private_rt_1c_nat_route" {
  count                  = var.natgw_count > 0 ? 1 : 0
  route_table_id         = aws_route_table.private_rt_1c.id
  destination_cidr_block = "0.0.0.0/0"

  # NATが1つ（dev想定）なら index 0 を使い、2つ（prod想定）なら index 1 を使う
  nat_gateway_id = var.natgw_count > 1 ? aws_nat_gateway.natgw[1].id : aws_nat_gateway.natgw[0].id
}

