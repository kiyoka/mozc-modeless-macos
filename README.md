# mozc-modeless-macos


macOSでKarabiner-Elements を使ってmozc/Google日本語入力をモードレス化するプロジェクトです。

## 概要

ctrl-j を押すことで英数モードから IME をオンにし、変換確定後は自動的に英数モードに戻ります。
これにより、IME のオン/オフ状態を気にせず入力でき、モードの切り替え忘れによる入力ミスを防ぎます。

### 動作フロー

```
[英数モード] --ctrl-j--> [IMEオン + 変数セット]
                              |
                           変換確定
                              |
                              v
                         [IMEオフ + 変数クリア]
```

## インストール

### 前提条件

- macOS
- [Karabiner-Elements](https://karabiner-elements.pqrs.org/) がインストール済み
- Google 日本語入力

## クイックスタート（推奨） 🚀

自動インストールスクリプトを使えば、簡単にセットアップできます。

### 1. リポジトリをクローン

```bash
git clone https://github.com/YOUR_USERNAME/mozc-modeless-macos.git
cd mozc-modeless-macos
```

### 2. インストールスクリプトを実行

```bash
./install.sh
```

インストーラーが自動的に：
- ✅ Swiftスクリプトを `~/.local/bin/mozc-modeless-macos/` にコピー
- ✅ パスを自動設定
- ✅ Karabiner設定ファイルをコピー

### 3. Karabiner-Elements で有効化

1. **Karabiner-Elements** を開く
2. **Complex Modifications** → **Add rule** をクリック
3. **「ctrl-j: IME ON with Romaji conversion」** を有効にする

### 4. アクセシビリティ権限を設定

**システム設定** → **プライバシーとセキュリティ** → **アクセシビリティ**

以下の2つのアプリを追加:
1. `/Applications/Karabiner-Elements.app`
2. `/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Elements Privileged Daemons v2.app`

**注意:** 通常はこの2つで十分です。Karabiner-Core-Service は不要です。

### 5. 動作確認

TextEdit で `nihongo` と入力して **ctrl-j** を押す
- 成功: `▼にほんご` のように変換候補が表示される

---

## 手動インストール（上級者向け）

<details>
<summary>クリックして展開</summary>

### 手順

カーソル前のローマ字を自動的に IME に変換する機能を提供します。**日本語とローマ字が混在していても、末尾のローマ字部分のみを変換できます。**

**動作の仕組み:**
- Cmd+Shift+Left でカーソル前の単語を選択
- クリップボード経由でテキストを取得
- 選択範囲の末尾から sumibi-skip-chars に該当する文字を抽出
- ローマ字部分のみを削除して IME オン
- ローマ字を再送信して変換候補を表示

#### 1. Swiftスクリプトを配置

```bash
# スクリプトに実行権限を付与
chmod +x convert-romaji-clipboard.swift

# スクリプトを適切な場所に配置（例: ホームディレクトリ）
cp convert-romaji-clipboard.swift ~/convert-romaji-clipboard.swift
```

#### 2. modeless-ime.json のパスを編集

`modeless-ime.json` の 18行目を編集して、convert-romaji-clipboard.swift の実際のパスに変更します：

```json
"shell_command": "/Users/YOUR_USERNAME/convert-romaji-clipboard.swift"
```

例えば、ユーザー名が `taro` で、ホームディレクトリに配置した場合：

```json
"shell_command": "/Users/taro/convert-romaji-clipboard.swift"
```

#### 3. 設定ファイルをKarabiner-Elementsにコピー

```bash
cp modeless-ime.json ~/.config/karabiner/assets/complex_modifications/
```

#### 4. Karabiner-Elementsで有効化

1. **Karabiner-Elements** を開く
2. **Complex Modifications** → **Add rule** をクリック
3. **「ctrl-j: IME ON with Romaji conversion」** を有効にする

#### 5. アクセシビリティ権限を付与

キーボードイベントの送信のため、アクセシビリティ権限が必要です。

**重要な注意点:**
最近のバージョンの Karabiner-Elements では、`karabiner_grabber` という名前の実行ファイルは存在しません。代わりに **Karabiner-Elements Privileged Daemons v2.app** がその役割を担っています。

**アクセシビリティに追加すべきアプリ:**

以下の2つのアプリを追加します：

1. **Karabiner-Elements メインアプリ**
   ```
   /Applications/Karabiner-Elements.app
   ```

2. **Karabiner-Elements Privileged Daemons v2** (旧 karabiner_grabber の役割)
   ```
   /Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Elements Privileged Daemons v2.app
   ```

**注意:** 通常はこの2つで十分です。Karabiner-Core-Service は不要です。

**手動でアクセシビリティに追加する方法:**

1. **システム設定** → **プライバシーとセキュリティ** → **アクセシビリティ**
2. 左下の **🔒** をクリックして管理者パスワードを入力
3. **+** ボタンをクリック
4. **Shift + Command + G** を押してパスを直接入力
5. 上記のパスを1つずつ入力してアプリを追加

**より簡単な方法（推奨）:**

通常は、Karabiner-Elements を起動すると自動的に権限要求が表示されます：

```bash
open /Applications/Karabiner-Elements.app
```

起動後、システムがアクセシビリティ権限を要求するので、「システム設定を開く」をクリックして許可してください。

#### 6. 動作確認

```bash
# TextEdit でテスト
open -a TextEdit
```

**テスト1: ローマ字のみ**
1. `nihongo` と入力
2. **ctrl-j** を押す
3. `nihongo` が削除されて `▼にほんご` のように変換候補が表示されれば成功

**テスト2: 日本語とローマ字の混在**
1. `日本語nihongo` と入力
2. **ctrl-j** を押す
3. `nihongo` の部分だけが削除されて `日本語▼にほんご` のように表示されれば成功

**デバッグログの確認:**
```bash
cat ~/.local/bin/mozc-modeless-macos/debug.log
```

期待されるログ:
- `選択されたテキスト: ...` でカーソル前の単語が表示される
- `✅ 検出されたローマ字: ...` で末尾のローマ字が抽出される
- `🔙 Backspace...` でローマ字の文字数分削除される
- `⌨️ ローマ字を再送信: ...` で再入力される

</details>

---

## トラブルシューティング 🔧

### ctrl-j を押しても何も起こらない

**確認事項:**

1. **Karabiner-Elements でルールが有効になっているか**
   - Karabiner-Elements を開く
   - Complex Modifications タブを確認
   - "ctrl-j: IME ON with Romaji conversion" が有効（緑のチェックマーク）になっているか

2. **デバッグログを確認**
   ```bash
   cat ~/.local/bin/mozc-modeless-macos/debug.log
   ```
   - ログが存在しない場合: スクリプトが実行されていない
   - ログが存在する場合: 内容を確認してエラーメッセージを探す

3. **スクリプトが正しい場所にあるか**
   ```bash
   ls -la ~/.local/bin/mozc-modeless-macos/convert-romaji-clipboard.swift
   ```

4. **Karabiner-Elements を再起動**
   ```bash
   killall Karabiner-Elements
   open /Applications/Karabiner-Elements.app
   ```

5. **アクセシビリティ権限が付与されているか**
   - システム設定 → プライバシーとセキュリティ → アクセシビリティ
   - Karabiner-Elements と Karabiner-Elements Privileged Daemons v2 にチェックが入っているか

### 変換候補が表示されない

**原因と対策:**

1. **Google 日本語入力が有効になっていない**
   - システム設定 → キーボード → 入力ソース
   - Google 日本語入力が追加されているか確認

2. **待機時間が短すぎる可能性**
   - 古いMacの場合、待機時間を長くする必要があるかもしれません
   - `convert-romaji-clipboard.swift` の `usleep(5000)` を `usleep(10000)` に変更

### Emacs で ctrl-j が動作しない

これは意図的な動作です。Emacs では ctrl-j が重要なコマンド（`newline-and-indent`）のため、除外設定されています。

**Emacs でも使いたい場合:**
`modeless-ime.json` から以下の部分を削除してください：
```json
"conditions": [
  {
    "type": "frontmost_application_unless",
    "bundle_identifiers": [
      "^org\\.gnu\\.Emacs$",
      "^org\\.gnu\\.AquamacsEmacs$",
      "^org\\.gnu\\.Aquamacs$"
    ]
  }
]
```

---

## アンインストール

インストールしたファイルを削除するには、アンインストールスクリプトを実行してください：

```bash
cd mozc-modeless-macos
./uninstall.sh
```

アンインストーラーは以下を削除します：
- `~/.local/bin/mozc-modeless-macos/`（Swiftスクリプトとログ）
- `~/.config/karabiner/assets/complex_modifications/modeless-ime.json`（Karabiner設定）

**注意:** Karabiner-Elements 本体は削除されません。

---

## 使い方

カーソル前のローマ字を自動的に IME に変換します。**日本語とローマ字が混在していても動作します。**

**ctrl-j** を押すと：

1. カーソル前の単語を選択
2. 末尾のローマ字部分を抽出
3. ローマ字部分を削除
4. IME をオンにして再入力
5. 変換候補が表示される

**動作例1: ローマ字のみ**
```
英数モード: nihongo█
   ↓ ctrl-j
IME モード: ▼にほんご（変換候補表示）
```

**動作例2: 日本語とローマ字の混在**
```
英数モード: 日本語nihongo█
   ↓ ctrl-j
IME モード: 日本語▼にほんご（末尾のローマ字のみ変換）
```

**動作の仕組み:**
- Cmd+Shift+Left でカーソル前の単語を選択
- 選択範囲の末尾から sumibi-skip-chars に該当する文字を抽出
- ローマ字部分のみを削除して IME に再送信
- 自動的にスペースキーを送信して変換候補を表示

**対応文字（sumibi.el 互換）:**
- `a-zA-Z0-9.,@:\`-+![]?;' \t`（大文字・数字・記号・スペース・タブに対応）
- `/` はフェンス文字として機能（`/` で抽出が停止し、`/` も削除される）

**動作例3: パス入力**
```
英数モード: path/to/file.txt█
   ↓ ctrl-j
IME モード: path/to/▼ふぃれてきすと（`/file.txt` が変換対象）
```

**制限事項:**
- macOS のアクセシビリティ権限が必要
- カーソル前の「単語」を選択するため、スペースや記号で区切られた最後の部分のみが対象
- パスワード入力欄などセキュリティ保護されたフィールドでは動作しません
- ほとんどのmacOSアプリで動作（TextEdit、VSCode、ブラウザなど）

## UI デザインの観点から

### 厳密には「準モードレス」

このソフトウェアは厳密には **モードレス** ではなく、**準モードレス (Quasi-modeless)** または **一時的モード (Transient Mode)** です。

| 特徴           | 従来の IME         | このソフトウェア           |
|----------------|--------------------|----------------------------|
| モードの持続性 | 永続的             | 一時的（Enter で自動終了） |
| モード終了操作 | 明示的に切替が必要 | 自然な操作で終了           |
| 認知負荷       | 常にモードを意識   | 入力時のみ意識             |

### UI デザイン用語での分類

- **Quasi-mode（準モード）**: 一時的にモードに入るが、自動的に抜ける
- **Transient Mode（一時的モード）**: 限定された時間だけ存在するモード

従来の IME のように常にモードを意識する必要がなく、入力時のみ意識すれば良いため、認知負荷が低減されます。

## 技術仕様

- Karabiner-Elements の `set_variable` と `conditions` 機能を使用
- 変数 `ime_active` で IME の状態を追跡
- `japanese_kana` でIME オン、`japanese_eisuu` で IME オフ

## ライセンス

MIT

## 貢献

Issue や Pull Request を歓迎します。

## 参考

- [Karabiner-Elements 公式サイト](https://karabiner-elements.pqrs.org/)

