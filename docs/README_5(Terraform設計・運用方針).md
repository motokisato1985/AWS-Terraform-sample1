# Terraform設計・運用方針

## 1. 設計方針
本プロジェクトでは、Terraformコードを「可読性」「変更容易性」「再利用性」を考慮し設計している。

- リソース単位でファイルを分割
- 環境差分は変数（terraform.tfvars）で管理
- dev / prod / network をディレクトリ単位で分離
- AWS構成図と対応する単位でグルーピング


## 2. ディレクトリ構成

- network/
  - VPC, Subnet, IGW, NAT Gateway など共通基盤
- dev/
  - 検証環境用リソース
- prod/
  - 本番環境用リソース


## 3. ファイル構成と役割

### network（共通基盤）
| ファイル名 | 内容 |
|------------|------|
| main.tf | Terraform設定、backend設定 |
| provider.tf | Provider設定 |
| variables.tf | 変数定義 |
| terraform.tfvars | 共通基盤用の値 |
| vpc.tf | VPC |
| subnet.tf | Public / Private Subnet |
| igw.tf | Internet Gateway |
| natgw.tf | NAT Gateway |
| routetable.tf | Route Table / Route Table Association |
| route53zone.tf | Route53 Hosted Zone |
| outputs.tf | 他環境から参照する出力値 |

### dev, prod（環境固有リソース）
| ファイル名 | 内容 |
|------------|------|
| main.tf | Terraform設定、backend設定 |
| provider.tf | Provider設定 |
| variables.tf | 変数定義 |
| terraform.tfvars | 環境ごとの値 |
| data.tf | networkの出力値や既存リソースの参照 |
| alb.tf | ALB, Listener, Target Group |
| ecs.tf | ECS Cluster, Task Definition, Service |
| autoscaling.tf | ECS Auto Scaling |
| rds.tf | RDS |
| security_group.tf | セキュリティグループ |
| cloudfront.tf | CloudFront |
| waf.tf | WAF |
| acm.tf | ACM証明書 |
| ecr.tf | ECR |
| iam.tf | IAMロール、IAMポリシー |
| secrets.tf | Secrets Manager | (本番用のみ)
| ssm_parameter.tf | SSM Parameter Store |
| cloudwatch.tf | CloudWatch Dashboard / Alarm |
| sns_topic.tf | SNS |


## 4. 構成図との対応
構成図の各コンポーネントとTerraformコードは以下のように対応している。

### 共通基盤（network）
- VPC
  - vpc.tf

- Public Subnet / Private Subnet
  - subnet.tf

- Internet Gateway（IGW）
  - igw.tf

- NAT Gateway
  - natgw.tf

- Route Table
  - routetable.tf

- Route53 Hosted Zone
  - route53zone.tf

### 環境固有リソース（dev, prod）
- CloudFront / WAF / ACM
  - cloudfront.tf / waf.tf / acm.tf

- ALB
  - alb.tf / security_group.tf

- ECS
  - ecs.tf / autoscaling.tf / security_group.tf

- RDS
  - rds.tf / security_group.tf

- 機密情報管理
  - secrets.tf / ssm_parameter.tf / iam.tf / ecs.tf

- CI/CD（ECR, IAM）
  - ecr.tf / iam.tf

- 監視 / 通知
  - cloudwatch.tf / sns_topic.tf


## 5. 命名規則

- すべてのリソース名に以下を付与
  - `${var.project}-${var.environment}-xxx`

例：
- nagoyameshi-dev-alb
- nagoyameshi-prod-ecs-service

これにより環境識別が容易となり、リソースの衝突を防止している。


## 6. 変更時の指針

- ALBの変更 → alb.tf
- ECSの変更 → ecs.tf
- DBの変更 → rds.tf
- 通信制御 → security_group.tf
- CDN / DNS → cloudfront.tf / route53zone.tf

変更箇所がファイル単位で明確になるよう設計している。


## 7. Terraform運用手順

- terraform init
- terraform fmt
- terraform validate
- terraform plan
- terraform apply


## 8. plan確認の観点

- 不要な destroy が含まれていないか
- ALB / RDS など重要リソースが再作成されないか
- 変更対象が意図したリソースのみか


## 9. apply失敗時の対応

- リソース参照名の誤りを確認
- 依存関係（参照順）の確認
- stateとコードの不整合を確認
- 既存リソースとの名前衝突を確認


## 10. 設計上のポイント

- 環境ごとにTerraformディレクトリを分離し、影響範囲を限定
- 変数化によりdev/prodの差分を吸収
- ファイル分割により変更箇所を限定し、保守性を向上