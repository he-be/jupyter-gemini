# JupyterHub + Gemini CLI セットアップガイド

## 概要

このガイドでは、JupyterHub、Docker、Cloudflare、Gemini CLIを統合したAI強化型学習環境の完全なセットアップ手順を説明します。

## 前提条件とシステム要件

### ハードウェア要件

| コンポーネント | 最小要件 | 推奨要件 |
|---------------|---------|---------|
| CPU | 2コア | 4コア以上 |
| メモリ | 4GB | 8GB以上 |
| ストレージ | 20GB | 50GB以上 |
| ネットワーク | 1Mbps | 10Mbps以上 |

### ソフトウェア要件

- **OS**: Ubuntu 20.04 LTS以降（Ubuntu 22.04 LTS推奨）
- **Docker**: 20.10以降
- **Docker Compose**: 2.0以降
- **Git**: 2.30以降
- **OpenSSL**: 1.1以降

### ネットワーク要件

- **外部アクセス用サーバー**: 192.168.0.202（固定IP推奨）
- **Cloudflaredサーバー**: 192.168.0.200（既存）
- **ポート**: 8000番（JupyterHub用）
- **インターネット接続**: Docker Hub、GitHub、Google APIアクセス用

## セットアップ手順

### 1. システムの準備

#### 1.1 必要なソフトウェアのインストール

```bash
# システムパッケージの更新
sudo apt update && sudo apt upgrade -y

# 必要なパッケージのインストール
sudo apt install -y \
    curl \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    openssl

# Dockerのインストール
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# ユーザーをdockerグループに追加
sudo usermod -aG docker $USER

# ログアウト・ログインまたは以下を実行
newgrp docker

# インストール確認
docker --version
docker compose version
```

#### 1.2 GitHub CLIのインストール（オプション）

```bash
# GitHub CLI のインストール
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# GitHub認証
gh auth login
```

### 2. プロジェクトのセットアップ

#### 2.1 リポジトリのクローン

```bash
# プロジェクトディレクトリに移動
cd /opt  # または任意のディレクトリ
sudo mkdir -p jupyter-gemini
sudo chown $USER:$USER jupyter-gemini
cd jupyter-gemini

# リポジトリのクローン（GitHubから）
git clone https://github.com/your-username/jupyter-gemini.git .

# または手動でファイルを配置する場合
# 必要なファイルを本ガイドの指示に従って作成
```

#### 2.2 ディレクトリ構造の確認

```bash
# ディレクトリ構造の確認
tree -a -L 2
```

期待される構造：
```
.
├── .env.sample
├── .gitignore
├── README.md
├── docker-compose.yml
├── data/
│   ├── jupyterhub/
│   ├── postgres/
│   └── user-homes/
├── docs/
│   ├── ai-usage-guidelines.md
│   ├── authentication-setup.md
│   ├── cloudflare-tunnel-setup.md
│   ├── gemini-cli-setup.md
│   ├── network-volume-setup.md
│   └── setup-guide.md
├── jupyterhub/
│   ├── Dockerfile
│   └── jupyterhub_config.py
├── secrets/
│   ├── README.md
│   └── setup-secrets.sh
└── user-image/
    ├── Dockerfile
    ├── gemini-setup.sh
    └── requirements.txt
```

### 3. 環境設定

#### 3.1 シークレットファイルの生成

```bash
# シークレットファイル自動生成
chmod +x secrets/setup-secrets.sh
./secrets/setup-secrets.sh
```

#### 3.2 環境変数ファイルの設定

```bash
# .envファイルの作成
cp .env.sample .env

# .envファイルの編集
nano .env  # またはお好みのエディタ
```

必須設定項目：
```bash
# JupyterHub Configuration
JUPYTERHUB_ADMIN_USERS=admin@yourdomain.com
JUPYTERHUB_COOKIE_SECRET=  # 自動生成されます
JUPYTERHUB_PROXY_AUTH_TOKEN=  # 自動生成されます

# Authentication Settings
ALLOWED_USERS=user1@yourdomain.com,user2@yourdomain.com
ALLOWED_EMAIL_DOMAINS=yourdomain.com
OPEN_SIGNUP=false

# Cloudflare Configuration
CLOUDFLARE_DOMAIN=yourdomain.com
JUPYTER_SUBDOMAIN=jupyter

# Gemini CLI
GEMINI_API_KEY=your-gemini-api-key-here
```

