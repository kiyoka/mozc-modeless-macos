# mozc-modeless-macos - 設計ドキュメント

## プロジェクト概要

macOS で Karabiner-Elements を使用し、Google 日本語入力（Mozc）やその他の IME をモードレス風に動作させるプロジェクト。

**コアコンセプト:**
- ctrl-j で IME をオンにし、Enter で自動的にオフに戻る
- 高度版では、カーソル前のローマ字を自動的に IME に変換

## 実装アプローチの選択

### 試行したアプローチ

#### アプローチ1: Accessibility API を使ったテキスト取得（不採用）

**実装:** `convert-romaji.swift`（削除済み）

```swift
AXUIElementCopyAttributeValue(
  focusedElement,
  kAXValueAttribute,
  &value
)
```

**問題点:**
- TextEdit、メモ帳などの標準アプリでテキスト取得に失敗（`nil` を返す）
- macOS のセキュリティ制限により、多くのアプリでアクセスできない
- カーソル位置の取得も不安定

**結論:** ほとんどのアプリで動作しないため不採用

#### アプローチ2: クリップボード経由のテキスト取得（採用）

**実装:** `convert-romaji-clipboard.swift`

**動作フロー:**
1. Cmd+Shift+Left でカーソル前の単語を選択
2. 選択範囲をクリップボードにコピー
3. 末尾からローマ字部分を抽出
4. 選択を解除（右矢印）
5. ローマ字の文字数分 Backspace で削除
6. IME をオン
7. ローマ字を1文字ずつ送信

**利点:**
- ✅ ほとんどの macOS アプリで動作（TextEdit、VSCode、ブラウザなど）
- ✅ Accessibility API でのテキスト読み取りが不要
- ✅ 元のクリップボード内容を自動的に復元

**制限事項:**
- カーソル前の「単語」を選択するため、スペースや記号で区切られる
- 小文字のローマ字（a-z）のみ対応

## 技術的な課題と解決策

### 課題1: 日本語とローマ字の混在

**問題:**
「日本語nihongo」のようなテキストで、Cmd+Shift+Left が全体を選択してしまう。

**解決策:**
選択されたテキストから末尾のローマ字部分のみを抽出する関数を実装。
（注: この実装は後に課題5で sumibi.el 互換性のため拡張されました）

**初期実装（シンプル版）:**
```swift
// 小文字のローマ字（a-z）のみを抽出
func extractRomajiFromEnd(_ text: String) -> String? {
    var romaji = ""

    // 末尾から1文字ずつ見ていく
    for char in text.reversed() {
        if char.isLowercase && char.isASCII && char >= "a" && char <= "z" {
            romaji.insert(char, at: romaji.startIndex)
        } else {
            break
        }
    }

    return romaji.isEmpty ? nil : romaji
}
```

**動作例:**
- 入力: 「日本語nihongo」
- 選択: 「日本語nihongo」全体
- 抽出: 「nihongo」
- 削除: 7文字分 Backspace
- 結果: 「日本語▼にほんご」

**現在の実装:**
課題5で sumibi.el との互換性のため拡張。詳細は「課題5: sumibi.el との互換性」を参照。

### 課題2: Emacs での ctrl-j の挙動

**問題:**
Karabiner で ctrl-j を割り当てると、Emacs でも影響を受ける。

**解決策:**
Emacs アプリを除外する条件を追加。

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

### 課題3: クリップボード内容の保護

**問題:**
スクリプトがクリップボードを使用するため、元の内容が失われる。

**解決策:**
元のクリップボード内容を保存し、処理後に復元。

```swift
// 元のクリップボード内容を保存
let originalClipboard = getClipboardString()

// 処理...

// 元のクリップボードを復元
if let original = originalClipboard {
    setClipboardString(original)
}
```

### 課題4: アクセシビリティ権限の混乱

**問題:**
`karabiner_grabber` という名前のファイルが見つからず、ユーザーが混乱。

