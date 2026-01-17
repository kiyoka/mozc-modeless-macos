#!/bin/bash

# mozc-modeless-macos アンインストーラー
# このスクリプトはインストールされたファイルを削除します

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}mozc-modeless-macos アンインストーラー${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 確認
echo -e "${YELLOW}以下のファイルとディレクトリを削除します:${NC}"
echo ""
echo "  • ~/.local/bin/mozc-modeless-macos/"
echo "  • ~/.config/karabiner/assets/complex_modifications/modeless-ime.json"
echo ""
echo -e "${RED}この操作は取り消せません。${NC}"
echo -n "本当にアンインストールしますか? (y/N): "
read answer

if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
    echo ""
    echo -e "${BLUE}アンインストールをキャンセルしました${NC}"
    echo ""
    exit 0
fi

echo ""

# 2. Swiftスクリプトとログを削除
INSTALL_DIR="$HOME/.local/bin/mozc-modeless-macos"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}🗑️  Swiftスクリプトとログを削除中...${NC}"
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}✓${NC} $INSTALL_DIR を削除しました"
else
    echo -e "${BLUE}ℹ${NC} $INSTALL_DIR は存在しません（スキップ）"
fi

# 3. Karabiner設定ファイルを削除
KARABINER_CONFIG="$HOME/.config/karabiner/assets/complex_modifications/modeless-ime.json"
if [ -f "$KARABINER_CONFIG" ]; then
    echo -e "${YELLOW}🗑️  Karabiner設定ファイルを削除中...${NC}"
    rm -f "$KARABINER_CONFIG"
    echo -e "${GREEN}✓${NC} $KARABINER_CONFIG を削除しました"
else
    echo -e "${BLUE}ℹ${NC} $KARABINER_CONFIG は存在しません（スキップ）"
fi

# 4. 完了メッセージ
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ アンインストール完了！${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}次のステップ:${NC}"
echo ""
echo "  ${BLUE}1.${NC} Karabiner-Elements を開く"
echo "  ${BLUE}2.${NC} Complex Modifications タブで"
echo "     'ctrl-j: IME ON with Romaji conversion' が"
echo "     リストから消えていることを確認"
echo ""
echo -e "${BLUE}ℹ Karabiner-Elements 本体は削除されていません${NC}"
echo ""