#### 3.3 Cloudflare Tunnel トークンの設定

```bash
# Cloudflare Tunnelトークンの設定
echo "your-actual-cloudflare-tunnel-token" > secrets/tunnel_token.txt
chmod 600 secrets/tunnel_token.txt
```

### 4. Dockerイメージのビルド

#### 4.1 JupyterHub イメージのビルド

```bash
# JupyterHub カスタムイメージのビルド
docker build -t jupyterhub-custom ./jupyterhub

# ビルド確認
docker images | grep jupyterhub-custom
```

#### 4.2 ユーザー環境イメージのビルド

```bash
# ユーザー環境イメージのビルド（時間がかかります）
docker build -t jupyter-user-gemini ./user-image

# ビルド確認
docker images | grep jupyter-user-gemini
```

### 5. システムの起動

#### 5.1 サービスの起動

```bash
# データディレクトリの権限設定
sudo chown -R 1000:1000 data/

# Docker Composeでサービス起動
docker compose up -d

# サービス状態確認
docker compose ps
```

#### 5.2 ログの確認

```bash
# 全サービスのログ確認
docker compose logs

# 特定サービスのログ確認
docker compose logs jupyterhub
docker compose logs db
```

### 6. 動作確認

#### 6.1 基本動作確認

```bash
# JupyterHubのヘルスチェック
curl -I http://localhost:8000/hub/health

# データベース接続確認
docker compose exec db psql -U jupyterhub -d jupyterhub -c "SELECT version();"
```

#### 6.2 Web インターフェース確認

1. **ローカルアクセス**: http://192.168.0.202:8000
2. **外部ドメインアクセス**: https://jupyter.yourdomain.com

#### 6.3 初回ログイン

1. JupyterHubにアクセス
2. 「Sign up」をクリック（OPEN_SIGNUP=falseの場合は管理者承認が必要）
3. メールアドレスとパスワードでアカウント作成
4. 管理者による承認（必要な場合）
5. ログインしてJupyter環境にアクセス

### 7. Cloudflare Tunnel設定

#### 7.1 既存Cloudflareサーバーでの設定

Cloudflaredサーバー（192.168.0.200）で以下を実行：

