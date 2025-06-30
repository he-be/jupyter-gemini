#!/bin/bash

# JupyterHub クイックテスト
# システムの基本動作を短時間で確認

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# カラー出力
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "=== JupyterHub クイックテスト ==="
echo ""

# 1. 設定ファイル確認
echo "1. 設定ファイル確認..."
if docker compose config > /dev/null 2>&1; then
    log_success "docker-compose.yml 構文OK"
else
    log_error "docker-compose.yml 構文エラー"
    exit 1
fi

# 2. シークレットファイル確認
echo "2. シークレットファイル確認..."
if [[ -f "secrets/db_password.txt" ]]; then
    log_success "シークレットファイル存在"
else
    log_warning "シークレットファイル未作成 - 自動生成中..."
    ./secrets/setup-secrets.sh
fi

# 3. サービス起動確認
echo "3. サービス起動確認..."
if docker compose ps | grep -q "Up"; then
    log_success "サービス稼働中"
    
    # ヘルスチェック
    if curl -s -f "http://localhost:8000/hub/health" > /dev/null; then
        log_success "JupyterHub応答OK"
    else
        log_warning "JupyterHub応答待ち..."
        sleep 5
        if curl -s -f "http://localhost:8000/hub/health" > /dev/null; then
            log_success "JupyterHub応答OK（遅延）"
        else
            log_error "JupyterHub応答なし"
        fi
    fi
else
    log_warning "サービス未起動 - 起動中..."
    docker compose up -d
    echo "30秒待機..."
    sleep 30
    
    if curl -s -f "http://localhost:8000/hub/health" > /dev/null; then
        log_success "JupyterHub起動成功"
    else
        log_error "JupyterHub起動失敗"
        echo "ログを確認してください:"
        docker compose logs jupyterhub --tail=20
        exit 1
    fi
fi

# 4. ログインページ確認
echo "4. 認証システム確認..."
if curl -s "http://localhost:8000/hub/login" | grep -q "email"; then
    log_success "メールアドレス認証フォーム確認OK"
else
    log_error "認証フォーム確認失敗"
fi

# 5. アクセス情報表示
echo ""
echo "=== アクセス情報 ==="
echo "ローカルアクセス: http://localhost:8000"
echo "内部ネットワーク: http://$(hostname -I | cut -d' ' -f1):8000"
echo ""

# 6. 次のステップ
echo "=== 次のステップ ==="
echo "1. ブラウザでJupyterHubにアクセス"
echo "2. メールアドレスでユーザー登録"
echo "3. 管理者による承認（必要な場合）"
echo "4. Jupyter環境でGemini APIを設定"
echo ""
echo "詳細なテスト: ./test/integration-test.sh"
echo "設定ガイド: docs/setup-guide.md"