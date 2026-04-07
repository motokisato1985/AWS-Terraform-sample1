# ---------------------------------------------
# Elastic IP
# ---------------------------------------------

resource "aws_eip" "natgw_eip" {
  # EIPは運用安定のため、常に2つ（1a用と1c用）確保しておく
  count  = 2
  domain = "vpc"

  tags = {
    Name    = "${var.project}-${var.environment}-natgw-eip-${count.index + 1}"
    Project = var.project
    Env     = var.environment
  }
}

# ---------------------------------------------
# NAT Gateway
# ---------------------------------------------
resource "aws_nat_gateway" "natgw" {
  # variableを 0, 1, 2 と切り替えることで、NAT本体だけを作成・削除する
  count = var.natgw_count

  # 作成された数に応じて、固定されているEIPを順番に割り当てる
  allocation_id = aws_eip.natgw_eip[count.index].id

  subnet_id = count.index == 0 ? aws_subnet.public_subnet_1a.id : aws_subnet.public_subnet_1c.id

  tags = {
    Name    = "${var.project}-${var.environment}-natgw-${count.index + 1}"
    Project = var.project
    Env     = var.environment
  }
}