1. **Cloudflare Dashboardにアクセス**
   - [Cloudflare Zero Trust](https://one.dash.cloudflare.com)にログイン
   - 「Access」→「Tunnels」を選択

2. **パブリックホスト名の追加**
   - Subdomain: `jupyter`
   - Domain: `yourdomain.com`
   - Service Type: `HTTP`
   - URL: `http://192.168.0.202:8000`

#### 7.2 DNS設定確認

```bash
# DNS解決確認
nslookup jupyter.yourdomain.com

# Cloudflare経由でのアクセス確認
curl -I https://jupyter.yourdomain.com/hub/health
```

### 8. Gemini API設定

#### 8.1 Google AI Studio でのAPIキー取得

1. [Google AI Studio](https://makersuite.google.com/app/apikey)にアクセス
2. Googleアカウントでログイン
3. 「Create API Key」をクリック
4. APIキーをコピー

#### 8.2 JupyterHub環境での設定

```bash
# JupyterHubにログイン後、ターミナルで実行
/opt/user-scripts/gemini-setup.sh

# .envファイルにAPIキーを設定
echo "GEMINI_API_KEY=your-api-key" >> ~/.env
```

### 9. 管理・運用

#### 9.1 ユーザー管理

```bash
# 管理者としてJupyterHubにログイン
# Admin Panelからユーザー管理を実行

# コマンドラインからのユーザー操作（高度）
docker compose exec jupyterhub python -c "
from jupyterhub.app import JupyterHub
app = JupyterHub()
app.initialize()
# ユーザー操作のコードをここに記述
"
```

#### 9.2 バックアップ

```bash
# データのバックアップ
tar -czf backup-$(date +%Y%m%d).tar.gz data/ secrets/

# 設定ファイルのバックアップ
tar -czf config-backup-$(date +%Y%m%d).tar.gz \
    .env docker-compose.yml jupyterhub/ user-image/
```

#### 9.3 アップデート

```bash
# システムの停止
docker compose down

# 新しいコードの取得
git pull origin main

# イメージの再ビルド（必要な場合）
docker compose build

# システムの再起動
docker compose up -d
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. Docker権限エラー

**エラー**: `permission denied while trying to connect to the Docker daemon socket`

**解決方法**:
```bash
# ユーザーをdockerグループに追加
sudo usermod -aG docker $USER
# ログアウト・ログインまたは
newgrp docker
```

#### 2. ポート競合エラー

**エラー**: `Port 8000 is already in use`

**解決方法**:
```bash
# ポート使用状況確認
sudo netstat -tlnp | grep 8000
# または
sudo lsof -i :8000

# 競合プロセスの停止
sudo kill -9 <PID>
```

#### 3. シークレットファイルエラー

**エラー**: `secret "db_password" not found`

**解決方法**:
```bash
# シークレットファイルの存在確認
ls -la secrets/

# 権限確認
ls -la secrets/*.txt

# 再生成
./secrets/setup-secrets.sh
```

#### 4. データベース接続エラー

**エラー**: `could not connect to server`

**解決方法**:
```bash
# データベースコンテナの状態確認
docker compose ps db

# データベースログ確認
docker compose logs db

# データベースの再起動
docker compose restart db
```

#### 5. JupyterHub起動エラー

**エラー**: `JupyterHub failed to start`

**解決方法**:
```bash
# JupyterHubログの詳細確認
docker compose logs jupyterhub

# 設定ファイルの構文確認
docker compose exec jupyterhub python -c "
import sys
sys.path.insert(0, '/srv/jupyterhub')
import jupyterhub_config
print('Config file syntax OK')
"

# JupyterHubの再起動
docker compose restart jupyterhub
```

#### 6. Cloudflare接続エラー

**エラー**: `502 Bad Gateway` または `504 Gateway Timeout`

**確認事項**:
```bash
# JupyterHubサービスの状態確認
curl -I http://192.168.0.202:8000/hub/health

# Cloudflare Tunnel設定確認（192.168.0.200で実行）
sudo systemctl status cloudflared
sudo journalctl -u cloudflared -f

# ネットワーク接続確認
ping 192.168.0.202
telnet 192.168.0.202 8000
```

#### 7. Gemini API認証エラー

**エラー**: `Invalid API key`

**解決方法**:
```bash
# APIキーの確認
echo $GEMINI_API_KEY

# .envファイルの確認
grep GEMINI_API_KEY ~/.env

# APIキーの再設定
export GEMINI_API_KEY="your-correct-api-key"
```

### ログレベル調整

```bash
# JupyterHubのログレベルをDEBUGに変更
# .envファイルで設定
JUPYTERHUB_LOG_LEVEL=DEBUG

# 設定反映
docker compose restart jupyterhub
```

### パフォーマンス監視

```bash
# リソース使用量確認
docker stats

# ディスク使用量確認
df -h
du -sh data/

# ネットワーク接続確認
docker compose exec jupyterhub netstat -tlnp
```

## セキュリティ設定

### 1. ファイアウォール設定

```bash
# UFWの有効化
sudo ufw enable

# 必要なポートのみ開放
sudo ufw allow ssh
sudo ufw allow 8000/tcp
sudo ufw status
```

### 2. SSL/TLS設定

Cloudflare Tunnelを使用する場合、SSL/TLSはCloudflareで処理されます。
独自のSSL証明書が必要な場合：

```bash
# Let's Encryptを使用した証明書取得
sudo apt install certbot
sudo certbot certonly --standalone -d jupyter.yourdomain.com
```

### 3. セキュリティアップデート

```bash
# 定期的なセキュリティアップデート
sudo apt update && sudo apt upgrade -y

# Dockerイメージの更新
docker compose pull
docker compose up -d
```

## 運用開始チェックリスト

### 起動前チェック

- [ ] 全ての環境変数が設定されている
- [ ] シークレットファイルが生成されている
- [ ] Dockerイメージがビルドされている
- [ ] データディレクトリが作成されている
- [ ] ネットワーク設定が正しい

### 動作確認チェック

- [ ] JupyterHubにアクセスできる
- [ ] ユーザー登録・ログインができる
- [ ] Jupyter Notebookが起動する
- [ ] Gemini APIが利用できる
- [ ] 外部ドメインからアクセスできる

### セキュリティチェック

- [ ] デフォルトパスワードが変更されている
- [ ] 不要なポートが閉じられている
- [ ] ログ監視が設定されている
- [ ] バックアップが設定されている

これで、JupyterHub + Gemini CLI環境の完全なセットアップが完了します。問題が発生した場合は、トラブルシューティングセクションを参照してください。