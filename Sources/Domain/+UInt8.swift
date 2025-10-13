extension UInt8 {
    @inlinable
    var isLowercasedLetterOrDigitOrHyphenOrUnderscoreOrStarOrWhitespace: Bool {
        self.isLowercasedLetter
            || self.isDigit
            || self == .asciiHyphenMinus
            || self == .asciiUnderscore
            || self == .asciiStar
            || self == .asciiWhitespace
    }

    @inlinable
    var isLowercasedLetter: Bool {
        self >= 0x61 && self <= 0x7A
    }

    @inlinable
    var isDigit: Bool {
        self >= 0x30 && self <= 0x39
    }

    @inlinable
    var isASCII: Bool {
        self & 0b1000_0000 == 0
    }

    @inlinable
    static var asciiHyphenMinus: UInt8 {
        0x2D
    }

    @inlinable
    static var asciiUnderscore: UInt8 {
        0x5F
    }

    @inlinable
    static var asciiWhitespace: UInt8 {
        0x20
    }

    @inlinable
    static var asciiStar: UInt8 {
        0x2A
    }

    @inlinable
    static var asciiDot: UInt8 {
        0x2E
    }
}
