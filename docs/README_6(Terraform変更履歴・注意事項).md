# Terraform変更履歴（一部）と plan/apply時の注意事項

本ドキュメントでは、Terraform適用時の注意点および構築過程での変更内容を整理する。

---

## 変更履歴（抜粋）

- dev / prod / network のディレクトリ分離
- networkディレクトリのvariablesにて、各サブネットのCIDRを変数として定義
- dev / prod ディレクトリにてRDSおよびECRの定義を完了
- ALB作成時、サブネットの参照ミスによりterraform planでエラー発生。dataソースおよびディレクトリ間参照を修正し、疎通を確認
- メンテナンス性向上のため、リソース名から環境名プレフィックスを削除（dev_alb → alb）
- メンテナンス性向上のため、dev/prodディレクトリのvariablesにて各環境変数の定義を見直し
- dev / prod ディレクトリにて、networkディレクトリで作成したVPC、サブネットの情報を取得するためのdataソースを追加
- ALB セキュリティグループのアウトバウンドを、全許可からECSへのポート80のみ許可へ変更
- RDS Migration用にECSタスク定義を追加。マイグレーション実行コマンドと環境変数定義を適切に設定
- prod(本番環境)にて、秘匿性の高いAPP_KEYとDB_PASSWORDを、SSM Parameter Store管理からSecrets Manager管理へ移行
- 耐障害性、可用性向上を考慮し、ECS Auto Scaling、RDS Multi-AZ設定を追加
- セキュリティの監視の可視化を目的として、CloudWatch Dashboardのリソースを追加
- CloudWatch Alarmsの統計値を Average から Minimum に変更し、より感度の高い監視設定に調整
- AWS CodePipelineのBuildステージにてエラー発生。IAMロールを追加し、ECSタスク定義のデプロイを完了
- CodeBuild内でのアーティファクト生成およびデプロイ設定を修正し、CodePipelineを完成
---

## terraform plan確認内容
terraform apply 適用前に、以下の観点で差分を確認する。

- 不要なリソース削除（destroy）が含まれていないか
- ALB / RDSなどの主要リソースが再作成対象になっていないか
- 変更対象が意図したリソースのみであるか
- ECSサービスの設定変更が意図通りであるか
- ECSサービス等の変更時、意図せずALBやRDSに対してdestroy（削除）が発生していないかを確認
- CodePipeline経由でECSタスク定義が更新された後にTerraformを実行すると、Terraform側のコードにある古いリビジョンへ戻す差分が発生する場合がある。　→ 対応：lifecycle { ignore_changes = [task_definition] } を設定
---

## apply失敗時の対応

- エラーメッセージを確認し、原因（リソース参照 / IAM / 依存関係）を特定
- リソース参照ミス（例：aws_lbの名前変更）を修正
- 依存関係（resource / data）の確認・修正
- 修正後に再度 terraform plan で差分を確認し、問題なければ再apply