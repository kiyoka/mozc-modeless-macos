#!/usr/bin/env swift

import Cocoa
import ApplicationServices

// キーコード定義
let kVK_Delete: CGKeyCode = 0x33
let kVK_JIS_Kana: CGKeyCode = 0x68
let kVK_ANSI_C: CGKeyCode = 0x08
let kVK_LeftArrow: CGKeyCode = 0x7B
let kVK_Space: CGKeyCode = 0x31

// タイミング定数（マイクロ秒）
let WAIT_KEY_PRESS_US:       UInt32 = 5000   // sendKey デフォルト: キー送信間隔 (5ms)
let WAIT_ROMAJI_CHAR_US:     UInt32 = 0      // ローマ字1文字送信間隔 (0ms - CGEventは待機不要)
let WAIT_DELETE_CHAR_US:     UInt32 = 0      // Backspace1文字間隔 (0ms - CGEventは待機不要)
let WAIT_CLIPBOARD_CLEAR_US: UInt32 = 20000  // クリップボードクリア後の待機 (20ms)
let WAIT_WORD_SELECT_US:     UInt32 = 50000  // Cmd+Shift+Left後の待機 (50ms)
let WAIT_CLIPBOARD_COPY_US:  UInt32 = 50000  // Cmd+C後の待機 (50ms)
let WAIT_DELETE_AFTER_US:    UInt32 = 20000  // deleteFast後の待機 (20ms)
let WAIT_IME_STARTUP_US:     UInt32 = 80000  // IME起動待機 (80ms) ※80ms未満は不安定
let WAIT_PRE_CONVERT_US:     UInt32 = 20000  // Space送信前の待機 (20ms)

// パス定数
let KARABINER_CLI_PATH = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"

// Karabiner変数名定数
let VAR_IME_CONVERTING = "ime_converting"

// 計測用: スクリプト開始時刻
var scriptStartTime = Date()

// 開始時刻からの経過時間をmsで返す
func elapsedMs() -> String {
    let ms = Int(Date().timeIntervalSince(scriptStartTime) * 1000)
    return "+\(ms)ms"
}

// ログファイルハンドル（開きっぱなし）
var logFileHandle: FileHandle? = nil

// ログファイルを開く（スクリプト開始時に1回だけ呼ぶ）
func openDebugLog() {
    let logDir = NSHomeDirectory() + "/.local/bin/mozc-modeless-macos"
    let logPath = logDir + "/debug.log"

    if !FileManager.default.fileExists(atPath: logDir) {
        try? FileManager.default.createDirectory(atPath: logDir, withIntermediateDirectories: true, attributes: nil)
    }
    if !FileManager.default.fileExists(atPath: logPath) {
        FileManager.default.createFile(atPath: logPath, contents: nil)
    }
    logFileHandle = FileHandle(forWritingAtPath: logPath)
    logFileHandle?.seekToEndOfFile()
}

// ログファイルを閉じる（スクリプト終了時に1回だけ呼ぶ）
func closeDebugLog() {
    logFileHandle?.closeFile()
    logFileHandle = nil
}

// デバッグログを書き込む関数
func writeDebugLog(_ message: String) {
    let timestamp = Date()
    let logMessage = "[\(timestamp)] \(message)\n"
    if let data = logMessage.data(using: .utf8) {
        logFileHandle?.write(data)
    }
}

// Karabiner変数を設定する（karabiner_cliを使用）
func setKarabinerVariable(_ name: String, value: Int) {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: KARABINER_CLI_PATH)
    task.arguments = ["--set-variables", "{\"\(name)\": \(value)}"]
    task.standardOutput = FileHandle.nullDevice
    task.standardError = FileHandle.nullDevice
    try? task.run()
    task.waitUntilExit()
}

// キーストロークを送信する関数（waitUs でキー間隔を指定）
func sendKey(_ keyCode: CGKeyCode, withModifiers modifiers: CGEventFlags = [], waitUs: UInt32 = WAIT_KEY_PRESS_US) {
    let source = CGEventSource(stateID: .hidSystemState)
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)

    keyDown?.flags = modifiers
    keyUp?.flags = modifiers

    keyDown?.post(tap: .cghidEventTap)
    usleep(waitUs)
    keyUp?.post(tap: .cghidEventTap)
    usleep(waitUs)
}

