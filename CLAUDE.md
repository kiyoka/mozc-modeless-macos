
このディレクトリは、macosでKarabiner-Elementsを使って、
どのIMEでもモードレス風にするプロジェクトです。
ctrl-jを押すと英数モードから、IMEオンの状態になり、
IMEオンの状態でエンターキーを押すと、IMEオフに戻るものを作ります。
実現方法を考えてください。

その応答をこのファイルに追記してください。

## 実現方法

### 基本アプローチ: Karabiner-Elements の変数機能を使う

Karabiner-Elements には `set_variable` / `conditions` 機能があり、これで IME の状態を追跡できます。

### 動作フロー

```
[英数モード] --ctrl-j--> [IMEオン + 変数セット]
                              |
                           Enter
                              |
                              v
                         [IMEオフ + 変数クリア]
```

### 実装案

**complex_modifications の JSON 構造:**

1. **ctrl-j の処理**
   - `eisuu` キーコードで英数を解除（または `japanese_kana` を送信）
   - 変数 `ime_active` を `1` にセット

2. **Enter キーの処理**
   - 条件: `ime_active == 1` のときのみ
   - 通常の Enter を送信後、`eisuu` キーを送信して IME オフ
   - 変数 `ime_active` を `0` にクリア

3. **Escape キーの処理（オプション）**
   - 入力キャンセル時も IME オフに戻す

### 課題と対策

| 課題 | 対策 |
|------|------|
| 変換候補選択中の Enter | `to_delayed_action` や複数回 Enter で対応 |
| IME が外部から切り替えられた場合 | 変数と実際の状態がずれる可能性あり |
| 複数の IME 対応 | `japanese_eisuu` / `japanese_kana` は多くの IME で動作 |

---

そのその使い方をこのファイルに追記してください。

## 使い方

### インストール

1. このファイルを Karabiner-Elements の設定フォルダにコピー:
   ```bash
   cp modeless-ime.json ~/.config/karabiner/assets/complex_modifications/
   ```

2. Karabiner-Elements を開く → **Complex Modifications** → **Add rule**

3. 「**Modeless IME (ctrl-j to activate, Enter to deactivate)**」を有効にする

### 動作

- **ctrl-j**: IME をオンにする（日本語入力モード）
- **Enter**: 入力確定後、IME をオフにする（英数モードに戻る）
- **Escape**: 入力をキャンセルし、IME をオフにする


このプロジェクトをGitHubに追加したいと思います。
GitHubのプロジェクト名をいくつか考えてください。

このソフトウェアの動作はモードレスと言えますでしょうか？
UIデザインの観点から答えてください。

その見解をここに追記してください。

## UI デザインの観点からの分析

### 結論: 厳密にはモードレスではない

このソフトウェアは **「準モードレス」** または **「一時的モード (Transient Mode)」** と呼ぶべきです。

### モーダル vs モードレスの定義

| 概念 | 定義 |
|------|------|
| **モーダル** | 同じ操作がモードによって異なる結果を生む |
| **モードレス** | 同じ操作が常に同じ結果を生む |

### このソフトウェアの実態

- `a` キーを押すと:
  - IME オフ時 → `a` が入力される
  - IME オン時 → `あ` の入力プロセスが始まる

**→ モードが存在する = 厳密にはモードレスではない**

### ただし、従来の IME より「モードレス寄り」

| 特徴           | 従来の IME         | このソフトウェア           |
|----------------|--------------------|----------------------------|
| モードの持続性 | 永続的             | 一時的（Enter で自動終了） |
| モード終了操作 | 明示的に切替が必要 | 自然な操作で終了           |
| 認知負荷       | 常にモードを意識   | 入力時のみ意識             |

### UI デザイン用語での正確な分類

- **Quasi-mode（準モード）**: 一時的にモードに入るが、自動的に抜ける
- **Spring-loaded mode**: Shift キーのように押している間だけ有効（これとは異なる）

### より正確な名称案

