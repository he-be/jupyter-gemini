# AI活用ガイドライン

## 概要

このガイドラインでは、JupyterHub環境でGemini APIを効果的かつ安全に活用するためのベストプラクティスを説明します。

## 1. 効果的なプロンプト作成

### 1.1 基本原則

#### 明確で具体的な指示
❌ **悪い例**:
```
このコードを良くして
```

✅ **良い例**:
```
以下のPythonコードの性能を改善してください。
特に以下の点に注意してください：
1. 時間計算量の最適化
2. メモリ使用量の削減
3. 可読性の維持

[コード]
```

#### 構造化されたプロンプト
```
## 目的
データ分析のためのPandasコードを生成

## 要件
- CSVファイルを読み込み
- 欠損値を処理
- 基本統計量を表示
- グラフ化（matplotlib使用）

## 制約
- Python 3.11対応
- メモリ効率を重視
- エラーハンドリング必須

## 期待する出力
実行可能なPythonコード + 説明コメント
```

### 1.2 コンテキスト提供

#### ファイル参照の活用
```python
# Jupyter Notebookセル内で
import google.generativeai as genai

# ファイル内容を含めたプロンプト
with open('data_analysis.py', 'r') as f:
    code_content = f.read()

prompt = f"""
以下のコードを分析して改善点を提示してください：

```python
{code_content}
```

改善観点：
1. パフォーマンス
2. 可読性
3. エラーハンドリング
4. ベストプラクティス適用
"""

model = genai.GenerativeModel('gemini-pro')
response = model.generate_content(prompt)
print(response.text)
```

#### 段階的なコンテキスト構築
```python
# 対話型でコンテキストを構築
chat = model.start_chat()

# 1. プロジェクト概要を提供
chat.send_message("機械学習を使った売上予測プロジェクトに取り組んでいます")

# 2. 具体的な課題を説明
chat.send_message("データに季節性があり、LSTMモデルを検討中です")

# 3. 具体的な質問
response = chat.send_message("時系列データの前処理で注意すべき点を教えてください")
```

## 2. ハルシネーション回避戦略

### 2.1 事実確認の実装

#### 検証可能な回答の要求
```python
prompt = """
Pythonのpandas.DataFrame.groupby()メソッドについて説明してください。

以下の形式で回答してください：
1. 基本的な使い方（コード例付き）
2. 公式ドキュメントへのリンク
3. よくあるエラーとその対処法
4. パフォーマンス考慮事項

※ 不確実な情報については「確認が必要」と明記してください
"""
```

#### 段階的検証
```python
def verify_ai_response(code_snippet):
    """AIが生成したコードの検証"""
    try:
        # 構文チェック
        compile(code_snippet, '<string>', 'exec')
        print("✓ 構文チェック: 合格")
        
        # 簡単な実行テスト
        exec(code_snippet)
        print("✓ 実行テスト: 合格")
        
    except SyntaxError as e:
        print(f"❌ 構文エラー: {e}")
    except Exception as e:
        print(f"⚠️ 実行時エラー: {e}")

# AIが生成したコードをテスト
ai_generated_code = """
import pandas as pd
df = pd.DataFrame({'A': [1, 2, 3], 'B': [4, 5, 6]})
print(df.head())
"""

verify_ai_response(ai_generated_code)
```

### 2.2 信頼できるソースとの照合

#### 公式ドキュメントとの比較
```python
def cross_reference_check(topic, ai_response):
    """AIの回答を公式ドキュメントと照合"""
    
    print(f"=== {topic} の検証 ===")
    print("AI回答:")
    print(ai_response)
    print("\n推奨確認先:")
    
    reference_sources = {
        "pandas": "https://pandas.pydata.org/docs/",
        "numpy": "https://numpy.org/doc/",
        "matplotlib": "https://matplotlib.org/stable/",
        "scikit-learn": "https://scikit-learn.org/stable/",
        "tensorflow": "https://www.tensorflow.org/api_docs"
    }
    
    for lib, url in reference_sources.items():
        if lib.lower() in topic.lower():
            print(f"- {lib}公式ドキュメント: {url}")
```

## 3. 教育的ワークフロー

### 3.1 コード理解支援

#### ステップバイステップ解説
```python
def explain_code_step_by_step(code):
    prompt = f"""
以下のコードを初心者にもわかりやすく解説してください：

```python
{code}
```

以下の形式で回答してください：
1. 全体の目的
2. 各行の詳細解説
3. 使用されている概念・技術
4. 実行結果の予想
5. 学習ポイント
"""
    
    model = genai.GenerativeModel('gemini-pro')
    response = model.generate_content(prompt)
    return response.text

# 使用例
complex_code = """
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
clf = RandomForestClassifier(n_estimators=100, random_state=42)
clf.fit(X_train, y_train)
predictions = clf.predict(X_test)
print(classification_report(y_test, predictions))
"""

explanation = explain_code_step_by_step(complex_code)
print(explanation)
```

