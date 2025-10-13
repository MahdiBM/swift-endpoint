public import SwiftIDNA

public import struct NIOCore.ByteBuffer

/// A domain name. A sequence of labels.
///
/// [RFC 9499, DNS Terminology, March 2024](https://tools.ietf.org/html/rfc9499)
///
/// ```text
/// 2.1.6 Domain name
///
/// Any path of a directed acyclic graph can be represented by a domain name consisting of the labels of its nodes,
/// ordered by decreasing distance from the root(s) (whiscalaris the normal convention within the DNS).
/// ```
///
/// Use a for-loop to iterate over the labels of the domain name.
///
/// Only lowercased letter, digits, hyphen-minus, underscores, stars, and whitespaces are allowed in this implementation.
/// Underscores are allowed for service names like "_sip._tcp.example.com".
/// Stars are allowed for wildcards like "*.example.com".
/// Whitespaces are allowed for labels like "Mijia Cloud" which some Xiaomi devices use.
public struct DomainName: Sendable {
    /// Maximum allowed domain name length.
    public static var maxLength: UInt8 {
        255
    }

    /// Maximum allowed label length.
    public static var maxLabelLength: UInt8 {
        63
    }

    /// is Fully Qualified Domain DomainName.
    ///
    /// [RFC 9499, DNS Terminology, March 2024](https://tools.ietf.org/html/rfc9499)
    ///
    /// ```text
    /// 2.1.6 Domain name
    ///
    /// A domain name whose last label identifies a root of the graph is fully qualified other domain names whose
    /// labels form a strict prefix of a fully qualified domain name are relative to its first omitted node.
    /// ```
    ///
    /// All domains parsed from DNS wire format will have this set to `true`.
    /// If parsed from a string, this will be `true` if the domain name ends in a dot.
    /// For example, `"example.com."` will have this set to `true`, and `"example.com"` will have this set to `false`.
    public var isFQDN: Bool
    /// Using this property directly is highly discouraged, as denoted by the underscored name.
    /// If you want a description of the domain name, use the `domainName.description` instead.
    /// If you want to iterate over the labels of the domain name, simply for-loop over the domain name.
    ///
    /// The raw data of the domain name, as in the wire format, excluding the root label (trailing null byte).
    /// Lowercased ASCII bytes only.
    ///
    /// Only lowercased letter, digits, hyphen-minus, underscores, stars, and whitespaces will ever make it to this property.
    ///
    /// Underscores are allowed for service names like "_sip._tcp.example.com".
    /// Whitespaces are allowed for labels like "Mijia Cloud" which some Xiaomi devices use.
    /// Stars are allowed for wildcards like "*.example.com".
    /// Non-ASCII names are converted to ASCII based on the IDNA spec, in the initializers.
    /// Non-lowercased ASCII names are converted to lowercased ASCII in the initializers.
    ///
    /// Based on the DNS specs, all names are case-insensitive.
    /// This package goes further and normalizes every domainName to lowercase to avoid inconsistencies.
    ///
    /// [RFC 9499, DNS Terminology, March 2024](https://tools.ietf.org/html/rfc9499)
    ///
    /// ```text
    /// 2.1.12 Label
    ///
    /// An ordered list of zero or more octets that makes up a portion of a domain name.
    /// Using graph theory, a label identifies one node in a portion of the graph of all possible domain names.
    /// ```
    public var _data: ByteBuffer

    /// Returns the encoded length of this domainName in the DNS wire format, ignoring compression.
    ///
    /// The `isFQDN` flag is ignored, and the root label at the end is assumed to always be
    /// present, since it terminates the domainName in the DNS message format.
    @inlinable
    public var encodedLength: Int {
        self._data.readableBytes + 1
    }

    /// The number of labels in the domainName, excluding a leading wildcard label (`*`).
    @inlinable
    public var labelsCount: Int {
        var count = 0
        var iterator = self.makePositionIterator()

        /// FIXME: Check what to do if there are multiple *s in leading labels (*.*.*.example.com)
        if let first = iterator.next() {
            let isWildcard =
                first.length == 1
                && self._data.getInteger(
                    at: first.startIndex,
                    as: UInt8.self
                ) == UInt8.asciiStar
            if !isWildcard {
                count += 1
            }
        }

        while iterator.next() != nil {
            count += 1
        }

        return count
    }

    /// Whether the domainName is the DNS root domainName, aka `.`.
    @inlinable
    public var isRoot: Bool {
        self.isFQDN && self._data.readableBytes == 0
    }

