#!/bin/bash

# mozc-modeless-macos インストーラー
# このスクリプトは自動的にセットアップを行います

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# エラー時に終了
set -e

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}mozc-modeless-macos インストーラー${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. ホームディレクトリを取得
HOME_DIR="$HOME"
INSTALL_DIR="$HOME_DIR/.local/bin/mozc-modeless-macos"
echo -e "${YELLOW}ℹ ホームディレクトリ:${NC} $HOME_DIR"
echo -e "${YELLOW}ℹ インストール先:${NC} $INSTALL_DIR"
echo ""

# 2. 必要なファイルが存在するか確認
if [ ! -f "convert-romaji-clipboard.swift" ]; then
    echo -e "${RED}✗ エラー: convert-romaji-clipboard.swift が見つかりません${NC}"
    echo "  このスクリプトはプロジェクトのルートディレクトリで実行してください"
    exit 1
fi

if [ ! -f "modeless-ime.json" ]; then
    echo -e "${RED}✗ エラー: modeless-ime.json が見つかりません${NC}"
    exit 1
fi

# 3. インストールディレクトリを作成
echo -e "${YELLOW}📁 インストールディレクトリを作成中...${NC}"
mkdir -p "$INSTALL_DIR"
echo -e "${GREEN}✓${NC} $INSTALL_DIR"
echo ""

# 4. Swiftスクリプトをコピー
echo -e "${YELLOW}📋 Swiftスクリプトをコピー中...${NC}"
cp convert-romaji-clipboard.swift "$INSTALL_DIR/convert-romaji-clipboard.swift"
chmod +x "$INSTALL_DIR/convert-romaji-clipboard.swift"
echo -e "${GREEN}✓${NC} $INSTALL_DIR/convert-romaji-clipboard.swift"
echo ""

# 5. modeless-ime.json のパスを自動的に書き換える
echo -e "${YELLOW}⚙️  設定ファイルのパスを自動設定中...${NC}"
TEMP_JSON=$(mktemp)

# すべてのパスパターンを検出して置換（より汎用的）
sed "s|\"shell_command\": \".*/convert-romaji-clipboard.swift\"|\"shell_command\": \"$INSTALL_DIR/convert-romaji-clipboard.swift\"|g" modeless-ime.json > "$TEMP_JSON"

echo -e "${GREEN}✓${NC} パスを自動設定: $INSTALL_DIR/convert-romaji-clipboard.swift"
echo ""

# 6. Karabiner設定フォルダにコピー
KARABINER_DIR="$HOME_DIR/.config/karabiner/assets/complex_modifications"

echo -e "${YELLOW}📁 Karabiner設定フォルダを準備中...${NC}"
mkdir -p "$KARABINER_DIR"

echo -e "${YELLOW}📋 Karabiner設定ファイルをコピー中...${NC}"
cp "$TEMP_JSON" "$KARABINER_DIR/modeless-ime.json"
rm "$TEMP_JSON"
echo -e "${GREEN}✓${NC} $KARABINER_DIR/modeless-ime.json"
echo ""

# 6. 完了メッセージ
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ インストール完了！${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}次のステップ:${NC}"
echo ""
echo "  ${BLUE}1.${NC} Karabiner-Elements を開く"
echo "  ${BLUE}2.${NC} Complex Modifications → Add rule をクリック"
echo "  ${BLUE}3.${NC} 'ctrl-j: IME ON with Romaji conversion' を有効にする"
echo ""

echo -e "${YELLOW}アクセシビリティ権限の設定:${NC}"
echo ""
echo "  システム設定 → プライバシーとセキュリティ → アクセシビリティ"
echo ""
echo "  以下のアプリを追加:"
echo "    • /Applications/Karabiner-Elements.app"
echo "    • /Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Elements Privileged Daemons v2.app"
echo ""

echo -e "${YELLOW}デバッグログの確認:${NC}"
echo ""
echo "  cat ~/.local/bin/mozc-modeless-macos/debug.log"
echo ""

echo -e "${BLUE}ℹ 詳しい使い方は README.md をご覧ください${NC}"
echo ""
