# ネットワークとボリューム設定ガイド

## ネットワーク構成

### カスタムブリッジネットワーク

JupyterHub環境では専用のブリッジネットワーク`jupyterhub_network`を使用します。

```yaml
networks:
  jupyterhub_network:
    driver: bridge
    name: jupyterhub_network
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
```

### 静的IPアドレス割り当て

| サービス | IPアドレス | 用途 |
|---------|------------|------|
| JupyterHub | 172.20.0.10 | メインハブサービス |
| PostgreSQL | 172.20.0.20 | データベース |
| Cloudflared | 172.20.0.30 | トンネルサービス |
| ユーザーコンテナ | 172.20.1.x～ | 動的割り当て |

### コンテナ間通信

- **サービス名によるDNS解決**: 各コンテナは他のコンテナにサービス名でアクセス可能
- **内部通信の有効化**: ブリッジネットワーク内でのコンテナ間通信が許可
- **IP マスカレード**: 外部ネットワークへのアクセスが可能

### 通信例

```python
# JupyterHub設定でのデータベース接続
c.JupyterHub.db_url = 'postgresql://jupyterhub:password@db:5432/jupyterhub'

# ユーザーコンテナからハブへの接続
# http://jupyterhub:8000 でアクセス可能
```

## ボリューム構成

### 名前付きボリューム

| ボリューム名 | マウント先 | 用途 |
|-------------|-----------|------|
| jupyterhub-data | /srv/jupyterhub | Hub設定・状態データ |
| jupyterhub-user-homes | /home | ユーザーホームディレクトリ |
| postgres-data | /var/lib/postgresql/data | データベースデータ |

### ローカルバインドマウント

データの永続化とバックアップを容易にするため、ローカルディレクトリにバインドマウントします：

```
project-root/
├── data/
│   ├── jupyterhub/     # JupyterHub設定とデータ
│   ├── user-homes/     # 全ユーザーのホームディレクトリ
│   └── postgres/       # PostgreSQLデータベース
```

### データ永続化の仕組み

1. **JupyterHub設定**: 設定ファイル、SSL証明書、ログファイル
2. **ユーザーデータ**: Jupyter Notebook、データファイル、カスタム設定
3. **データベース**: ユーザー情報、認証データ、セッション情報

## トラブルシューティング

### ネットワーク接続問題

```bash
# ネットワーク状態確認
docker network ls
docker network inspect jupyterhub_network

# コンテナ間通信テスト
docker exec jupyterhub ping db
docker exec db ping jupyterhub
```

### ボリューム問題

```bash
# ボリューム状態確認
docker volume ls
docker volume inspect jupyterhub-data

# データディレクトリ権限確認
ls -la data/
ls -la data/jupyterhub/
```

### IP アドレス競合の解決

IP範囲 172.20.0.0/16 が他のDockerネットワークと競合する場合：

1. docker-compose.yml でサブネットを変更
2. 使用中のネットワーク確認: `docker network ls`
3. 競合回避: 172.21.0.0/16 等に変更

## セキュリティ考慮事項

1. **ネットワーク分離**: 外部ネットワークから直接アクセス不可
2. **ファイアウォール**: 必要なポートのみ公開
3. **権限管理**: ボリュームディレクトリの適切な権限設定
4. **データ暗号化**: 機密データの暗号化を推奨