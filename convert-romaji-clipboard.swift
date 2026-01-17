#!/usr/bin/env swift

import Cocoa
import ApplicationServices

// キーコード定義
let kVK_Delete: CGKeyCode = 0x33
let kVK_JIS_Kana: CGKeyCode = 0x68
let kVK_ANSI_C: CGKeyCode = 0x08
let kVK_LeftArrow: CGKeyCode = 0x7B
let kVK_Space: CGKeyCode = 0x31

// デバッグログを書き込む関数
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

// キーストロークを送信する関数
func sendKeyPress(_ keyCode: CGKeyCode, withModifiers modifiers: CGEventFlags = []) {
    let source = CGEventSource(stateID: .hidSystemState)
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)

    keyDown?.flags = modifiers
    keyUp?.flags = modifiers

    keyDown?.post(tap: .cghidEventTap)
    usleep(5000) // 5ms待機（互換性重視の最適化）
    keyUp?.post(tap: .cghidEventTap)
    usleep(5000)
}

// 文字からキーコードへの変換マップ
func getKeyCode(for char: Character) -> CGKeyCode? {
    let mapping: [Character: CGKeyCode] = [
        "a": 0x00, "b": 0x0B, "c": 0x08, "d": 0x02, "e": 0x0E,
        "f": 0x03, "g": 0x05, "h": 0x04, "i": 0x22, "j": 0x26,
        "k": 0x28, "l": 0x25, "m": 0x2E, "n": 0x2D, "o": 0x1F,
        "p": 0x23, "q": 0x0C, "r": 0x0F, "s": 0x01, "t": 0x11,
        "u": 0x20, "v": 0x09, "w": 0x0D, "x": 0x07, "y": 0x10,
        "z": 0x06
    ]
    return mapping[char]
}

// クリップボードから文字列を取得
func getClipboardString() -> String? {
    let pasteboard = NSPasteboard.general
    return pasteboard.string(forType: .string)
}

// クリップボードに文字列を設定
func setClipboardString(_ string: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(string, forType: .string)
}

// 単語を選択してクリップボードにコピー
func selectAndCopyWord() -> String? {
    writeDebugLog("📋 単語選択開始")

    // 元のクリップボード内容を保存
    let originalClipboard = getClipboardString()
    writeDebugLog("元のクリップボード: \(originalClipboard ?? "nil")")

    // クリップボードをクリア（空文字列を設定）
    setClipboardString("")
    usleep(50000) // 50ms待機

    // Cmd+Shift+Left で単語を選択
    writeDebugLog("Cmd+Shift+Left で単語選択")
    sendKeyPress(kVK_LeftArrow, withModifiers: [.maskCommand, .maskShift])
    usleep(100000) // 100ms待機

    // Cmd+C でコピー
    writeDebugLog("Cmd+C でコピー")
    sendKeyPress(kVK_ANSI_C, withModifiers: .maskCommand)
    usleep(100000) // 100ms待機

    // クリップボードから取得
    let selectedText = getClipboardString()
    writeDebugLog("コピーされたテキスト: \(selectedText ?? "nil")")

    // 元のクリップボードを復元
    if let original = originalClipboard {
        setClipboardString(original)
        writeDebugLog("クリップボードを復元")
    }

    return selectedText
}

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

// メイン処理
func main() {
    writeDebugLog("=== convert-romaji-clipboard.swift 開始 ===")

    // Accessibility権限チェック
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

    if !trusted {
        writeDebugLog("❌ Accessibility権限がありません")
        print("Accessibility権限が必要です")
        exit(1)
    }
    writeDebugLog("✅ Accessibility権限OK")

    // 単語を選択してコピー
    guard let selectedText = selectAndCopyWord() else {
        writeDebugLog("⚠️ テキスト選択失敗 -> 通常のIMEオンのみ")
        sendKeyPress(kVK_JIS_Kana)
        exit(0)
    }

    writeDebugLog("選択されたテキスト: \(selectedText)")

    // 選択されたテキストの末尾からローマ字を抽出
    guard let result = extractRomajiFromEnd(selectedText) else {
        writeDebugLog("⚠️ 末尾にローマ字なし: \(selectedText) -> 通常のIMEオンのみ")
        // 選択を解除（右矢印）
        sendKeyPress(0x7C) // Right arrow
        sendKeyPress(kVK_JIS_Kana)
        exit(0)
    }

    let romaji = result.romaji
    let deleteCount = result.deleteCount

    writeDebugLog("✅ 検出されたローマ字: \(romaji) (文字数: \(romaji.count), 削除文字数: \(deleteCount))")

    // 選択を解除（右矢印でカーソル位置を選択範囲の最後に移動）
    writeDebugLog("➡️  選択を解除")
    sendKeyPress(0x7C) // Right arrow
    usleep(50000) // 50ms待機

    // deleteCount の文字数分 Backspace を送信（/ も含む）
    writeDebugLog("🔙 Backspaceを\(deleteCount)回送信")
    for i in 0..<deleteCount {
        sendKeyPress(kVK_Delete)
        writeDebugLog("  Backspace \(i+1)/\(deleteCount)")
        usleep(10000) // 10ms待機
    }
    usleep(50000) // 50ms待機

    // IMEをオン
    writeDebugLog("🈴 IMEをオン")
    sendKeyPress(kVK_JIS_Kana)
    usleep(150000) // 150ms待機（IME起動を待つ）

    // ローマ字を1文字ずつ送信
    writeDebugLog("⌨️  ローマ字を再送信: \(romaji)")
    for char in romaji.lowercased() {
        if let keyCode = getKeyCode(for: char) {
            sendKeyPress(keyCode)
            writeDebugLog("  送信: \(char)")
        }
    }

    // スペースキーを送信して変換
    writeDebugLog("␣ スペースキーを送信して変換")
    usleep(50000) // 50ms待機（ローマ字入力完了を待つ）
    sendKeyPress(kVK_Space)
    writeDebugLog("  変換確定")

    writeDebugLog("=== convert-romaji-clipboard.swift 終了 ===\n")
}

main()
