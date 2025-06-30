# Gemini CLI認証設定ガイド

## 概要

このガイドでは、JupyterHub環境でGemini APIを利用するための認証設定手順を説明します。

## 認証方法の選択

Gemini APIには2つの認証方法があります：

1. **APIキー認証（推奨）**: シンプルで設定が容易
2. **OAuth 2.0認証**: より高度なセキュリティが必要な場合

## 方法1: APIキー認証（推奨）

### 1. Google AI StudioでのAPIキー取得

1. [Google AI Studio](https://makersuite.google.com/app/apikey) にアクセス
2. Googleアカウントでログイン
3. 「Create API Key」をクリック
4. 新しいプロジェクトを作成するか、既存プロジェクトを選択
5. 生成されたAPIキーをコピーして安全に保存

### 2. JupyterHub環境での設定

#### 環境変数による設定

JupyterHubにログイン後、ターミナルで以下を実行：

```bash
# .envファイルを作成
echo "GEMINI_API_KEY=your-api-key-here" >> ~/.env

# 権限設定
chmod 600 ~/.env

# 現在のセッションで有効化
source ~/.env
```

#### Python環境での利用

```python
import os
from dotenv import load_dotenv
import google.generativeai as genai

# 環境変数読み込み
load_dotenv()

# APIキー設定
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))

# テスト実行
model = genai.GenerativeModel('gemini-pro')
response = model.generate_content("Hello, how are you?")
print(response.text)
```

#### 初回セットアップスクリプトの実行

```bash
# セットアップスクリプトを実行
/opt/user-scripts/gemini-setup.sh

# .envファイルを編集してAPIキーを設定
nano ~/.env
```

### 3. 設定の検証

```python
import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()

# 設定確認
api_key = os.getenv('GEMINI_API_KEY')
if api_key:
    print("✓ APIキーが設定されています")
    genai.configure(api_key=api_key)
    
    # 利用可能なモデル一覧表示
    print("利用可能なモデル:")
    for model in genai.list_models():
        if 'generateContent' in model.supported_generation_methods:
            print(f"  - {model.name}")
else:
    print("❌ APIキーが設定されていません")
```

## 方法2: OAuth 2.0認証（高度なユーザー向け）

### 1. Google Cloud Consoleでの設定

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. プロジェクトを作成または選択
3. 「APIs & Services」→「Credentials」
4. 「Create Credentials」→「OAuth 2.0 Client IDs」
5. Application type: 「Desktop application」
6. 作成されたクライアントIDとシークレットをダウンロード

### 2. 認証フローの実行

#### 初回認証

```python
import google.auth
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow

# OAuth設定
SCOPES = ['https://www.googleapis.com/auth/generative-ai']
CLIENT_SECRETS_FILE = 'client_secrets.json'  # ダウンロードしたファイル

def authenticate_oauth():
    flow = InstalledAppFlow.from_client_secrets_file(
        CLIENT_SECRETS_FILE, SCOPES)
    
    # ローカルサーバーで認証（JupyterHub環境では手動処理が必要）
    creds = flow.run_local_server(port=0)
    
    # 認証情報を保存
    with open('token.json', 'w') as token:
        token.write(creds.to_json())
    
    return creds

# 認証実行
credentials = authenticate_oauth()
```

#### JupyterHub環境での手動認証手順

OAuth認証はブラウザ連携が必要なため、JupyterHub環境では以下の手順を実行：

1. **認証URLの生成**
```python
from google_auth_oauthlib.flow import Flow

flow = Flow.from_client_secrets_file(
    'client_secrets.json',
    scopes=['https://www.googleapis.com/auth/generative-ai'])
flow.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'

auth_url, _ = flow.authorization_url(prompt='consent')
print(f"認証URL: {auth_url}")
```

2. **ブラウザでの認証**
   - 表示されたURLをブラウザで開く
   - Googleアカウントでログイン
   - 許可を与える
   - 表示された認証コードをコピー

3. **認証コードの入力**
```python
auth_code = input("認証コードを入力してください: ")
flow.fetch_token(code=auth_code)

# 認証情報保存
credentials = flow.credentials
with open('token.json', 'w') as token:
    token.write(credentials.to_json())
```

### 3. 保存された認証情報の使用

```python
import google.auth
from google.oauth2.credentials import Credentials
import google.generativeai as genai

# 保存された認証情報読み込み
creds = Credentials.from_authorized_user_file('token.json')

# APIクライアント設定
genai.configure(credentials=creds)

# テスト実行
model = genai.GenerativeModel('gemini-pro')
response = model.generate_content("Hello, how are you?")
print(response.text)
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. APIキーが無効

**エラー**: `Invalid API key`

**解決方法**:
- APIキーが正しく設定されているか確認
- Google AI Studioでキーが有効か確認
- キーに不要なスペースや改行が含まれていないか確認

#### 2. 認証情報の期限切れ

**エラー**: `Credentials expired`

**解決方法**:
```python
from google.auth.transport.requests import Request

if creds.expired and creds.refresh_token:
    creds.refresh(Request())
    # 更新された認証情報を保存
    with open('token.json', 'w') as token:
        token.write(creds.to_json())
```

#### 3. ネットワーク接続エラー

**エラー**: `Connection timeout` または `Network error`

**解決方法**:
- インターネット接続を確認
- プロキシ設定が必要な場合は環境変数を設定
- ファイアウォール設定を確認

#### 4. 権限エラー

**エラー**: `Permission denied`

**解決方法**:
- Google Cloud Consoleでプロジェクトの権限確認
- 必要なAPIが有効化されているか確認
- OAuth同意画面の設定確認

### デバッグ用コマンド

```python
import logging
import google.generativeai as genai

# ログレベル設定
logging.basicConfig(level=logging.DEBUG)

# 詳細なエラー情報表示
try:
    model = genai.GenerativeModel('gemini-pro')
    response = model.generate_content("Test")
    print(response.text)
except Exception as e:
    print(f"エラー詳細: {e}")
    import traceback
    traceback.print_exc()
```

## 初回利用時のテスト

### 1. 基本動作確認

```python
import google.generativeai as genai
from dotenv import load_dotenv
import os

# 設定読み込み
load_dotenv()
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))

