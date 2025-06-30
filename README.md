# JupyterHub + Docker + Cloudflare + Gemini CLI AI強化型学習環境

## システム概要

本プロジェクトは、JupyterHub、Docker、Cloudflare、Gemini CLIを統合したAI強化型の学習環境を提供します。

### 主要コンポーネント

- **JupyterHub**: マルチユーザー対応のJupyter環境
- **Docker**: コンテナ化による環境の分離と再現性
- **Cloudflare**: セキュアなアクセス制御とトンネリング
- **Gemini CLI**: AI支援による開発・学習体験の向上

### ディレクトリ構造

```
.
├── jupyterhub/          # JupyterHub設定ファイル
├── secrets/             # 認証情報（.gitignoreで除外）
├── user-image/          # ユーザー環境用Dockerfile
├── docs/                # ドキュメント
├── README.md            # このファイル
├── .gitignore           # Git除外設定
└── .env.sample          # 環境変数テンプレート
```

## セットアップ

詳細なセットアップ手順については、`docs/setup-guide.md`を参照してください。

### クイックスタート

```bash
# 1. シークレットファイル生成
./secrets/setup-secrets.sh

# 2. 環境変数設定
cp .env.sample .env
# .envファイルを編集して必要な設定を行う

# 3. システム起動
docker compose up -d

# 4. 動作確認
./test/quick-test.sh
```

## テスト

### クイックテスト（基本動作確認）
```bash
./test/quick-test.sh
```

### 統合テスト（包括的なシステム検証）
```bash
./test/integration-test.sh
```

### テストオプション
```bash
# クリーンアップなしで実行
./test/integration-test.sh --no-cleanup

# 特定のテストのみ実行
./test/integration-test.sh --pattern "authentication"
```

## セキュリティ

機密情報は`secrets/`ディレクトリに配置し、Gitから除外されるよう設定しています。