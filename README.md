# mozc-modeless-macos


macOSでKarabiner-Elements を使ってmozc/Google日本語入力をモードレス化するプロジェクトです。

## 概要

ctrl-j を押すと英数モードから IME オンの状態になり、IMEで変換結果を確定すると、自動的に IME オフに戻ります。
それにより、英数したいときにIMEモード オンになっていて入力誤りをするというモードエラーをなくします。

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

高度版は、英数モードで入力したローマ字を自動的に IME に渡す機能を提供します。

##### 3-1. Swiftスクリプトを配置

```bash
# スクリプトに実行権限を付与
chmod +x convert-romaji.swift

# スクリプトを適切な場所に配置（例: ホームディレクトリ）
cp convert-romaji.swift ~/convert-romaji.swift
```

##### 3-2. modeless-ime.json のパスを編集

`modeless-ime.json` の 18行目を編集して、convert-romaji.swift の実際のパスに変更します：

```json
"shell_command": "/Users/YOUR_USERNAME/convert-romaji.swift"
```

例えば、ユーザー名が `taro` で、ホームディレクトリに配置した場合：

```json
"shell_command": "/Users/taro/convert-romaji.swift"
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

高度版はテキストフィールドの内容を読み取るため、アクセシビリティ権限が必要です。

1. **システム設定** → **プライバシーとセキュリティ** → **アクセシビリティ**
2. 以下のアプリにチェックを入れる：
   - **Karabiner-Elements**
   - **karabiner_grabber**
3. 初回実行時にプロンプトが表示された場合は、許可してください

## 使い方

このプロジェクトでは、2つのモードを提供しています：

### シンプル版（Simple）

- **ctrl-j**: IME をオンにする（日本語入力モード）
- **Enter**: 入力確定後、IME をオフにする（英数モードに戻る）
- **Escape**: 入力をキャンセルし、IME をオフにする

### 高度版（Advanced - ローマ字自動変換）

英数モードで `nihongo` と入力した後に **ctrl-j** を押すと：

1. `nihongo` が削除される
2. IME がオンになる
3. `nihongo` が IME に自動投入され、変換候補が表示される

**動作例:**
```
英数モード: nihongo█
   ↓ ctrl-j
IME モード: ▼にほんご（変換候補表示）
```

**制限事項:**
- macOS のアクセシビリティ権限が必要
- すべてのアプリで動作するとは限りません
- パスワード入力欄などでは動作しません

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

