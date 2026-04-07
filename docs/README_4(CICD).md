# CI/CD代表的なエラーと対応(AWS CodePipeline, CodeBuild)


## ECRにアクセスできない（ログイン失敗）
原因：ECRログイン処理未実行／リージョン違い／IAM権限不足
対応：
- `aws ecr get-login-password` の実行確認
- リージョン（ap-northeast-1）確認
- CodeBuildロールに ecr:*（push系）権限付与

## ECRリポジトリ名の記載ミス
原因：リポジトリURIの誤り
対応：
- ECRのリポジトリURIを正確にコピー
- buildspec.yml内のURIと一致させる

## Dockerイメージのpush失敗
原因：タグ不一致／ログイン失敗／権限不足
対応：
- docker tag と docker push のURI一致確認
- latestタグの付与確認
- IAM権限確認

## imagedefinitions.jsonの不備
原因：コンテナ名不一致／JSON形式エラー／ファイル未生成
対応：
- ECSタスク定義のcontainer名と一致させる
- buildspec.ymlのpost_buildを確認
- JSON形式の誤り修正

## CodeBuildでDocker build失敗
原因：Dockerfileパス誤り／COPY対象不足／文法エラー
対応：
- Dockerfileの場所確認
- build context確認
- ログのエラー行を修正

## ECSデプロイ失敗（タスク起動失敗）
原因：環境変数不足／Secrets参照ミス／イメージ取得失敗
対応：
- ECSタスクの停止理由を確認
- 環境変数・SSM・Secretsの設定確認
- ECRのイメージURI確認

## ECSが最新イメージを参照しない（latestタグ問題）
原因：古いイメージキャッシュ／タグ運用不備
対応：
- 新しいタスク定義リビジョンが作成されているか確認
- 可能ならタグをlatest以外（commit hash）に変更

## ECSタスク定義のリビジョン不整合
原因：サービスが古いタスク定義を参照している
対応：
- ECS Serviceのtask definition revision確認
- 必要に応じてサービスを再デプロイ

## タスクは起動するが画面が表示されない
原因：ALBヘルスチェック不一致／ポート設定ミス／SG設定不足
対応：
- Target Groupのhealth check確認
- containerPortとALB設定一致確認
- Security Groupの疎通確認

## ALBのターゲットがunhealthy
原因：ヘルスチェックパス誤り／アプリ未起動
対応：
- / や /health など正しいパスに修正
- コンテナログ確認

## DB接続エラー（RDS接続不可）
原因：接続情報誤り／SG設定不足／RDS停止
対応：
- DBホスト・ユーザー・パスワード確認
- ECS→RDSのセキュリティグループ許可
- RDS起動状態確認

## 権限不足（IAMエラー）
原因：CodeBuild / ECS / Task Role の権限不足
対応：
- CloudWatch LogsやCodePipelineの実行ログを確認
- 必要なポリシー追加（ECR / Logs / SSM / Secretsなど）
- ECS Deployでは `ecs:TagResource` や `ecs:DescribeTasks` など追加権限が必要になる場合がある