- `transient-ime` (一時的 IME)
- `auto-dismiss-ime` (自動終了 IME)
- `quasi-modeless-ime` (準モードレス IME)

「モードレス風」という表現は、マーケティング的には許容範囲ですが、学術的には「準モードレス」が正確です。

emacsのmarkdown-modeで環境によって動作に違いがあります。
会社の環境では、表の中のセル部分でエンターキーを押すと、表の枠がきれいな長方形にレイアウト調整されます。
このEmacs環境ではその動作が発動しません。
環境の違いとして何がありますか？

OKです。

githubのリポジトリ名を考えてください。

karabiner-modeless-imeがいい気がします。
ちなみに、karabinerが付いていることにより、macosようということが連想できますか？


承知しました。それでは、その内容で、README.mdを作ってください


このプロジェクトは、google ime だけでなくmacosの標準IMEでも実現できると思いますか？

もし、カーソル位置カーソルからさかのぼってローマ字を取得し、それを初期状態の変換対象ローマ字として
投入したい場合は、Google日本語入力でしかうまく動かない気がします。

## ローマ字自動変換機能について

### なぜ Google 日本語入力でしか動かない可能性が高いか

#### 提案機能の動作イメージ

```
1. 英数モードで: konnichiha█
2. ctrl-j 押下
3. ローマ字削除 + IME起動 + 再投入: ▼こんにちは
```

#### IME ごとの違い

| 機能 | Google 日本語入力 | macOS 標準 IME |
|------|------------------|----------------|
| **自動変換開始** | ✅ 入力と同時に候補表示 | ⚠️ 変換キー待ち |
| **未確定文字の扱い** | ✅ 柔軟 | ❌ 制限的 |
| **再変換機能** | ✅ 強力 | △ 限定的 |
| **API/拡張性** | ✅ 豊富 | ❌ 限定的 |

#### 技術的な問題点

macOS 標準 IME では：

1. **ローマ字を送信しても変換候補が出ない**
   - `konnichiha` を送っただけでは未確定状態にならない
   - スペースキーを押すまで変換が始まらない

2. **未確定文字列の制御が難しい**
   - Karabiner から未確定文字列を作る方法が限定的

3. **再変換の動作が異なる**
   - Google 日本語入力: 自動で候補が出る
   - macOS 標準 IME: 手動操作が必要

#### 解決策（Google 日本語入力限定）

もしこの機能を実装するなら：

```json
{
  "manipulators": [
    {
      "from": {"key_code": "j", "modifiers": {"mandatory": ["control"]}},
      "to": [
        // 1. ローマ字の文字数分 Backspace を送信
        {"key_code": "delete_or_backspace"},
        // ...繰り返し
        // 2. IME オン
        {"key_code": "japanese_kana"},
        // 3. ローマ字を再送信
        {"key_code": "k"},
        {"key_code": "o"},
        // ...
      ]
    }
  ]
}
```

**しかし**: ローマ字の文字数を動的に判定できないため、Karabiner だけでは実装困難

#### 結論

- **Google 日本語入力専用機能**として割り切る必要がある
- または、外部スクリプト（AppleScript、Python など）との組み合わせが必要


さらに追加で質問です。

google imeが無効の状態(英数)の状態で以下のように入力した場合、
nihongo[Ctrl-J]
Karabinerとswiftスクリプトを使って、nihongo部分をgoogle日本語入力に渡した上で、
google日本語入力の有効状態に遷移することはできますか？

その設計メモをここに追記してください。

## ローマ字自動変換機能の設計

### 実現可能性

はい、**技術的には可能**です。Karabiner と Swift スクリプトの組み合わせで実装できます。

### アーキテクチャ

```
[英数モード] nihongo█
      ↓ Ctrl-J
[Karabiner] → shell_command → [Swift/AppleScript]
      ↓
1. カーソル前のテキスト取得 (nihongo)
2. 6文字分 Backspace 送信
3. IME 有効化 (japanese_kana)
4. "nihongo" をキーストロークで再送信
      ↓
[Google IME] ▼にほんご
```