### 3.2 デバッグ支援

#### 体系的なデバッグアプローチ
```python
def ai_debug_assistant(error_message, code_context):
    prompt = f"""
以下のエラーメッセージとコードを分析して、デバッグ手順を提示してください：

エラーメッセージ:
{error_message}

関連コード:
```python
{code_context}
```

以下の形式で回答してください：
1. エラーの原因分析
2. 具体的な修正方法
3. 予防策
4. 関連する学習リソース
5. テスト方法
"""
    
    model = genai.GenerativeModel('gemini-pro')
    response = model.generate_content(prompt)
    return response.text

# 使用例
error_msg = "KeyError: 'column_name'"
problematic_code = """
import pandas as pd
df = pd.read_csv('data.csv')
result = df['column_name'].mean()
"""

debug_advice = ai_debug_assistant(error_msg, problematic_code)
print(debug_advice)
```

### 3.3 テスト生成支援

#### 自動テストケース生成
```python
def generate_test_cases(function_code):
    prompt = f"""
以下の関数に対して、包括的なテストケースを生成してください：

```python
{function_code}
```

以下を含むテストケースを作成してください：
1. 正常系テスト（境界値含む）
2. 異常系テスト（エラー処理）
3. エッジケーステスト
4. パフォーマンステスト（必要に応じて）

pytest形式で出力してください。
"""
    
    model = genai.GenerativeModel('gemini-pro')
    response = model.generate_content(prompt)
    return response.text

# 使用例
function_to_test = """
def calculate_bmi(weight, height):
    if height <= 0:
        raise ValueError("身長は正の数である必要があります")
    bmi = weight / (height ** 2)
    return round(bmi, 2)
"""

test_code = generate_test_cases(function_to_test)
print(test_code)
```

## 4. GEMINI.mdファイル活用法

### 4.1 プロジェクト固有の指示

プロジェクトルートに`GEMINI.md`ファイルを作成し、AIアシスタントへの指示を記述：

```markdown
# プロジェクト: 売上予測システム

## プロジェクト概要
ECサイトの売上データを使用した機械学習による予測システム

## 技術スタック
- Python 3.11
- pandas, numpy, scikit-learn
- FastAPI (API層)
- Docker (デプロイ)

## コーディング規約
- PEP 8準拠
- 型ヒント必須
- docstring必須
- 単体テストカバレッジ80%以上

## データ仕様
- 売上データ: sales_data.csv
- 顧客データ: customer_data.csv
- 商品データ: product_data.csv

## AI支援時の注意点
1. データプライバシーを考慮
2. 本番環境の設定は含めない
3. セキュリティベストプラクティスを適用
4. エラーハンドリングを必ず含める
```

### 4.2 ワークフロー統合

```python
def load_project_context():
    """プロジェクトコンテキストをAIに提供"""
    try:
        with open('GEMINI.md', 'r', encoding='utf-8') as f:
            project_context = f.read()
        return project_context
    except FileNotFoundError:
        return "プロジェクト固有の指示ファイルが見つかりません"

def ai_with_project_context(user_query):
    """プロジェクトコンテキストを含めてAIに質問"""
    context = load_project_context()
    
    prompt = f"""
プロジェクト情報:
{context}

質問: {user_query}

上記のプロジェクト仕様と技術スタックを考慮して回答してください。
"""
    
    model = genai.GenerativeModel('gemini-pro')
    response = model.generate_content(prompt)
    return response.text
```

## 5. セキュリティ・プライバシー配慮

### 5.1 機密情報の除去

```python
import re

def sanitize_code_for_ai(code_content):
    """コードから機密情報を除去"""
    
    # パスワード、キー、トークンのパターン
    sensitive_patterns = [
        r'password\s*=\s*["\'][^"\']+["\']',
        r'api_key\s*=\s*["\'][^"\']+["\']',
        r'secret\s*=\s*["\'][^"\']+["\']',
        r'token\s*=\s*["\'][^"\']+["\']',
    ]
    
    sanitized_code = code_content
    for pattern in sensitive_patterns:
        sanitized_code = re.sub(pattern, 
                               lambda m: m.group().split('=')[0] + '= "***"', 
                               sanitized_code, flags=re.IGNORECASE)
    
    return sanitized_code

# 使用例
original_code = """
api_key = "sk-1234567890abcdef"
password = "my_secret_password"
connection_string = "postgresql://user:pass@localhost:5432/db"
"""

safe_code = sanitize_code_for_ai(original_code)
print(safe_code)
```

### 5.2 データ匿名化

