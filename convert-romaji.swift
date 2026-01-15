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

// メイン処理
func main() {
    // Accessibility権限チェック
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

    if !trusted {
        print("Accessibility権限が必要です")
        exit(1)
    }

    // テキストとカーソル位置を取得
    guard let text = getFocusedElementText(),
          let cursorPos = getCursorPosition() else {
        // テキスト取得失敗時は通常のIMEオンのみ
        sendKeyPress(kVK_JIS_Kana)
        exit(0)
    }

    // ローマ字を検出
    guard let romaji = extractRomajiBeforeCursor(text: text, cursorPosition: cursorPos),
          !romaji.isEmpty else {
        // ローマ字がない場合は通常のIMEオンのみ
        sendKeyPress(kVK_JIS_Kana)
        exit(0)
    }

    print("検出されたローマ字: \(romaji)")

    // ローマ字の文字数分Backspaceを送信
    for _ in 0..<romaji.count {
        sendKeyPress(kVK_Delete)
    }

    usleep(50000) // 50ms待機

    // IMEをオン
    sendKeyPress(kVK_JIS_Kana)
    usleep(100000) // 100ms待機（IME起動を待つ）

    // ローマ字を1文字ずつ送信
    for char in romaji.lowercased() {
        if let keyCode = getKeyCode(for: char) {
            sendKeyPress(keyCode)
        }
    }
}

main()
