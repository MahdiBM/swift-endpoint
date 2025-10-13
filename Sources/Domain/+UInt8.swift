extension UInt8 {
    /// Whether the byte is a valid character in a domain name.
    ///
    /// Only lowercased letter, digits, hyphen-minus, underscores, stars, and whitespaces are allowed in a domain name.
    /// Underscores are allowed for service names like "_sip._tcp.example.com".
    /// Stars are allowed for wildcards like "*.example.com".
    /// Whitespaces are allowed for labels like "Mijia Cloud" which some Xiaomi devices use.
    @inlinable
    public var isAcceptableDomainNameCharacter: Bool {
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
