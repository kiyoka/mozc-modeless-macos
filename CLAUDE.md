
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
	
