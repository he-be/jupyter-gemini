# 既存Cloudflare Tunnelとの連携設定ガイド

## 構成概要

本システムは既存のCloudflare Tunnel環境と連携して動作します：

- **既存cloudflaredサーバー**: 192.168.0.200（変更不要）
- **JupyterHubサーバー**: 192.168.0.202:8000
- **外部アクセス**: https://jupyter.yourdomain.com

## アーキテクチャ

```
インターネット
    ↓
Cloudflare CDN
    ↓
Cloudflare Tunnel (192.168.0.200)
    ↓ 内部ルーティング
JupyterHub Server (192.168.0.202:8000)
```

## Cloudflare Dashboard設定

### 1. Zero Trustダッシュボードにアクセス

1. [Cloudflare Zero Trust](https://one.dash.cloudflare.com) にログイン
2. 「Access」→「Tunnels」を選択
3. 既存のトンネルを選択

### 2. 公開ホスト名の追加

「Public Hostnames」タブで新しいルートを追加：

| 設定項目 | 値 |
|---------|---|
| Subdomain | jupyter |
| Domain | yourdomain.com |
| Path | （空白） |
| Service Type | HTTP |
| URL | http://192.168.0.202:8000 |

### 3. 詳細設定

**Origin Server Name**: `192.168.0.202`
**Additional Headers**: 
```
X-Forwarded-Proto: https
X-Forwarded-Host: jupyter.yourdomain.com
```

**TLS Settings**:
- TLS Verification: Off（内部ネットワークのため）
- Origin Server Name: （空白）

## JupyterHub設定

### Base URL設定

JupyterHubが外部ドメイン経由でアクセスされることを考慮し、必要に応じて base URL を設定：

```python
# jupyterhub_config.py
c.JupyterHub.base_url = os.environ.get('JUPYTERHUB_BASE_URL', '/')
```

### リバースプロキシ対応

```python
# jupyterhub_config.py
# Trust forwarded headers from Cloudflare
c.JupyterHub.trusted_upstream_ips = ['0.0.0.0/0']  # Cloudflare IPs
```

## 接続テスト

### 1. ローカル接続確認

```bash
# JupyterHubサーバー（192.168.0.202）で実行
curl -I http://localhost:8000/hub/health
```

### 2. 内部ネットワーク接続確認

```bash
# cloudflaredサーバー（192.168.0.200）で実行
curl -I http://192.168.0.202:8000/hub/health
```

### 3. 外部ドメイン接続確認

```bash
curl -I https://jupyter.yourdomain.com/hub/health
```

## トラブルシューティング

### 1. 502 Bad Gateway エラー

**原因**: JupyterHubサービスが起動していない
**解決**: 
```bash
docker-compose up jupyterhub
docker-compose logs jupyterhub
```

### 2. 504 Gateway Timeout

**原因**: ネットワーク接続の問題
**確認事項**:
- ファイアウォール設定
- ポート8000の開放状況
- JupyterHubの応答性能

### 3. Cloudflare Tunnel接続エラー

**確認手順**:
1. cloudflaredサービスの状態確認（192.168.0.200）
2. トンネル設定の確認
3. DNS設定の確認

## セキュリティ設定

### 1. Cloudflare Access Policy

Zero Trustダッシュボードで適切なアクセスポリシーを設定：

- **Email Authentication**: 許可するメールドメイン
- **IP Restrictions**: 必要に応じてIPアドレス制限
- **Multi-Factor Authentication**: 2FA の有効化

### 2. JupyterHub認証との連携

JupyterHubの認証はCloudflare Accessと独立して動作します：

1. **一次認証**: Cloudflare Access（ドメインレベル）
2. **二次認証**: JupyterHub Native Authenticator（アプリケーションレベル）

## 監視とログ

### Cloudflare Analytics

- アクセス統計の確認
- エラー率の監視
- レスポンス時間の測定

### JupyterHub ログ

```bash
# ログの確認
docker-compose logs -f jupyterhub

# 特定期間のログ
docker-compose logs --since 1h jupyterhub
```

## 設定例

### Cloudflare Tunnel設定（参考）

```yaml
# config.yml（cloudflaredサーバー側）
tunnel: your-tunnel-id
credentials-file: /path/to/credentials.json

ingress:
  - hostname: jupyter.yourdomain.com
    service: http://192.168.0.202:8000
    originRequest:
      noTLSVerify: true
  - service: http_status:404
```

この設定により、既存のCloudflare Tunnel環境を活用してJupyterHubへの安全なアクセスが可能になります。