### 実装アプローチ

#### 1. Karabiner 設定

```json
{
  "type": "basic",
  "from": {
    "key_code": "j",
    "modifiers": {"mandatory": ["control"]}
  },
  "to": [
    {
      "shell_command": "/path/to/convert-romaji.swift"
    }
  ]
}
```

#### 2. Swift スクリプトの役割

```swift
// 疑似コード
1. カーソル前のテキストを取得（Accessibility API）
2. 単語境界まで遡ってローマ字を検出
3. CGEvent で Backspace を送信（文字数分）
4. CGEvent で IME オン (japanese_kana)
5. CGEvent でローマ字を1文字ずつ送信
```

### 課題と対策

| 課題 | 対策 |
|------|------|
| **アクセシビリティ権限** | システム設定で許可が必要 |
| **アプリによって動作が異なる** | テキストフィールドの実装に依存 |
| **パスワード欄では動かない** | セキュリティ上の制限 |
| **処理速度** | Swift なら十分高速 |
| **ローマ字の判定** | 正規表現で `[a-z]+` を検出 |

### 具体的な実装技術

#### テキスト取得方法

**Option 1: Accessibility API (推奨)**
```swift
AXUIElementCopyAttributeValue(
  focusedElement,
  kAXValueAttribute,
  &value
)
```

**Option 2: CGEvent でキーストロークを監視**
- より複雑だが、すべてのアプリで動作

#### キーストローク送信

```swift
func sendKeyPress(_ keyCode: CGKeyCode) {
    let source = CGEventSource(stateID: .hidSystemState)
    let keyDown = CGEvent(keyboardEventSource: source,
                          virtualKey: keyCode,
                          keyDown: true)
    let keyUp = CGEvent(keyboardEventSource: source,
                        virtualKey: keyCode,
                        keyDown: false)
    keyDown?.post(tap: .cghidEventTap)
    keyUp?.post(tap: .cghidEventTap)
}
```

### 結論

✅ **実現可能**ですが：
- アクセシビリティ権限が必要
- すべてのアプリで動作する保証はない
- Swift スクリプトの開発が必要

シンプルなプロトタイプなら **100行程度の Swift コード**で実装できます。

間違えました。
このファイルを読んで、Option 1 の実装方法で実装してみてください。
必要であれば、modeless-ime.jsonの中身も書き換えてください。
	
karabinerでctrl+jを何らかのキーに割り当てた場合、emacsというアプリ上のctrl-jの挙動も変わってしまいますか？

今、実装できている、convert-romaji.swiftとmodeless-ime.jsonのインストールの手順をREADME.mdに反映してください。

convert-romaji.swiftロジックが合っているかユニットテストをすることはできますか？


選択肢2: シンプルなテストスクリプトでお願いします。

その結果をこのファイルに追記してください

## ユニットテストの実装と結果

### 実装内容

convert-romaji.swift に `--test` オプションを追加しました。コマンドライン引数で `--test` を渡すとテストモードで実行されます。

```bash
./convert-romaji.swift --test
```

### テストケース

**extractRomajiBeforeCursor のテスト (10件)**
1. 基本的なローマ字抽出 - `"hello world"` のカーソル位置5で `"hello"` を抽出
2. 文末のローマ字抽出 - `"konnichiha"` のカーソル位置10で `"konnichiha"` を抽出
3. スペース後のローマ字抽出 - `"hello world"` のカーソル位置11で `"world"` を抽出
4. ローマ字がない場合 - `"123 "` のカーソル位置4で `nil` を返す
5. カーソル位置0の場合 - `"hello"` のカーソル位置0で `nil` を返す
6. 記号の後のローマ字 - `"foo-bar"` のカーソル位置7で `"bar"` を抽出
7. 日本語の後のローマ字 - `"こんにちはnihongo"` のカーソル位置12で `"nihongo"` を抽出
8. 大文字は無視される - `"HELLO"` のカーソル位置5で `nil` を返す（小文字のみ対応）
9. 小文字のみ抽出 - `"heLLo"` のカーソル位置2で `"he"` を抽出
10. 数字が混ざっている場合 - `"test123abc"` のカーソル位置10で `"abc"` を抽出