# 基本テスト
print("=== Gemini API 基本テスト ===")
model = genai.GenerativeModel('gemini-pro')
response = model.generate_content("1 + 1 = ?")
print(f"回答: {response.text}")
```

### 2. 対話型テスト

```python
def chat_test():
    model = genai.GenerativeModel('gemini-pro')
    chat = model.start_chat()
    
    print("=== Gemini 対話テスト（'quit'で終了）===")
    while True:
        user_input = input("あなた: ")
        if user_input.lower() == 'quit':
            break
        
        response = chat.send_message(user_input)
        print(f"Gemini: {response.text}")

# テスト実行
chat_test()
```

### 3. 画像解析テスト（Gemini Pro Vision）

```python
import PIL.Image

# 画像読み込み
image = PIL.Image.open('test_image.jpg')

# Vision モデルでテスト
model = genai.GenerativeModel('gemini-pro-vision')
response = model.generate_content(["この画像について説明してください", image])
print(response.text)
```

## セキュリティ考慮事項

1. **APIキー管理**
   - APIキーをコードに直接記述しない
   - .envファイルの権限を適切に設定（600）
   - 定期的なAPIキーのローテーション

2. **認証情報の保護**
   - OAuth認証情報を安全に保存
   - token.jsonファイルの権限設定
   - 共有環境での注意事項

3. **利用量監視**
   - Google Cloud Consoleでの使用量確認
   - 必要に応じて利用制限設定
   - 異常な使用パターンの監視

これで、JupyterHub環境でGemini APIを安全かつ効率的に利用できるようになります。