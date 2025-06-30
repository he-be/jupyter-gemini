# メールアドレス認証設定ガイド

## 概要

本システムでは、JupyterHub Native Authenticatorを使用したメールアドレスベースの認証を実装しています。
Cloudflareによる一次認証の後、JupyterHubで二次認証を行う二段階のセキュリティ構造になっています。

## 認証フロー

1. **Cloudflare Access**: ドメインレベルでの一次認証
2. **JupyterHub**: メールアドレスとパスワードによる二次認証

## 設定方法

### 1. 環境変数の設定

`.env`ファイルに以下の設定を追加：

```bash
# 管理者ユーザー（カンマ区切り）
JUPYTERHUB_ADMIN_USERS=admin@example.com,manager@example.com

# 許可するユーザー（カンマ区切り）
ALLOWED_USERS=user1@example.com,user2@example.com

# 許可するメールドメイン（カンマ区切り）
ALLOWED_EMAIL_DOMAINS=example.com,company.com

# オープンサインアップの有効/無効
OPEN_SIGNUP=false
```

### 2. ユーザー管理

#### 管理者ユーザーの追加
- `JUPYTERHUB_ADMIN_USERS`に管理者のメールアドレスを追加
- 管理者は他のユーザーの承認/削除が可能

#### 一般ユーザーの追加
- `ALLOWED_USERS`にユーザーのメールアドレスを追加
- または`ALLOWED_EMAIL_DOMAINS`でドメイン単位で許可

### 3. パスワード要件

- 最小文字数: 8文字
- 一般的なパスワードのチェック: 有効
- ログイン失敗許容回数: 3回

### 4. ユーザー登録フロー

1. ユーザーがサインアップページにアクセス
2. メールアドレスとパスワードを入力
3. 管理者による承認（`OPEN_SIGNUP=false`の場合）
4. 承認後、ログイン可能

### 5. パスワードリセット

- ユーザーはログイン画面からパスワードリセットを要求可能
- 管理者がリセットを実行

## セキュリティ考慮事項

1. **二要素認証**: JupyterHub側では無効（Cloudflareで処理）
2. **メールアドレス検証**: サインアップ時に必須
3. **ブルートフォース対策**: 3回の失敗でアカウントロック

## トラブルシューティング

### ユーザーがログインできない場合
1. メールアドレスが`ALLOWED_USERS`または`ALLOWED_EMAIL_DOMAINS`に含まれているか確認
2. パスワードが要件を満たしているか確認
3. アカウントがロックされていないか確認

### 管理者権限が機能しない場合
1. `JUPYTERHUB_ADMIN_USERS`にメールアドレスが正しく設定されているか確認
2. Docker Composeを再起動して設定を反映