**getKeyCode のテスト (5件)**
1. aのキーコード - `0x00` を返す
2. zのキーコード - `0x06` を返す
3. nのキーコード - `0x2D` を返す
4. 存在しない文字 - 数字 `"1"` で `nil` を返す
5. 大文字は対応しない - `"A"` で `nil` を返す

### テスト実行結果

```
=== convert-romaji.swift ユニットテスト ===

--- extractRomajiBeforeCursor のテスト ---
✅ 基本的なローマ字抽出
✅ 文末のローマ字抽出
✅ スペース後のローマ字抽出
✅ ローマ字がない場合
✅ カーソル位置0の場合
✅ 記号の後のローマ字
✅ 日本語の後のローマ字
✅ 大文字は無視される
✅ 小文字のみ抽出
✅ 数字が混ざっている場合

--- getKeyCode のテスト ---
✅ aのキーコード
✅ zのキーコード
✅ nのキーコード
✅ 存在しない文字
✅ 大文字は対応しない

=== テスト結果 ===
成功: 15
失敗: 0
合計: 15

✅ すべてのテストに合格しました！
```

### 結論

全15件のテストケースが合格し、ローマ字抽出ロジックとキーコード変換ロジックが正しく実装されていることを確認しました

modeless-ime.jsonにctrl+jを割り当てemacsのばいあは、そのまま無加工で渡すように設定してください。

karabiner_grabberはどこにインストールされていますか？アクセシビリティーに追加しようとして、パスが分からず困っています。

はい、CLAUDE.mdに追記してください。

## karabiner_grabber の場所とアクセシビリティ設定

### 重要な注意点

最近のバージョンの Karabiner-Elements では、`karabiner_grabber` という名前の実行ファイルは存在しません。代わりに **Karabiner-Elements Privileged Daemons v2.app** がその役割を担っています。

### アクセシビリティに追加すべきパス

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

### 手動でアクセシビリティに追加する方法

1. **システム設定** → **プライバシーとセキュリティ** → **アクセシビリティ**
2. 左下の **🔒** をクリックして管理者パスワードを入力
3. **+** ボタンをクリック
4. **Shift + Command + G** を押してパスを直接入力
5. 上記のパスを1つずつ入力してアプリを追加

### より簡単な方法（推奨）

通常は、Karabiner-Elements を起動すると自動的に権限要求が表示されます：

```bash
open /Applications/Karabiner-Elements.app
```

起動後、システムがアクセシビリティ権限を要求するので、「システム設定を開く」をクリックして許可してください。

### 実行中の Karabiner プロセスの確認

以下のコマンドで、現在実行中の Karabiner プロセスを確認できます：

```bash
ps aux | grep -i karabiner | grep -v grep
```

主なプロセス：
- `Karabiner-Elements Privileged Daemons v2` - キーボード入力の監視と変換
- `Karabiner-Core-Service` - コアサービス
- `Karabiner-Menu` - メニューバーアイコン
- `karabiner_console_user_server` - ユーザーセッション管理

karabiner_console_user_serverをアクセシビリティに足す方法が分かりません。なぜか足そうと思っても空振りします。

### karabiner_console_user_server について

**結論: karabiner_console_user_server はアクセシビリティに追加する必要はありません。**

#### 理由

1. **ファイル形式の違い**
   - `karabiner_console_user_server` は単なる実行可能バイナリファイル（Mach-O executable）
   - macOS のアクセシビリティ設定画面では `.app` バンドルのみを追加可能
   - そのため、バイナリファイルを直接追加しようとしても「空振り」してしまう