// 高速Backspace用の関数（ユーザー入力との競合を防ぐため選択方式から変更）
func deleteFast(_ count: Int) {
    let source = CGEventSource(stateID: .hidSystemState)

    for _ in 0..<count {
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: kVK_Delete, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: kVK_Delete, keyDown: false)

        keyDown?.post(tap: .cghidEventTap)
        usleep(WAIT_DELETE_CHAR_US)
        keyUp?.post(tap: .cghidEventTap)
        usleep(WAIT_DELETE_CHAR_US)
    }
}

// 文字からキーコードへの変換マップ
func getKeyCode(for char: Character) -> CGKeyCode? {
    let mapping: [Character: CGKeyCode] = [
        // 小文字アルファベット
        "a": 0x00, "b": 0x0B, "c": 0x08, "d": 0x02, "e": 0x0E,
        "f": 0x03, "g": 0x05, "h": 0x04, "i": 0x22, "j": 0x26,
        "k": 0x28, "l": 0x25, "m": 0x2E, "n": 0x2D, "o": 0x1F,
        "p": 0x23, "q": 0x0C, "r": 0x0F, "s": 0x01, "t": 0x11,
        "u": 0x20, "v": 0x09, "w": 0x0D, "x": 0x07, "y": 0x10,
        "z": 0x06,
        // 大文字アルファベット（同じキーコード、Shiftは後で処理）
        "A": 0x00, "B": 0x0B, "C": 0x08, "D": 0x02, "E": 0x0E,
        "F": 0x03, "G": 0x05, "H": 0x04, "I": 0x22, "J": 0x26,
        "K": 0x28, "L": 0x25, "M": 0x2E, "N": 0x2D, "O": 0x1F,
        "P": 0x23, "Q": 0x0C, "R": 0x0F, "S": 0x01, "T": 0x11,
        "U": 0x20, "V": 0x09, "W": 0x0D, "X": 0x07, "Y": 0x10,
        "Z": 0x06,
        // 数字
        "0": 0x1D, "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15,
        "5": 0x17, "6": 0x16, "7": 0x1A, "8": 0x1C, "9": 0x19,
        // 記号（Shiftなし）
        "-": 0x1B, // ハイフン
        ".": 0x2F, // ピリオド
        ",": 0x2B, // カンマ
        ";": 0x29, // セミコロン
        "'": 0x27, // シングルクォート
        "`": 0x32, // バックティック
        "[": 0x21, // 左角括弧
        "]": 0x1E, // 右角括弧
        " ": 0x31, // スペース
        // 記号（Shiftあり） - 基本キーコード
        "@": 0x13, // Shift + 2
        ":": 0x29, // Shift + ;
        "+": 0x18, // Shift + =
        "!": 0x12, // Shift + 1
        "?": 0x2C  // Shift + /
    ]
    return mapping[char]
}

