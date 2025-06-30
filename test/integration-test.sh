#!/bin/bash

# JupyterHub + Gemini CLI システム統合テスト
# Usage: ./test/integration-test.sh [options]

set -euo pipefail

# 設定
TEST_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/test/test-results.log"
RESULTS_FILE="$PROJECT_ROOT/test/test-summary.json"
TEST_TIMEOUT=300  # 5分

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# テスト結果カウンター
PASSED=0
FAILED=0
SKIPPED=0

# ログ関数
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$LOG_FILE"
    ((PASSED++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$LOG_FILE"
    ((FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1" | tee -a "$LOG_FILE"
    ((SKIPPED++))
}

# テストユーティリティ関数
wait_for_service() {
    local service_name="$1"
    local port="$2"
    local timeout="${3:-60}"
    
    log_info "Waiting for $service_name on port $port..."
    
    for i in $(seq 1 $timeout); do
        if curl -s -f "http://localhost:$port" > /dev/null 2>&1; then
            log_success "$service_name is responding on port $port"
            return 0
        fi
        sleep 1
    done
    
    log_error "$service_name failed to respond on port $port within $timeout seconds"
    return 1
}

check_docker_service() {
    local service_name="$1"
    
    if docker compose ps "$service_name" | grep -q "Up"; then
        log_success "Docker service $service_name is running"
        return 0
    else
        log_error "Docker service $service_name is not running"
        return 1
    fi
}

# テスト開始
start_tests() {
    log_info "=== JupyterHub統合テスト開始 ==="
    log_info "プロジェクトディレクトリ: $PROJECT_ROOT"
    log_info "ログファイル: $LOG_FILE"
    
    # ログファイルを初期化
    echo "=== テスト開始: $(date) ===" > "$LOG_FILE"
    
    cd "$PROJECT_ROOT"
}

# 1. 前提条件チェック
test_prerequisites() {
    log_info "=== 前提条件チェック ==="
    
    # Docker確認
    if command -v docker >/dev/null 2>&1; then
        log_success "Docker is installed"
    else
        log_error "Docker is not installed"
        return 1
    fi
    
    # Docker Compose確認
    if command -v docker compose >/dev/null 2>&1; then
        log_success "Docker Compose is available"
    else
        log_error "Docker Compose is not available"
        return 1
    fi
    
    # 必要ファイル確認
    local required_files=(
        "docker-compose.yml"
        "jupyterhub/Dockerfile"
        "user-image/Dockerfile"
        "jupyterhub/jupyterhub_config.py"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "Required file exists: $file"
        else
            log_error "Required file missing: $file"
            return 1
        fi
    done
    
    # シークレットファイル確認
    if [[ -f "secrets/db_password.txt" ]]; then
        log_success "Database password secret exists"
    else
        log_warning "Database password secret missing - creating..."
        ./secrets/setup-secrets.sh
    fi
}

# 2. 設定ファイル検証
test_configuration() {
    log_info "=== 設定ファイル検証 ==="
    
    # docker-compose.yml構文チェック
    if docker compose config > /dev/null 2>&1; then
        log_success "docker-compose.yml syntax is valid"
    else
        log_error "docker-compose.yml syntax error"
        docker compose config 2>&1 | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Python設定ファイル構文チェック
    if python3 -m py_compile jupyterhub/jupyterhub_config.py; then
        log_success "jupyterhub_config.py syntax is valid"
    else
        log_error "jupyterhub_config.py syntax error"
        return 1
    fi
}

# 3. イメージビルドテスト
test_image_build() {
    log_info "=== Docker イメージビルドテスト ==="
    
    # JupyterHub イメージビルド
    log_info "Building JupyterHub image..."
    if docker build -t jupyterhub-custom ./jupyterhub; then
        log_success "JupyterHub image built successfully"
    else
        log_error "JupyterHub image build failed"
        return 1
    fi
    
    # ユーザー環境イメージビルド
    log_info "Building user environment image..."
    if timeout 1200 docker build -t jupyter-user-gemini ./user-image; then
        log_success "User environment image built successfully"
    else
        log_error "User environment image build failed or timed out"
        return 1
    fi
}

# 4. サービス起動テスト
test_service_startup() {
    log_info "=== サービス起動テスト ==="
    
    # 既存サービス停止
    docker compose down -v --remove-orphans > /dev/null 2>&1 || true
    
    # データディレクトリ作成
    mkdir -p data/{jupyterhub,user-homes,postgres}
    
    # サービス起動
    log_info "Starting services..."
    if docker compose up -d; then
        log_success "Services started successfully"
    else
        log_error "Failed to start services"
        docker compose logs
        return 1
    fi
    
    # サービス状態確認
    sleep 10
    check_docker_service "jupyterhub" || return 1
    check_docker_service "db" || return 1
}

# 5. ヘルスチェックテスト
test_health_checks() {
    log_info "=== ヘルスチェックテスト ==="
    
    # JupyterHub ヘルスチェック
    wait_for_service "JupyterHub" "8000" 120 || return 1
    
    # データベース接続確認
    if docker compose exec -T db pg_isready -U jupyterhub > /dev/null 2>&1; then
        log_success "Database is ready"
    else
        log_error "Database is not ready"
        return 1
    fi
    
    # JupyterHub API確認
    if curl -s -f "http://localhost:8000/hub/api" > /dev/null; then
        log_success "JupyterHub API is accessible"
    else
        log_error "JupyterHub API is not accessible"
        return 1
    fi
}

# 6. 認証システムテスト
test_authentication() {
    log_info "=== 認証システムテスト ==="
    
    # ログインページ確認
    if curl -s "http://localhost:8000/hub/login" | grep -q "email"; then
        log_success "Login page contains email authentication form"
    else
        log_error "Login page does not contain expected authentication form"
        return 1
    fi
    
    # サインアップページ確認
    if curl -s "http://localhost:8000/hub/signup" | grep -q "signup"; then
        log_success "Signup page is accessible"
    else
        log_warning "Signup page is not accessible (may be disabled)"
    fi
    
    # 認証API確認
    if curl -s -f "http://localhost:8000/hub/api/authorizations/token" > /dev/null; then
        log_success "Authentication API is available"
    else
        log_warning "Authentication API requires credentials"
    fi
}

# 7. Docker Spawner テスト
test_docker_spawner() {
    log_info "=== Docker Spawner テスト ==="
    
    # DockerSpawner設定確認
    if docker compose exec -T jupyterhub python -c "
import sys
sys.path.insert(0, '/srv/jupyterhub')
import jupyterhub_config
spawner_class = getattr(jupyterhub_config.c.JupyterHub, 'spawner_class', None)
assert spawner_class == 'dockerspawner.DockerSpawner'
print('DockerSpawner configured correctly')
" 2>/dev/null; then
        log_success "DockerSpawner is configured correctly"
    else
        log_error "DockerSpawner configuration error"
        return 1
    fi
    
    # ユーザーイメージ確認
    if docker images | grep -q "jupyter-user-gemini"; then
        log_success "User environment image is available"
    else
        log_error "User environment image is not available"
        return 1
    fi
    
    # ネットワーク確認
    if docker network ls | grep -q "jupyterhub_network"; then
        log_success "JupyterHub network exists"
    else
        log_warning "JupyterHub network not found (may be created on first user spawn)"
    fi
}

# 8. ボリューム永続化テスト
test_volume_persistence() {
    log_info "=== ボリューム永続化テスト ==="
    
    # データボリューム確認
    local volumes=("jupyterhub-data" "jupyterhub-user-homes" "postgres-data")
    
    for volume in "${volumes[@]}"; do
        if docker volume ls | grep -q "$volume"; then
            log_success "Volume $volume exists"
        else
            log_error "Volume $volume does not exist"
            return 1
        fi
    done
    
    # データディレクトリ確認
    if [[ -d "data/jupyterhub" ]] && [[ -d "data/user-homes" ]] && [[ -d "data/postgres" ]]; then
        log_success "Data directories exist"
    else
        log_error "Data directories are missing"
        return 1
    fi
    
    # テストファイル作成・確認
    echo "test content" > data/user-homes/test-persistence.txt
    if [[ -f "data/user-homes/test-persistence.txt" ]]; then
        log_success "File persistence test successful"
        rm -f data/user-homes/test-persistence.txt
    else
        log_error "File persistence test failed"
        return 1
    fi
}

# 9. Gemini環境テスト
test_gemini_environment() {
    log_info "=== Gemini環境テスト ==="
    
    # Pythonパッケージ確認
    if docker run --rm jupyter-user-gemini python -c "
import google.generativeai as genai
import langchain
import pandas as pd
print('Required packages are installed')
" 2>/dev/null; then
        log_success "Required Python packages are installed in user environment"
    else
        log_error "Required Python packages are missing"
        return 1
    fi
    
    # セットアップスクリプト確認
    if docker run --rm jupyter-user-gemini test -f "/opt/user-scripts/gemini-setup.sh"; then
        log_success "Gemini setup script is available"
    else
        log_error "Gemini setup script is missing"
        return 1
    fi
    
    # Node.js環境確認
    if docker run --rm jupyter-user-gemini node --version > /dev/null 2>&1; then
        log_success "Node.js is available in user environment"
    else
        log_warning "Node.js is not available in user environment"
    fi
}

# 10. セキュリティテスト
test_security() {
    log_info "=== セキュリティテスト ==="
    
    # 未認証アクセス確認
    if curl -s "http://localhost:8000/user/admin/tree" | grep -q "login"; then
        log_success "Unauthenticated access correctly redirected to login"
    else
        log_warning "Could not verify authentication requirement"
    fi
    
    # シークレットファイル権限確認
    if [[ $(stat -c "%a" secrets/db_password.txt 2>/dev/null) == "600" ]]; then
        log_success "Secret files have correct permissions"
    else
        log_warning "Secret files may have incorrect permissions"
    fi
    
    # Docker socket マウント確認
    if docker compose exec -T jupyterhub test -S /var/run/docker.sock; then
        log_success "Docker socket is mounted in JupyterHub container"
    else
        log_error "Docker socket is not mounted"
        return 1
    fi
}

# 11. 外部接続テスト（オプション）
test_external_connectivity() {
    log_info "=== 外部接続テスト ==="
    
    # ポート公開確認
    if netstat -tlnp 2>/dev/null | grep -q ":8000"; then
        log_success "Port 8000 is listening"
    else
        log_error "Port 8000 is not listening"
        return 1
    fi
    
    # 外部からのアクセステスト（限定的）
    if curl -s -m 5 "http://$(hostname -I | cut -d' ' -f1):8000/hub/health" > /dev/null 2>&1; then
        log_success "External access to JupyterHub is possible"
    else
        log_warning "External access test failed (may be due to network configuration)"
    fi
}

# 12. クリーンアップテスト
test_cleanup() {
    log_info "=== クリーンアップテスト ==="
    
    # サービス停止
    if docker compose down -v --remove-orphans; then
        log_success "Services stopped successfully"
    else
        log_error "Failed to stop services"
        return 1
    fi
    
    # 孤立リソース確認
    local orphaned_containers=$(docker ps -a --filter "label=com.docker.compose.project=jupyter-gemini" -q)
    if [[ -z "$orphaned_containers" ]]; then
        log_success "No orphaned containers found"
    else
        log_warning "Orphaned containers found: $orphaned_containers"
    fi
}

# テスト結果の生成
generate_test_report() {
    log_info "=== テスト結果サマリー ==="
    
    local total=$((PASSED + FAILED + SKIPPED))
    local success_rate=0
    
    if [[ $total -gt 0 ]]; then
        success_rate=$(( (PASSED * 100) / total ))
    fi
    
    # JSON レポート生成
    cat > "$RESULTS_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "total_tests": $total,
  "passed": $PASSED,
  "failed": $FAILED,
  "skipped": $SKIPPED,
  "success_rate": $success_rate,
  "status": "$([[ $FAILED -eq 0 ]] && echo "PASSED" || echo "FAILED")"
}
EOF
    
    # コンソール出力
    echo ""
    echo "================================="
    echo "テスト結果サマリー"
    echo "================================="
    echo "総テスト数: $total"
    echo -e "成功: ${GREEN}$PASSED${NC}"
    echo -e "失敗: ${RED}$FAILED${NC}"
    echo -e "スキップ: ${YELLOW}$SKIPPED${NC}"
    echo "成功率: $success_rate%"
    echo ""
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ 全てのテストが成功しました！${NC}"
        echo ""
        echo "システムは正常に動作しています。"
        echo "詳細ログ: $LOG_FILE"
        echo "結果ファイル: $RESULTS_FILE"
        return 0
    else
        echo -e "${RED}✗ $FAILED個のテストが失敗しました${NC}"
        echo ""
        echo "詳細ログを確認してください: $LOG_FILE"
        echo "結果ファイル: $RESULTS_FILE"
        return 1
    fi
}

# メイン実行フロー
main() {
    local run_cleanup=true
    local test_pattern=".*"
    
    # オプション解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-cleanup)
                run_cleanup=false
                shift
                ;;
            --pattern)
                test_pattern="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --no-cleanup    Keep services running after tests"
                echo "  --pattern REGEX Only run tests matching pattern"
                echo "  --help          Show this help"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    start_tests
    
    # テスト実行
    local tests=(
        "test_prerequisites"
        "test_configuration" 
        "test_image_build"
        "test_service_startup"
        "test_health_checks"
        "test_authentication"
        "test_docker_spawner"
        "test_volume_persistence"
        "test_gemini_environment"
        "test_security"
        "test_external_connectivity"
    )
    
    for test in "${tests[@]}"; do
        if [[ $test =~ $test_pattern ]]; then
            if ! $test; then
                log_error "Test $test failed"
            fi
        else
            log_skip "Test $test skipped (pattern mismatch)"
        fi
    done
    
    # クリーンアップ
    if [[ $run_cleanup == true ]]; then
        test_cleanup
    else
        log_info "Cleanup skipped (--no-cleanup specified)"
    fi
    
    generate_test_report
}

# スクリプト実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi