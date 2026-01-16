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
- Google 日本語入力（高度版を使う場合）

### 手順

#### 1. リポジトリをクローン

```bash
git clone https://github.com/YOUR_USERNAME/mozc-modeless-macos.git
cd mozc-modeless-macos
```

#### 2. シンプル版のみを使う場合

シンプル版は Swift スクリプトを使わず、Karabiner のみで動作します。

```bash
# 設定ファイルをコピー
cp modeless-ime.json ~/.config/karabiner/assets/complex_modifications/
```

その後、Karabiner-Elements を開いて設定します：

1. **Complex Modifications** → **Add rule** をクリック
2. **「ctrl-j: IME ON, Enter: IME OFF (modeless style - simple)」** を有効にする

これで完了です。

#### 3. 高度版（ローマ字自動変換）を使う場合

高度版は、カーソル前のローマ字を自動的に IME に変換する機能を提供します。**日本語とローマ字が混在していても、末尾のローマ字部分のみを変換できます。**

**動作の仕組み:**
- Cmd+Shift+Left でカーソル前の単語を選択
- クリップボード経由でテキストを取得
- 選択範囲の末尾から連続するローマ字（a-z）を抽出
- ローマ字部分のみを削除して IME オン
- ローマ字を再送信して変換候補を表示

##### 3-1. Swiftスクリプトを配置

```bash
# スクリプトに実行権限を付与
chmod +x convert-romaji-clipboard.swift

# スクリプトを適切な場所に配置（例: ホームディレクトリ）
cp convert-romaji-clipboard.swift ~/convert-romaji-clipboard.swift
```

##### 3-2. modeless-ime.json のパスを編集

`modeless-ime.json` の 18行目を編集して、convert-romaji-clipboard.swift の実際のパスに変更します：

```json
"shell_command": "/Users/YOUR_USERNAME/convert-romaji-clipboard.swift"
```

例えば、ユーザー名が `taro` で、ホームディレクトリに配置した場合：

```json
"shell_command": "/Users/taro/convert-romaji-clipboard.swift"
```

##### 3-3. 設定ファイルをKarabiner-Elementsにコピー

```bash
cp modeless-ime.json ~/.config/karabiner/assets/complex_modifications/
```

##### 3-4. Karabiner-Elementsで有効化

1. **Karabiner-Elements** を開く
2. **Complex Modifications** → **Add rule** をクリック
3. **「ctrl-j: IME ON with Romaji conversion (advanced)」** を有効にする

##### 3-5. アクセシビリティ権限を付与

高度版はキーボードイベントの送信のため、アクセシビリティ権限が必要です。

**重要な注意点:**
最近のバージョンの Karabiner-Elements では、`karabiner_grabber` という名前の実行ファイルは存在しません。代わりに **Karabiner-Elements Privileged Daemons v2.app** がその役割を担っています。

**アクセシビリティに追加すべきアプリ:**

1. **Karabiner-Elements メインアプリ**
   ```
   /Applications/Karabiner-Elements.app
   ```

2. **Karabiner-Elements Privileged Daemons v2** (旧 karabiner_grabber の役割)
   ```
   /Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Elements Privileged Daemons v2.app
   ```

3. **Karabiner-Core-Service** (必要に応じて)
   ```
   /Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Core-Service.app
   ```

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

##### 3-6. 動作確認

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
cat ~/convert-romaji-debug.log
```

期待されるログ:
- `選択されたテキスト: ...` でカーソル前の単語が表示される
- `✅ 検出されたローマ字: ...` で末尾のローマ字が抽出される
- `🔙 Backspace...` でローマ字の文字数分削除される
- `⌨️ ローマ字を再送信: ...` で再入力される

## 使い方

このプロジェクトでは、2つのモードを提供しています：

### シンプル版（Simple）

- **ctrl-j**: IME をオンにする（日本語入力モード）
- **Enter**: 入力確定後、IME をオフにする（英数モードに戻る）
- **Escape**: 入力をキャンセルし、IME をオフにする

### 高度版（Advanced - ローマ字自動変換）

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
- 選択範囲の末尾から連続するローマ字（a-z）を抽出
- ローマ字部分のみを削除して IME に再送信

**制限事項:**
- macOS のアクセシビリティ権限が必要
- 小文字のローマ字（a-z）のみ対応（大文字は無視される）
- カーソル前の「単語」を選択するため、スペースや記号で区切られた最後の部分のみが対象
  - 例: `hello world` → `world` のみ対象
  - 例: `foo-bar` → `bar` のみ対象
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