**解決策:**
README.md に詳細な説明を追加：
- 最近のバージョンでは `karabiner_grabber` は存在しない
- 代わりに `Karabiner-Elements Privileged Daemons v2.app` を使用
- 正確なパスと手動追加方法を記載

### 課題5: sumibi.el との互換性

**問題:**
Emacs の sumibi.el と同じ挙動を実現したい。具体的には：
1. `/` をフェンス文字として使用（区切りとして機能し、削除対象にも含まれる）
2. sumibi-skip-chars と同じ文字セット（`a-zA-Z0-9.,@:\`-+![]?;' \t`）を対象とする

**解決策:**
`extractRomajiFromEnd()` 関数を拡張し、タプル `(romaji: String, deleteCount: Int)?` を返すように変更。

```swift
// テキストの末尾から sumibi-skip-chars に該当する文字を抽出
// sumibi-skip-chars: a-zA-Z0-9.,@:`\-+![]?;' \t
// / が出現したら、そこで停止（/もフェンスとして削除対象）
// 戻り値: (抽出された文字列, 削除すべき文字数)
func extractRomajiFromEnd(_ text: String) -> (romaji: String, deleteCount: Int)? {
    var romaji = ""
    var foundSlash = false

    // sumibi-skip-chars に含まれる文字のセット
    let sumibiChars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,@:`-+![]?;' \t")

    // 末尾から1文字ずつ見ていく
    for char in text.reversed() {
        // / が出現したら停止（フェンスとして機能）
        if char == "/" {
            foundSlash = true
            break
        }

        // sumibi-skip-chars に含まれる文字なら追加
        if let scalar = char.unicodeScalars.first, sumibiChars.contains(scalar) {
            romaji.insert(char, at: romaji.startIndex)
        } else {
            // sumibi-skip-chars に含まれない文字が出現したら停止
            break
        }
    }

    if romaji.isEmpty {
        return nil
    }

    // 削除文字数: ローマ字の文字数 + (/ が見つかった場合は +1)
    let deleteCount = foundSlash ? romaji.count + 1 : romaji.count

    return (romaji: romaji, deleteCount: deleteCount)
}
```

**動作例:**
- 入力: `path/to/file.txt█`
- 選択: `path/to/file.txt`
- 抽出: `file.txt` (romaji)
- 削除: 9文字（`/file.txt`）
- 結果: `path/to/▼ふぃぇ.txt`

**ポイント:**
- `/` が検出された場合は `foundSlash` フラグを立てる
- 削除文字数 (`deleteCount`) には `/` も含まれる
- Backspace 送信時は `deleteCount` を使用
- IME には抽出された `romaji` のみを送信

### 課題6: 削除処理の速度改善

**問題:**
Ctrl-j を押したときに、ローマ字をBackspaceで1文字ずつ削除すると時間がかかる。
- 10文字削除: 約200ms
- 20文字削除: 約400ms

**解決策1: Backspace → 選択方式への変更**

Backspaceで削除するのではなく、Shift+Left で選択してからIME入力で上書きする方式に変更。

**変更前（Backspace方式）:**
```swift
// deleteCount の文字数分 Backspace を送信
for i in 0..<deleteCount {
    sendKeyPress(kVK_Delete)
    usleep(10000) // 10ms待機
}
```

**変更後（選択方式）:**
```swift
// deleteCount の文字数分を Shift+Left で選択
for _ in 0..<deleteCount {
    sendKeyPress(kVK_LeftArrow, withModifiers: .maskShift)
}
// IME入力時に選択範囲が自動的に上書きされる
```

**解決策2: 高速選択関数の実装**

Shift+Left の待機時間を短縮した専用関数を実装。

```swift
// 高速選択用の関数（確実性重視で待機時間短縮）
func selectLeftFast(_ count: Int) {
    let source = CGEventSource(stateID: .hidSystemState)

    for _ in 0..<count {
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: kVK_LeftArrow, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: kVK_LeftArrow, keyDown: false)

        keyDown?.flags = .maskShift
        keyUp?.flags = .maskShift

        keyDown?.post(tap: .cghidEventTap)
        usleep(2000) // 2ms待機（従来の5msから短縮）
        keyUp?.post(tap: .cghidEventTap)
        usleep(1000) // 1ms待機（従来の5msから短縮）
    }
}
```

**パフォーマンス改善:**

| 文字数 | Backspace方式 | 選択方式（通常） | 選択方式（高速） |
|--------|--------------|----------------|----------------|
| 10文字 | 200ms        | 100ms          | **30ms**       |
| 20文字 | 400ms        | 200ms          | **60ms**       |

**改善のポイント:**
- 1文字あたりの処理時間: 20ms → 10ms → **3ms**
- 視覚的にもスムーズ（削除→入力ではなく、選択→上書き）
- 確実性を維持（キーリピート方式ではなく、keyDown/keyUpを確実に送信）

## アーキテクチャ

### システム構成

```
┌─────────────────────────────────────┐
│  Karabiner-Elements                 │
│  (modeless-ime.json)                │
│                                     │
│  ctrl-j イベント検出                │
└──────────────┬──────────────────────┘
               │
               │ shell_command
               ▼
┌─────────────────────────────────────┐
│  convert-romaji-clipboard.swift     │
│                                     │
│  1. Cmd+Shift+Left で単語選択       │
│  2. クリップボードにコピー          │
│  3. 末尾からローマ字抽出            │
│  4. 選択解除 (右矢印)               │
│  5. Backspace で削除                │
│  6. IME オン                        │
│  7. ローマ字を再送信                │
└─────────────────────────────────────┘
```

### ファイル構成

```
mozc-modeless-macos/
├── convert-romaji-clipboard.swift  # メインスクリプト
├── modeless-ime.json               # Karabiner 設定
├── README.md                       # ユーザー向けドキュメント
└── DESIGN.md                       # 技術ドキュメント（本ファイル）
```

## 重要な実装の詳細

### キーストローク送信

```swift
func sendKeyPress(_ keyCode: CGKeyCode, withModifiers modifiers: CGEventFlags = []) {
    let source = CGEventSource(stateID: .hidSystemState)
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)

    keyDown?.flags = modifiers
    keyUp?.flags = modifiers

    keyDown?.post(tap: .cghidEventTap)
    usleep(10000) // 10ms待機
    keyUp?.post(tap: .cghidEventTap)
    usleep(10000)
}
```

**ポイント:**
- `CGEventSource` と `CGEvent` を使用
- keyDown と keyUp の両方を送信
- 10ms の待機時間を入れて安定性を確保

### IME の制御

```swift
let kVK_JIS_Kana: CGKeyCode = 0x68  // IME オン (かな)
let kVK_Delete: CGKeyCode = 0x33     // Backspace
let kVK_RightArrow: CGKeyCode = 0x7C // 右矢印

// IME をオン
sendKeyPress(kVK_JIS_Kana)
usleep(150000) // 150ms待機（IME起動を待つ）
```

**ポイント:**
- `japanese_kana` (0x68) で IME をオン
- IME 起動には時間がかかるため、150ms の待機時間が必要

### 単語選択とクリップボード操作

```swift
// Cmd+Shift+Left で単語を選択
sendKeyPress(kVK_LeftArrow, withModifiers: [.maskCommand, .maskShift])
usleep(100000) // 100ms待機

// Cmd+C でコピー
sendKeyPress(kVK_ANSI_C, withModifiers: .maskCommand)
usleep(100000) // 100ms待機

// クリップボードから取得
let selectedText = getClipboardString()
```

**ポイント:**
- 各操作の間に適切な待機時間を入れる
- Cmd+Shift+Left は単語境界で選択を停止する

## デバッグ機能

### デバッグログ

```swift
func writeDebugLog(_ message: String) {
    let logPath = NSHomeDirectory() + "/convert-romaji-debug.log"
    let timestamp = Date()
    let logMessage = "[\(timestamp)] \(message)\n"

    if let data = logMessage.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logPath) {
            if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: URL(fileURLWithPath: logPath))
        }
    }
}
```

**ログの確認:**
```bash
cat ~/convert-romaji-debug.log
```

**主なログ項目:**
- 選択されたテキスト
- 検出されたローマ字
- Backspace の送信回数
- IME の起動
- ローマ字の再送信（1文字ずつ）

## テスト

### ユニットテスト（削除済み）

convert-romaji.swift（Accessibility API版）には `--test` オプションを実装していたが、この実装は削除されました。

### 手動テスト

**テストケース1: ローマ字のみ**
```
入力: nihongo
操作: ctrl-j
期待: ▼にほんご
```

**テストケース2: 日本語混在**
```
入力: 日本語nihongo
操作: ctrl-j
期待: 日本語▼にほんご
```

**テストケース3: スペース区切り**
```
入力: hello world
操作: ctrl-j（worldの後）
期待: hello ▼をrld（worldのみ変換）
```

## 制限事項

1. **単語境界の制限**
   - Cmd+Shift+Left の動作に依存
   - スペースや記号で区切られた最後の部分のみが対象

2. **小文字のみ対応**
   - 大文字のローマ字は無視される
   - 例: "HELLO" → 変換されない

3. **アプリの互換性**
   - パスワード入力欄では動作しない（セキュリティ上の制限）
   - 一部の特殊なテキストフィールドでは動作しない可能性

4. **処理速度**
   - クリップボード操作とキーストローク送信のため、若干の遅延がある
   - 通常は1秒以内で完了

## UI デザインの観点

### モードレス vs 準モードレス

このソフトウェアは厳密には **「準モードレス (Quasi-modeless)」** または **「一時的モード (Transient Mode)」** です。

**理由:**
- 同じ操作（例: `a` キーを押す）がモードによって異なる結果を生む
- ただし、モードは一時的で、Enter を押すと自動的に終了する

**従来の IME との違い:**

| 特徴           | 従来の IME         | このソフトウェア           |
|----------------|--------------------|----------------------------|
| モードの持続性 | 永続的             | 一時的（Enter で自動終了） |
| モード終了操作 | 明示的に切替が必要 | 自然な操作で終了           |
| 認知負荷       | 常にモードを意識   | 入力時のみ意識             |

## 今後の改善案

1. **大文字対応**
   - 現在は小文字のみだが、大文字も変換できるようにする

2. **複数単語の対応**
   - 現在はスペース区切りの最後の単語のみだが、複数単語を選択できるようにする

3. **カスタマイズ可能なキーバインド**
   - ctrl-j 以外のキーを選択できるようにする

4. **他の IME のサポート**
   - macOS 標準 IME での動作確認と最適化

5. **パフォーマンス改善**
   - 待機時間の最適化
   - より高速なクリップボード操作

## 参考資料

- [Karabiner-Elements 公式サイト](https://karabiner-elements.pqrs.org/)
- [CGEvent Class Reference](https://developer.apple.com/documentation/coregraphics/cgevent)
- [Accessibility Programming Guide](https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/)

## 開発履歴

- **v0.0.1**: シンプル版（ctrl-j で IME オン、Enter で自動オフ）
- **v0.0.2**: 高度版（ローマ字自動変換）- Accessibility API 版
- **v0.0.3**: 高度版をクリップボード版に変更（互換性向上）
- **v0.0.4**: 日本語混在対応（末尾からローマ字抽出）
- **v0.0.5**: Emacs 除外機能追加
- **v0.0.6**: sumibi.el 互換性対応（`/` フェンス機能、sumibi-skip-chars 対応）

## ライセンス

MIT License