2. **権限が不要**
   - `karabiner_console_user_server` はユーザーセッション管理用のプロセス
   - キーボード入力の監視や変換を行わないため、アクセシビリティ権限は不要
   - 必要な権限は以下の2つのみ：
     - `/Applications/Karabiner-Elements.app`
     - `/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Elements Privileged Daemons v2.app`

#### 確認コマンド

```bash
# karabiner_console_user_server の実体を確認
ls -la "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_console_user_server"

# ファイルタイプを確認
file "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_console_user_server"
```

出力例：
```
-rwxr-xr-x  1 root  wheel  5409120 11月 10 12:41 karabiner_console_user_server
Mach-O universal binary with 2 architectures: [x86_64] [arm64]
```

→ `.app` バンドルではなく、単なる実行ファイル

「ctrl-j: IME ON with Romaji conversion (advanced)」** を有効にしましたが、
以下のようにはなりません。
1. カーソル前のテキスト取得 (nihongo)
2. 6文字分 Backspace 送信
3. IME 有効化 (japanese_kana)
4. "nihongo" をキーストロークで再送信
      ↓
  [Google IME] ▼にほんご
のようにはならず、
  nihongo ▼にほんご
のようになります。

## デバッグ方法

この問題をデバッグするために、convert-romaji.swift にデバッグログ機能を追加しました。

### デバッグログの確認手順

1. **テキストエディタで `nihongo` と入力してから ctrl-j を押す**

2. **ログファイルを確認**
   ```bash
   cat ~/convert-romaji-debug.log
   ```

3. **ログの内容を確認**

   正常に動作している場合のログ例：
   ```
   [2026-01-16 ...] === convert-romaji.swift 開始 ===
   [2026-01-16 ...] ✅ Accessibility権限OK
   [2026-01-16 ...] テキスト取得結果: nihongo
   [2026-01-16 ...] カーソル位置: 7
   [2026-01-16 ...] 抽出されたローマ字: Optional("nihongo")
   [2026-01-16 ...] ✅ 検出されたローマ字: nihongo (文字数: 7)
   [2026-01-16 ...] 🔙 Backspaceを7回送信開始
   [2026-01-16 ...]   Backspace 1/7
   [2026-01-16 ...]   Backspace 2/7
   ...
   [2026-01-16 ...] 🈴 IMEをオン
   [2026-01-16 ...] ⌨️  ローマ字を再送信: nihongo
   [2026-01-16 ...] === convert-romaji.swift 終了 ===
   ```

   問題がある場合のログパターン：
   - `テキスト取得結果: nil` → アクセシビリティ権限または対応していないアプリ
   - `カーソル位置: nil` → カーソル位置の取得に失敗
   - `⚠️ テキスト取得失敗` → Accessibility API でテキストが読めない

4. **ログをクリア**
   ```bash
   rm ~/convert-romaji-debug.log
   ```

### よくある問題と対処法

| 問題 | 原因 | 対処法 |
|------|------|--------|
| `テキスト取得結果: nil` | アプリがAccessibility APIに対応していない | そのアプリでは高度版は使えません。シンプル版を使用してください |
| `カーソル位置: nil` | カーソル位置の取得に失敗 | アプリによっては取得できない場合があります |
| Backspace が効いていない | キーイベントがアプリに届いていない | 待機時間を増やすか、別のアプリで試してください |
| スクリプトが実行されない | パスが間違っている | modeless-ime.json のパスを確認してください |

メモ帳でnihongo[ctrl+j]とした結果、ログは以下のようになりました。
[2026-01-16 06:01:35 +0000] === convert-romaji.swift 開始 ===
[2026-01-16 06:01:35 +0000] ✅ Accessibility権限OK
[2026-01-16 06:01:35 +0000] テキスト取得結果: nil
[2026-01-16 06:01:35 +0000] カーソル位置: nil
[2026-01-16 06:01:35 +0000] ⚠️ テキスト取得失敗 -> 通常のIMEオンのみ

