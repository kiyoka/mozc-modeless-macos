#!/usr/bin/env swift

import Cocoa
import ApplicationServices

// キーコード定義
let kVK_Delete: CGKeyCode = 0x33
let kVK_JIS_Kana: CGKeyCode = 0x68

// キーストロークを送信する関数
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

// フォーカスされた要素のテキストを取得
func getFocusedElementText() -> String? {
    let systemWideElement = AXUIElementCreateSystemWide()
    var focusedElement: CFTypeRef?

    let result = AXUIElementCopyAttributeValue(
        systemWideElement,
        kAXFocusedUIElementAttribute as CFString,
        &focusedElement
    )

    guard result == .success, let element = focusedElement else {
        return nil
    }

    var value: CFTypeRef?
    let valueResult = AXUIElementCopyAttributeValue(
        element as! AXUIElement,
        kAXValueAttribute as CFString,
        &value
    )

    guard valueResult == .success, let text = value as? String else {
        return nil
    }

    return text
}

// カーソル位置を取得
func getCursorPosition() -> Int? {
    let systemWideElement = AXUIElementCreateSystemWide()
    var focusedElement: CFTypeRef?

    let result = AXUIElementCopyAttributeValue(
        systemWideElement,
        kAXFocusedUIElementAttribute as CFString,
        &focusedElement
    )

    guard result == .success, let element = focusedElement else {
        return nil
    }

    var selectedRange: CFTypeRef?
    let rangeResult = AXUIElementCopyAttributeValue(
        element as! AXUIElement,
        kAXSelectedTextRangeAttribute as CFString,
        &selectedRange
    )

    if rangeResult == .success,
       let range = selectedRange,
       CFGetTypeID(range) == AXValueGetTypeID() {
        var cfRange = CFRange()
        if AXValueGetValue(range as! AXValue, .cfRange, &cfRange) {
            return cfRange.location
        }
    }

    return nil
}

// カーソル前のローマ字を検出
func extractRomajiBeforeCursor(text: String, cursorPosition: Int) -> String? {
    guard cursorPosition > 0 && cursorPosition <= text.count else {
        return nil
    }

    let beforeCursor = String(text.prefix(cursorPosition))

    // 末尾から連続するローマ字（a-z）を取得
    var romaji = ""
    for char in beforeCursor.reversed() {
        if char.isLowercase && char.isASCII {
            romaji.insert(char, at: romaji.startIndex)
        } else {
            break
        }
    }

    return romaji.isEmpty ? nil : romaji
}

// テスト実行
func runTests() {
    print("=== convert-romaji.swift ユニットテスト ===\n")

    var passCount = 0
    var failCount = 0

    func test(_ name: String, _ condition: Bool, expected: String = "", actual: String = "") {
        if condition {
            print("✅ \(name)")
            passCount += 1
        } else {
            print("❌ \(name)")
            if !expected.isEmpty {
                print("   期待値: \(expected)")
                print("   実際値: \(actual)")
            }
            failCount += 1
        }
    }

    // extractRomajiBeforeCursor のテスト
    print("--- extractRomajiBeforeCursor のテスト ---")

    test("基本的なローマ字抽出",
         extractRomajiBeforeCursor(text: "hello world", cursorPosition: 5) == "hello",
         expected: "hello",
         actual: extractRomajiBeforeCursor(text: "hello world", cursorPosition: 5) ?? "nil")

    test("文末のローマ字抽出",
         extractRomajiBeforeCursor(text: "konnichiha", cursorPosition: 10) == "konnichiha",
         expected: "konnichiha",
         actual: extractRomajiBeforeCursor(text: "konnichiha", cursorPosition: 10) ?? "nil")

    test("スペース後のローマ字抽出",
         extractRomajiBeforeCursor(text: "hello world", cursorPosition: 11) == "world",
         expected: "world",
         actual: extractRomajiBeforeCursor(text: "hello world", cursorPosition: 11) ?? "nil")

    test("ローマ字がない場合",
         extractRomajiBeforeCursor(text: "123 ", cursorPosition: 4) == nil,
         expected: "nil",
         actual: extractRomajiBeforeCursor(text: "123 ", cursorPosition: 4) ?? "nil")

    test("カーソル位置0の場合",
         extractRomajiBeforeCursor(text: "hello", cursorPosition: 0) == nil,
         expected: "nil",
         actual: extractRomajiBeforeCursor(text: "hello", cursorPosition: 0) ?? "nil")

    test("記号の後のローマ字",
         extractRomajiBeforeCursor(text: "foo-bar", cursorPosition: 7) == "bar",
         expected: "bar",
         actual: extractRomajiBeforeCursor(text: "foo-bar", cursorPosition: 7) ?? "nil")

    test("日本語の後のローマ字",
         extractRomajiBeforeCursor(text: "こんにちはnihongo", cursorPosition: 12) == "nihongo",
         expected: "nihongo",
         actual: extractRomajiBeforeCursor(text: "こんにちはnihongo", cursorPosition: 12) ?? "nil")

    test("大文字は無視される",
         extractRomajiBeforeCursor(text: "HELLO", cursorPosition: 5) == nil,
         expected: "nil",
         actual: extractRomajiBeforeCursor(text: "HELLO", cursorPosition: 5) ?? "nil")

    test("小文字のみ抽出",
         extractRomajiBeforeCursor(text: "heLLo", cursorPosition: 2) == "he",
         expected: "he",
         actual: extractRomajiBeforeCursor(text: "heLLo", cursorPosition: 2) ?? "nil")

    test("数字が混ざっている場合",
         extractRomajiBeforeCursor(text: "test123abc", cursorPosition: 10) == "abc",
         expected: "abc",
         actual: extractRomajiBeforeCursor(text: "test123abc", cursorPosition: 10) ?? "nil")

    // getKeyCode のテスト
    print("\n--- getKeyCode のテスト ---")

    test("aのキーコード", getKeyCode(for: "a") == 0x00)
    test("zのキーコード", getKeyCode(for: "z") == 0x06)
    test("nのキーコード", getKeyCode(for: "n") == 0x2D)
    test("存在しない文字", getKeyCode(for: "1") == nil)
    test("大文字は対応しない", getKeyCode(for: "A") == nil)

    // 結果表示
    print("\n=== テスト結果 ===")
    print("成功: \(passCount)")
    print("失敗: \(failCount)")
    print("合計: \(passCount + failCount)")

    if failCount == 0 {
        print("\n✅ すべてのテストに合格しました！")
        exit(0)
    } else {
        print("\n❌ \(failCount)個のテストが失敗しました")
        exit(1)
    }
}

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