```python
def anonymize_data_for_ai(data_description):
    """データの説明を匿名化"""
    
    anonymization_map = {
        '顧客名': '顧客ID',
        '実際の会社名': 'Company_A',
        '個人情報': '匿名化されたデータ',
        '機密プロジェクト': 'プロジェクトX'
    }
    
    anonymized = data_description
    for original, replacement in anonymization_map.items():
        anonymized = anonymized.replace(original, replacement)
    
    return anonymized
```

## 6. パフォーマンス最適化

### 6.1 効率的なAPI利用

```python
class GeminiOptimizer:
    def __init__(self):
        self.cache = {}
        self.model = genai.GenerativeModel('gemini-pro')
    
    def cached_generate(self, prompt):
        """キャッシュ機能付きの生成"""
        prompt_hash = hash(prompt)
        if prompt_hash in self.cache:
            print("キャッシュから回答を取得")
            return self.cache[prompt_hash]
        
        response = self.model.generate_content(prompt)
        self.cache[prompt_hash] = response.text
        return response.text
    
    def batch_generate(self, prompts):
        """バッチ処理での効率化"""
        responses = []
        for prompt in prompts:
            response = self.cached_generate(prompt)
            responses.append(response)
        return responses

# 使用例
optimizer = GeminiOptimizer()
response = optimizer.cached_generate("Pythonのリスト内包表記について説明してください")
```

### 6.2 コスト管理

```python
import time
from datetime import datetime

class CostTracker:
    def __init__(self):
        self.usage_log = []
    
    def track_request(self, prompt, response):
        """API使用量を追跡"""
        usage_info = {
            'timestamp': datetime.now(),
            'prompt_length': len(prompt),
            'response_length': len(response),
            'estimated_tokens': (len(prompt) + len(response)) // 4  # 概算
        }
        self.usage_log.append(usage_info)
    
    def get_usage_summary(self):
        """使用量サマリーを表示"""
        total_requests = len(self.usage_log)
        total_tokens = sum(log['estimated_tokens'] for log in self.usage_log)
        
        print(f"総リクエスト数: {total_requests}")
        print(f"推定総トークン数: {total_tokens}")
        print(f"平均トークン/リクエスト: {total_tokens/total_requests if total_requests > 0 else 0}")

# 使用例
tracker = CostTracker()
# API呼び出し時に使用量を記録
tracker.track_request(prompt, response)
tracker.get_usage_summary()
```

## 7. 学習成果の記録

### 7.1 学習ログの管理

```python
import json
from datetime import datetime

class LearningJournal:
    def __init__(self, journal_file='learning_journal.json'):
        self.journal_file = journal_file
        self.load_journal()
    
    def load_journal(self):
        """学習ジャーナルを読み込み"""
        try:
            with open(self.journal_file, 'r', encoding='utf-8') as f:
                self.entries = json.load(f)
        except FileNotFoundError:
            self.entries = []
    
    def add_entry(self, topic, question, ai_response, notes=""):
        """学習エントリを追加"""
        entry = {
            'timestamp': datetime.now().isoformat(),
            'topic': topic,
            'question': question,
            'ai_response': ai_response,
            'personal_notes': notes,
            'tags': self.extract_tags(question)
        }
        self.entries.append(entry)
        self.save_journal()
    
    def extract_tags(self, text):
        """テキストからタグを抽出"""
        # 簡単なタグ抽出ロジック
        common_tags = ['python', 'pandas', 'machine learning', 'debug', 'optimization']
        return [tag for tag in common_tags if tag.lower() in text.lower()]
    
    def save_journal(self):
        """ジャーナルを保存"""
        with open(self.journal_file, 'w', encoding='utf-8') as f:
            json.dump(self.entries, f, ensure_ascii=False, indent=2)
    
    def search_entries(self, keyword):
        """エントリを検索"""
        matching_entries = []
        for entry in self.entries:
            if keyword.lower() in entry['question'].lower() or \
               keyword.lower() in entry['topic'].lower():
                matching_entries.append(entry)
        return matching_entries

# 使用例
journal = LearningJournal()
journal.add_entry(
    topic="データ分析",
    question="pandasでグループ化してからソートする方法",
    ai_response="df.groupby('column').sum().sort_values('sum_column')",
    notes="groupby後もDataFrameメソッドが使える点が重要"
)
```

## まとめ

効果的なAI活用のためのポイント：

1. **明確で構造化されたプロンプト**を作成する
2. **段階的にコンテキスト**を構築する
3. **事実確認**を怠らない
4. **検証可能な形**で回答を求める
5. **機密情報**を適切に保護する
6. **使用量**を監視・管理する
7. **学習プロセス**を記録・振り返る

これらのガイドラインに従うことで、AIを学習の強力なパートナーとして活用できるようになります。