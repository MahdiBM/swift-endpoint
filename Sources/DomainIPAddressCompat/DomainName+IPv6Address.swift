public import Domain
public import IPAddress

public import struct NIOCore.ByteBuffer

@available(swiftEndpointApplePlatforms 15, *)
extension IPv6Address {
    /// Initialize an `IPv6Address` from a `DomainName`.
    /// The domain name must correspond to a valid IPv6 address.
    /// For example a domain name like `"::1"` will parse into the IPv6 address `::1`,
    /// or a domain name like `"2001:db8:1111::"` will parse into the IPv6 address `2001:DB8:1111:0:0:0:0:0`.
    @inlinable
    public init?(domainName: DomainName) {
        var iterator = domainName.makePositionIterator()
        guard let (range, _) = iterator.nextRange() else {
            return nil
        }

        if let ipv6Address = domainName._data.withUnsafeReadableBytes({ ptr -> IPv6Address? in
            ptr.withMemoryRebound(to: UInt8.self) { ptr in
                /// `DomainName.data` always only contains ASCII bytes
                let asciiSpan = ptr.span

                if iterator.reachedEnd() {
                    return IPv6Address(
                        _uncheckedAssumingValidASCII: asciiSpan.extracting(unchecked: range)
                    )
                } else {
                    /// Maybe it's an ipv4-mapped ipv6 address
                    /// like `::FFFF:1.1.1.1`
                    return IPv6Address.ipv4Mapped(
                        asciiSpan: asciiSpan,
                        iterator: &iterator,
                        firstRange: range
                    )
                }
            }
        }) {
            self = ipv6Address
            return
        }

        return nil
    }

    @inlinable
    static func ipv4Mapped(
        asciiSpan: Span<UInt8>,
        iterator: inout DomainName.PositionIterator,
        firstRange: Range<Int>
    ) -> IPv6Address? {
        guard let lastColonIdx = asciiSpan.lastIndex(where: { $0 == .asciiColon }) else {
            return nil
        }
        let afterLastColonIdx = lastColonIdx &+ 1
        guard afterLastColonIdx < firstRange.upperBound else {
            return nil
        }
        /// Need to trim the square brackets here and notify the ipv4 parsing logic
        /// Otherwise in an ipv4-mapped ipv6 address like `[::FFFF:1.1.1.1]`,
        /// we'll be asking the ipv4-parsing logic to parse `1.1.1.1]` and the ipv6 parsing logic to
        /// parse `[::FFFF`, and both of these are invalid.
        let expectingRightSquareBracketAtTheEnd =
            asciiSpan[unchecked: firstRange.lowerBound] == UInt8.asciiLeftSquareBracket
        var ipv6StartIndex = firstRange.lowerBound
        if expectingRightSquareBracketAtTheEnd {
            ipv6StartIndex &+= 1
        }
        guard
            let ipv4MappedSegment = IPv4Address(
                __domainNameSpan: asciiSpan,
                iterator: &iterator,
                firstRange: afterLastColonIdx..<firstRange.upperBound,
                expectingRightSquareBracketAtTheEnd: expectingRightSquareBracketAtTheEnd
            )
        else {
            return nil
        }
        let ipv6Range = ipv6StartIndex..<lastColonIdx
        return IPv6Address(
            _uncheckedAssumingValidASCII: asciiSpan.extracting(unchecked: ipv6Range),
            preParsedIPv4MappedSegment: ipv4MappedSegment
        )
    }
}