// Shiftキーが必要な文字かどうかを判定
func needsShift(_ char: Character) -> Bool {
    // 大文字、または Shift が必要な記号
    if char.isUppercase { return true }
    let shiftChars: Set<Character> = ["@", ":", "+", "!", "?"]
    return shiftChars.contains(char)
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
    usleep(WAIT_CLIPBOARD_CLEAR_US)
    writeDebugLog("⏱ クリップボードクリア完了: \(elapsedMs())")

    // Cmd+Shift+Left で単語を選択
    writeDebugLog("Cmd+Shift+Left で単語選択")
    sendKey(kVK_LeftArrow, withModifiers: [.maskCommand, .maskShift])
    usleep(WAIT_WORD_SELECT_US)
    writeDebugLog("⏱ 単語選択完了: \(elapsedMs())")

    // Cmd+C でコピー → 直後に Right arrow で選択解除（選択状態を最小化）
    // CGEventはキューに積まれるため、Cmd+CのコピーはRight arrow処理前に完了する
    writeDebugLog("Cmd+C でコピー")
    sendKey(kVK_ANSI_C, withModifiers: .maskCommand)
    sendKey(0x7C) // Right arrow - 選択解除（コピー直後）
    setKarabinerVariable(VAR_IME_CONVERTING, value: 0) // キーブロック解除（選択解除直後）
    usleep(WAIT_CLIPBOARD_COPY_US)
    writeDebugLog("⏱ クリップボードコピー＋選択解除完了: \(elapsedMs())")

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
    scriptStartTime = Date()
    openDebugLog()
    writeDebugLog("=== convert-romaji-clipboard.swift 開始 ===")

    // Accessibility権限チェック
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

    if !trusted {
        writeDebugLog("❌ Accessibility権限がありません")
        print("Accessibility権限が必要です")
        setKarabinerVariable(VAR_IME_CONVERTING, value: 0) // 安全のため解除
        closeDebugLog()
        exit(1)
    }
    writeDebugLog("✅ Accessibility権限OK")

    // 単語を選択してコピー
    guard let selectedText = selectAndCopyWord() else {
        writeDebugLog("⚠️ テキスト選択失敗 -> 通常のIMEオンのみ")
        setKarabinerVariable(VAR_IME_CONVERTING, value: 0) // 安全のため解除
        sendKey(kVK_JIS_Kana)
        closeDebugLog()
        exit(0)
    }

    writeDebugLog("選択されたテキスト: \(selectedText)")
    writeDebugLog("⏱ テキスト取得フェーズ完了: \(elapsedMs())")

    // 選択されたテキストの末尾からローマ字を抽出
    guard let result = extractRomajiFromEnd(selectedText) else {
        writeDebugLog("⚠️ 末尾にローマ字なし: \(selectedText) -> 通常のIMEオンのみ")
        setKarabinerVariable(VAR_IME_CONVERTING, value: 0) // 安全のため解除
        sendKey(kVK_JIS_Kana)
        closeDebugLog()
        exit(0)
    }

    let romaji = result.romaji
    let deleteCount = result.deleteCount

    writeDebugLog("✅ 検出されたローマ字: \(romaji) (文字数: \(romaji.count), 削除文字数: \(deleteCount))")

    // deleteCount の文字数分を高速Backspaceで削除（選択状態を作らないため安全）
    writeDebugLog("🔙 Backspaceで\(deleteCount)文字を削除（高速モード）")
    deleteFast(deleteCount)
    usleep(WAIT_DELETE_AFTER_US)
    writeDebugLog("⏱ 削除完了: \(elapsedMs())")

    // IMEをオン
    writeDebugLog("🈴 IMEをオン")
    sendKey(kVK_JIS_Kana)
    usleep(WAIT_IME_STARTUP_US)
    writeDebugLog("⏱ IME起動完了: \(elapsedMs())")

    // ローマ字を1文字ずつ高速送信（waitUs: WAIT_ROMAJI_CHAR_US = 0ms）
    writeDebugLog("⌨️  ローマ字を再送信: \(romaji) (\(romaji.count)文字)")
    for char in romaji {
        if let keyCode = getKeyCode(for: char) {
            // Shiftキーが必要な文字の場合
            if needsShift(char) {
                sendKey(keyCode, withModifiers: .maskShift, waitUs: WAIT_ROMAJI_CHAR_US)
            } else {
                sendKey(keyCode, waitUs: WAIT_ROMAJI_CHAR_US)
            }
        } else {
            writeDebugLog("  ⚠️ キーコード未定義: \(char)")
        }
    }
    writeDebugLog("⏱ ローマ字送信完了: \(elapsedMs())")

    // スペースキーを送信して変換
    usleep(WAIT_PRE_CONVERT_US)
    sendKey(kVK_Space)
    writeDebugLog("␣ 変換完了")
    writeDebugLog("⏱ 総経過時間: \(elapsedMs())")

    writeDebugLog("=== convert-romaji-clipboard.swift 終了 ===\n")
    closeDebugLog()
}

main()
