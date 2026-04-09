# AWSインフラ環境構築（Terraform × ECS × CI/CD）

Terraformを用いてAWS上にLaravelアプリケーションの実行環境を構築し、
CI/CDにより自動デプロイを実現したプロジェクトです。
本構成では以下を実現しています：
- Terraformによるインフラのコード化(IaC)
- network / dev / prod 環境の分離
- CloudFront + WAF によるセキュアな配信
- ECS/Fargate によるコンテナ運用
- CodePipeline、CodeBuild によるアプリケーション自動デプロイ
---
## 構成図

![構成図](./architecture.png)
- CloudFront + WAF を入口とし、ALB → ECS → RDS の構成
- 静的コンテンツはCloudFront経由で配信し、動的処理はECSで実行
- CI/CDはCodePipeline、CodeBuildにより自動化

---
## 📄 ドキュメント

本プロジェクトでは、設計・見積・提案まで含めて一貫して対応しています。

- 📝 提案書  
  https://docs.google.com/presentation/d/1Ndn7kfNVjR4YvsROvyQeximUFvu1MDO5wNOmrBmEvk8/edit?usp=sharing

- 💰 見積書  
  https://docs.google.com/spreadsheets/d/18XdWbQzIQmavuhlGR9B4OrAH652WDAfYNFDVYWaCYR4/edit?usp=sharing

- ⚙️ AWSパラメータシート  
  https://docs.google.com/spreadsheets/d/1CCJOAIbfhGz8fowwJQsyqpZ6Btcio7X7iCEzXYL-hAs/edit?usp=sharing

---
## 動作確認
AWSコンソール上での稼働状況は下記 **screenshots** フォルダに掲載しています。

---
## 1. ディレクトリ構成

```text
.
├── terraform/
│   ├── network/       # VPC, Subnet, Internet Gateway等の共通基盤
│   ├── dev/           # ECS, RDS, ALB, CloudFront等、環境固有のリソース(検証環境用)
│   ├── prod/          # ECS, RDS, ALB, CloudFront等、環境固有のリソース(本番環境用)
│   └── .gitignore     # Terraform用の除外設定
├── docs/              # 設計書・補足README
├── screenshots/       # AWSコンソール画面キャプチャ
├── architecture(構成図).png
└── README.md
```

## 2. 前提条件
本環境を実行するには、事前に以下の準備が必要です。
- **Terraform**: バージョン v1.x 以上
- **AWS CLI**: インストール及び設定済みであること
- **S3 Bucket**: TerraformのState管理用バケットが作成済みであること（backend用）


## 3. セットアップ手順

### 共通基盤（network）の構築
- `network/` フォルダに移動し、`terraform init` を実行
- `terraform apply` を実行し、VPC等の基盤を作成

### 検証 / 本番環境（dev, prod）の構築
- `terraform/dev` または `terraform/prod` フォルダに移動
- `main.tf` 内の `backend "s3"` ブロックの `bucket` 名を、自身のバケット名に変更
- `provider.tf` 内の `profile` が削除されていることを確認
- `example_terraform.tfvars` をコピーして `terraform.tfvars` を作成し、  
各変数を環境に合わせて設定
- `terraform init` → `terraform apply` を実行


## 4. CI/CDセットアップ手順

- GitHub リポジトリで `dev` および `main` ブランチを作成し、アプリケーションコード、`Dockerfile`、`buildspec.yml` などの関連ファイルを管理
- AWS CodePipeline で GitHub リポジトリをソースとして接続し、対象ブランチへの更新を契機にパイプラインが起動するように設定
- ソース更新を契機に CodePipeline が実行され、Dockerイメージのビルドおよびデプロイ処理を自動実行  

※ 検証環境は `dev` ブランチ、本番環境は `main` ブランチを対象として運用します。

※ 本構成では、GitHub への push を起点として CodePipeline が起動し、ビルドからデプロイまでを自動化しています。


## 5. スケーリングとサービス継続性
本システムでは、**ECS Service Auto Scaling**により、CPU使用率70%を閾値として
自動的にタスク数を増減させる構成としています。

これにより、アクセス増加時もサービス停止を伴わずに処理能力を拡張し、
サービス継続性を確保しています。

また、スケール状況は CloudWatch Dashboard で可視化され、
異常時はSNS通知により即時対応可能な構成としています。


## 6. 監視設定と通知について
CloudWatch AlarmsとSNSを連携し、以下の項目を監視しています。
- ALB: 5xxエラー発生時
- ECS: CPU/メモリ使用率（70%以上）、Running Task Count(dev:1未満、prod:2未満)
- RDS: CPU使用率（70%以上）、空きストレージ容量減少(25%未満)
- Logs: アプリケーションエラーログの検知

※SNSサブスクリプション作成後、届いたメールの「Confirm subscription」をクリックして有効化してください

※一部のアラートについては、Auto ScalingやWAFにより自動的な負荷分散・遮断が行われる設計としています。


## 7. 障害対応フロー
1. 異常検知: CloudWatch Alarmの閾値超過をトリガーに、
Amazon SNS経由で管理者に自動メール通知
<br>
2. 原因特定: メールとCloudWatch Dashboardを確認し、以下のいずれに起因するかを特定
- コンピューティングリソース（ECS）の枯渇
- DBストレージ不足
- アプリケーションログ（CloudWatch Logs）でのエラー

3. 自動復旧の状況確認: 負荷起因の場合、ECS Service Auto Scalingが正常にトリガーされ、タスクのスケールアウトが開始されているかをマネジメントコンソールで確認
<br>
4. 手動復旧対応: 自動復旧しない場合（DB接続エラー等）は、GitHub Actionsを用いたロールバック、またはECSタスクの手動再起動による暫定復旧を実施
<br>
5. 復旧確認: ALBの5xxエラーメトリクスが収束し、サービスの正常稼働（ヘルスチェック合格）をダッシュボードで再確認
<br>
6. 恒久対策: 障害ログの事後分析を行い、根本原因を修正したコードをGitHubにpush、必要に応じてCloudWatch Alarmの閾値を最適化


## 8. 注意事項
- 提出用のコードからは、AWSプロフィール名（profile）や機密情報（Access Key等）を削除しています。実行時は環境変数やデフォルトプロフィールを使用してください。
- 作業終了時はコスト削減のため、以下の操作を実施推奨します。
    * **NATゲートウェイ**：networkフォルダ内の `variables.tf` 内の `default` を `0` に変更し、  
    `terraform plan` → `terraform apply` でリソースの削除を行ってください。
    * **RDS**：AWSマネジメントコンソール上で一時停止を行ってください。
    * **ECSタスク**：AWS CLIコマンドでタスクの停止を行ってください。
```text
  aws ecs update-service \
  --cluster nagoyameshi-prod-ecs-cluster \
  --service nagoyameshi-prod-ecs-service \
  --desired-count 0
```