texteditでも以下のようになりました。
[2026-01-16 06:12:38 +0000] === convert-romaji.swift 開始 ===
[2026-01-16 06:12:38 +0000] ✅ Accessibility権限OK
[2026-01-16 06:12:38 +0000] テキスト取得結果: nil
[2026-01-16 06:12:38 +0000] カーソル位置: nil
[2026-01-16 06:12:38 +0000] ⚠️ テキスト取得失敗 -> 通常のIMEオンのみ

## クリップボード版への移行

Accessibility APIでのテキスト取得が多くのアプリで動作しないため、クリップボードを使った実装に変更しました。

### 新しいアプローチ（convert-romaji-clipboard.swift）

**動作の流れ:**

1. **Cmd+Shift+Left** でカーソル前の単語を選択
2. 選択範囲を一時的にクリップボードにコピー
3. ローマ字（小文字のa-zのみ）かどうか判定
4. **Delete** で選択範囲を削除
5. **IMEをオン**
6. クリップボードの内容を1文字ずつ送信

**利点:**
- ほとんどのmacOSアプリで動作（メモ帳、TextEdit、VSCode、ブラウザなど）
- Accessibility APIでのテキスト読み取りが不要
- 元のクリップボード内容は自動的に復元される

**制限事項:**
- カーソル前の「単語」を選択するため、スペースや記号の前までしか選択されない
  - 例: `hello world` → `world` のみ選択
  - 例: `foo-bar` → `bar` のみ選択
- 大文字は無視される（小文字のみ対応）

### 設定の更新

`modeless-ime.json` を更新して、`convert-romaji-clipboard.swift` を使用するようにしました。

```json
{
  "shell_command": "/Users/kiyoka/Documents/GitHub/mozc-modeless-macos/convert-romaji-clipboard.swift"
}
```

### Karabiner-Elements の設定を再読み込み

変更を反映させるため、設定を再読み込みしてください：

```bash
# 設定ファイルをコピー（変更後）
cp /Users/kiyoka/Documents/GitHub/mozc-modeless-macos/modeless-ime.json ~/.config/karabiner/assets/complex_modifications/

# Karabiner-Elements を再起動（または設定再読み込み）
```

または、Karabiner-Elements の UI で：
1. **Complex Modifications** タブを開く
2. 既存のルールを一度削除
3. **Add rule** から再度追加

### テスト方法

1. **TextEdit を開く**
   ```bash
   open -a TextEdit
   ```

2. **`nihongo` と入力して ctrl-j を押す**

3. **期待される動作:**
   - `nihongo` が削除される
   - IME がオンになる
   - `▼にほんご` のように変換候補が表示される

4. **デバッグログを確認**
   ```bash
   cat ~/convert-romaji-debug.log
   ```

はい、クリップボードのアプローチに切り替えてください。

## クリップボード版への切り替え完了

以下の作業を実施しました：

1. ✅ `convert-romaji-clipboard.swift` を作成
2. ✅ `modeless-ime.json` を更新してクリップボード版を使用
3. ✅ シンボリックリンクを正しいパスに更新
4. ✅ デバッグログをクリア

### 次のステップ（ユーザー操作）

1. **Karabiner-Elements の設定を再読み込み**
   - Karabiner-Elements アプリを開く
   - **Complex Modifications** タブを開く
   - 既存のルール「ctrl-j: IME ON with Romaji conversion (advanced)」を一度削除
   - **Add rule** ボタンをクリックして再度追加

2. **テスト**
   - TextEdit を開く: `open -a TextEdit`
   - `nihongo` と入力
   - ctrl-j を押す
   - 期待される動作: `nihongo` が削除され、`▼にほんご` のように変換候補が表示される

3. **ログ確認**
   ```bash
   cat ~/convert-romaji-debug.log
   ```

### 期待されるログ（正常動作時）