// メイン処理
func main() {
    writeDebugLog("=== convert-romaji.swift 開始 ===")

    // Accessibility権限チェック
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

    if !trusted {
        writeDebugLog("❌ Accessibility権限がありません")
        print("Accessibility権限が必要です")
        exit(1)
    }
    writeDebugLog("✅ Accessibility権限OK")

    // テキストとカーソル位置を取得
    let text = getFocusedElementText()
    let cursorPos = getCursorPosition()

    writeDebugLog("テキスト取得結果: \(text ?? "nil")")
    writeDebugLog("カーソル位置: \(cursorPos?.description ?? "nil")")

    guard let text = text, let cursorPos = cursorPos else {
        // テキスト取得失敗時は通常のIMEオンのみ
        writeDebugLog("⚠️ テキスト取得失敗 -> 通常のIMEオンのみ")
        sendKeyPress(kVK_JIS_Kana)
        exit(0)
    }

    // ローマ字を検出
    let romaji = extractRomajiBeforeCursor(text: text, cursorPosition: cursorPos)
    writeDebugLog("抽出されたローマ字: \(romaji ?? "nil")")

    guard let romaji = romaji, !romaji.isEmpty else {
        // ローマ字がない場合は通常のIMEオンのみ
        writeDebugLog("⚠️ ローマ字なし -> 通常のIMEオンのみ")
        sendKeyPress(kVK_JIS_Kana)
        exit(0)
    }

    writeDebugLog("✅ 検出されたローマ字: \(romaji) (文字数: \(romaji.count))")

    // ローマ字の文字数分Backspaceを送信
    writeDebugLog("🔙 Backspaceを\(romaji.count)回送信開始")
    for i in 0..<romaji.count {
        sendKeyPress(kVK_Delete)
        writeDebugLog("  Backspace \(i+1)/\(romaji.count)")
    }

    usleep(50000) // 50ms待機

    // IMEをオン
    writeDebugLog("🈴 IMEをオン")
    sendKeyPress(kVK_JIS_Kana)
    usleep(100000) // 100ms待機（IME起動を待つ）

    // ローマ字を1文字ずつ送信
    writeDebugLog("⌨️  ローマ字を再送信: \(romaji)")
    for char in romaji.lowercased() {
        if let keyCode = getKeyCode(for: char) {
            sendKeyPress(keyCode)
            writeDebugLog("  送信: \(char)")
        }
    }

    writeDebugLog("=== convert-romaji.swift 終了 ===\n")
}

// エントリーポイント
if CommandLine.arguments.count > 1 && CommandLine.arguments[1] == "--test" {
    runTests()
} else {
    main()
}