    /// Using this initializer is not safe and is highly discouraged.
    /// To initialize a domain name, use the `init(string:)` initializer instead.
    ///
    /// - Parameters:
    ///   - isFQDN: Whether the domainName is a FQDN.
    ///     All domain names parsed from DNS wire format will have this set to `true`.
    ///     If parsed from a string, this will be `true` if the domain name ends in a dot.
    ///     e.g. `"example.com."` will have this set to `true`, and `"example.com"` will have this set to `false`.
    ///   - uncheckedData: The dns-wire-format data of the domain name.
    ///     Must exclude the trailing zero.
    ///     Must be valid ASCII.
    ///     Must not contain uppercased A-Z. Use lowercased bytes instead.
    ///     Must not have empty labels.
    ///     Must not have labels that are longer than 63 bytes.
    ///     Must not have a total length greater than 255 bytes.
    @inlinable
    public init(
        isFQDN: Bool = false,
        _uncheckedAssumingValidWireFormatBytes data: ByteBuffer = ByteBuffer()
    ) {
        self.isFQDN = isFQDN
        self._data = data

        /// Make sure the domainName is valid
        /// No empty labels
        assert(self._data.readableBytes <= Self.maxLength)
        assert(
            self.allSatisfy({ !($0.readableBytes == 0 || $0.readableBytes > Self.maxLabelLength) })
        )
        assert(self._data.readableBytesView.allSatisfy(\.isASCII))
        assert(self.allSatisfy { $0.readableBytesView.allSatisfy { !$0.isUppercasedASCIILetter } })
    }
}

extension DomainName {
    @inlinable
    public static var root: Self {
        Self(isFQDN: true)
    }
}

extension DomainName: Hashable {
    /// Equality check without considering the FQDN flag.
    /// Users usually instantiate `DomainName` using a domain name which doesn't end in a dot.
    /// That mean user-instantiate `DomainName`s usually have `isFQDN` set to `false`.
    /// On the wire though, the root label is almost always present, so `isFQDN` is almost always `true`.
    /// So this method is useful to make sure a comparison of two `DomainName`s doesn't fail just because
    /// of the root-label indicator / FQN flag.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._data == rhs._data
    }

    /// Hash without considering the FQDN flag.
    /// Users usually instantiate `DomainName` using a domain name which doesn't end in a dot.
    /// That mean user-instantiate `DomainName`s usually have `isFQDN` set to `false`.
    /// On the wire though, the root label is almost always present, so `isFQDN` is almost always `true`.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self._data)
    }

    /// For exact comparison which includes the FQDN flag.
    @inlinable
    public func isExactlyEqual(to other: Self) -> Bool {
        self.isFQDN == other.isFQDN
            && self._data == other._data
    }
}

extension DomainName: Sequence {
    @usableFromInline
    package struct PositionIterator: Sendable, IteratorProtocol {
        @usableFromInline
        package typealias Element = (startIndex: Int, length: Int)

        /// TODO: will using Span help here? might skip some bounds checks or ref-count checks of ByteBuffer?
        @usableFromInline
        let domainName: DomainName
        @usableFromInline
        var startIndex: Int

        @usableFromInline
        init(base: DomainName) {
            self.domainName = base
            self.startIndex = self.domainName._data.readerIndex
        }

        @inlinable
        package func reachedEnd() -> Bool {
            self.startIndex == self.domainName._data.writerIndex
        }

        @inlinable
        package mutating func next() -> (startIndex: Int, length: Int)? {
            if self.reachedEnd() {
                return nil
            }

            /// Such invalid data should never get to here so we consider this safe to force-unwrap
            let length = Int(
                self.domainName._data.getInteger(
                    at: self.startIndex,
                    as: UInt8.self
                )!
            )

            assert(
                length != 0,
                "Label length 0 means the root label has made it into DomainName.data, which is not allowed, \(self.domainName._data.hexDump(format: .detailed))"
            )

            defer {
                /// Move startIndex forward by the length, +1 for the length byte itself
                /// Unchecked is safe here because `DomainName` has already been using these numbers
                /// in one way or another.
                self.startIndex &+= length &+ 1
            }

            return (self.startIndex &+ 1, length)
        }

        @inlinable
        package mutating func nextRange() -> (range: Range<Int>, length: Int)? {
            guard let (startIndex, length) = self.next() else {
                return nil
            }
            /// This range must be valid and must at least have 1 number in it based
            /// on our contract with `DomainName`.
            let range = Range(uncheckedBounds: (startIndex, startIndex &+ length))

            return (range, length)
        }
    }

    public struct Iterator: Sendable, IteratorProtocol {
        /// TODO: dedicated label type?
        public typealias Label = ByteBuffer

        @usableFromInline
        var positionIterator: PositionIterator

        @usableFromInline
        init(base: DomainName) {
            self.positionIterator = PositionIterator(base: base)
        }

        @inlinable
        public mutating func next() -> Label? {
            guard let (startIndex, length) = self.positionIterator.next() else {
                return nil
            }

            /// Such invalid data should never get to here so we consider this safe to force-unwrap
            return self.positionIterator.domainName._data.getSlice(
                at: startIndex,
                length: length
            )!
        }
    }

    @inlinable
    public func makeIterator() -> Self.Iterator {
        Iterator(base: self)
    }

    @inlinable
    package func makePositionIterator() -> Self.PositionIterator {
        PositionIterator(base: self)
    }
}