```
[2026-01-16 ...] === convert-romaji-clipboard.swift 開始 ===
[2026-01-16 ...] ✅ Accessibility権限OK
[2026-01-16 ...] 📋 単語選択開始
[2026-01-16 ...] 元のクリップボード: ...
[2026-01-16 ...] Cmd+Shift+Left で単語選択
[2026-01-16 ...] Cmd+C でコピー
[2026-01-16 ...] コピーされたテキスト: nihongo
[2026-01-16 ...] クリップボードを復元
[2026-01-16 ...] ✅ 検出されたローマ字: nihongo (文字数: 7)
[2026-01-16 ...] 🗑️  選択範囲を削除
[2026-01-16 ...] 🈴 IMEをオン
[2026-01-16 ...] ⌨️  ローマ字を再送信: nihongo
[2026-01-16 ...] === convert-romaji-clipboard.swift 終了 ===
```


open -a TextEditで以下のように正常動作しました。
  - nihongo と入力
  - ctrl-j を押す
  - nihongo が削除されて ▼にほんご と変換候補が表示されるはず
また、ログは以下のようになりました。
[2026-01-16 06:32:07 +0000] === convert-romaji-clipboard.swift 開始 ===
[2026-01-16 06:32:07 +0000] ✅ Accessibility権限OK
[2026-01-16 06:32:07 +0000] 📋 単語選択開始
[2026-01-16 06:32:07 +0000] 元のクリップボード: [2026-01-16 06:12:38 +0000] === convert-romaji.swift 開始 ===
[2026-01-16 06:12:38 +0000] ✅ Accessibility権限OK
[2026-01-16 06:12:38 +0000] テキスト取得結果: nil
[2026-01-16 06:12:38 +0000] カーソル位置: nil
[2026-01-16 06:12:38 +0000] ⚠️ テキスト取得失敗 -> 通常のIMEオンのみ

[2026-01-16 06:32:07 +0000] Cmd+Shift+Left で単語選択
[2026-01-16 06:32:08 +0000] Cmd+C でコピー
[2026-01-16 06:32:08 +0000] コピーされたテキスト: nihongo
[2026-01-16 06:32:08 +0000] クリップボードを復元
[2026-01-16 06:32:08 +0000] ✅ 検出されたローマ字: nihongo (文字数: 7)
[2026-01-16 06:32:08 +0000] 🗑️  選択範囲を削除
[2026-01-16 06:32:08 +0000] 🈴 IMEをオン
[2026-01-16 06:32:09 +0000] ⌨️  ローマ字を再送信: nihongo
[2026-01-16 06:32:09 +0000]   送信: n
[2026-01-16 06:32:09 +0000]   送信: i
[2026-01-16 06:32:09 +0000]   送信: h
[2026-01-16 06:32:09 +0000]   送信: o
[2026-01-16 06:32:09 +0000]   送信: n
[2026-01-16 06:32:09 +0000]   送信: g
[2026-01-16 06:32:09 +0000]   送信: o
[2026-01-16 06:32:09 +0000] === convert-romaji-clipboard.swift 終了 ===

### 動作確認成功 ✅

クリップボード版が TextEdit で正常に動作することを確認しました。

**実行結果:**
- `nihongo` と入力 → ctrl-j 押下 → `nihongo` が削除され `▼にほんご` と変換候補が表示

**ログ分析:**
- 単語選択、クリップボードコピー、ローマ字判定、削除、IME起動、再送信のすべてが正常に動作
- 元のクリップボード内容も正しく復元されている
- 7文字のローマ字（n, i, h, o, n, g, o）が正しく送信されている

### 結論

Accessibility API版（convert-romaji.swift）は多くのアプリでテキスト取得に失敗するため、**クリップボード版（convert-romaji-clipboard.swift）を正式版として採用**します。

**推奨構成:**
- **シンプル版**: すべてのユーザー向け（ctrl-jでIMEオン、Enterで自動オフ）
- **高度版（クリップボード）**: ローマ字自動変換が必要なユーザー向け
