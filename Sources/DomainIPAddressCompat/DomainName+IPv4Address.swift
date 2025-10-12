public import Domain
public import IPAddress

public import struct NIOCore.ByteBuffer

@available(swiftEndpointApplePlatforms 13, *)
extension IPv4Address {
    /// Initialize an `IPv4Address` from a `DomainName`.
    /// The domain name must correspond to a valid IPv4 address.
    /// For example a domain name like `"127.0.0.1"` will parse into the IPv4 address `127.0.0.1`.
    @inlinable
    public init?(domainName: DomainName) {
        guard
            let result = domainName._data.withUnsafeReadableBytes({ ptr -> IPv4Address? in
                ptr.withMemoryRebound(to: UInt8.self) { ptr in
                    var ipv4 = IPv4Address(0)
                    var iterator = domainName.makePositionIterator()

                    /// `DomainName.data` always only contains ASCII bytes
                    let asciiSpan = ptr.span

                    var idx = 0
                    while let (range, _) = iterator.nextRange() {
                        guard
                            let byte = UInt8(
                                decimalRepresentation: asciiSpan.extracting(unchecked: range)
                            )
                        else {
                            return nil
                        }

                        /// Unchecked because `idx` can't exceed `3` anyway
                        let shift = 8 &* (3 &- idx)
                        ipv4.address |= UInt32(byte) &<< shift

                        if idx == 3 {
                            if iterator.reachedEnd() {
                                /// We've had exactly enough labels, let's return
                                return ipv4
                            } else {
                                return nil
                            }
                        }

                        idx &+= 1
                    }

                    /// We had less than 4 labels, so this is an error
                    return nil
                }
            })
        else {
            return nil
        }

        self = result
    }

    /// Initialize an `IPv4Address` from a `DomainName`.
    /// The domain name must correspond to a valid IPv4 address.
    /// For example a domain name like `"127.0.0.1"` will parse into the IPv4 address `127.0.0.1`.
    @inlinable
    init?(
        __domainNameSpan asciiSpan: Span<UInt8>,
        iterator: inout DomainName.PositionIterator,
        firstRange: Range<Int>,
        expectingRightSquareBracketAtTheEnd: Bool
    ) {
        self.init(0)

        let byteSpan1 = asciiSpan.extracting(unchecked: firstRange)
        guard let byte1 = UInt8(decimalRepresentation: byteSpan1) else {
            return nil
        }
        self.address |= UInt32(byte1) &<< 24

        guard let (range2, _) = iterator.nextRange() else {
            return nil
        }
        let byteSpan2 = asciiSpan.extracting(unchecked: range2)
        guard let byte2 = UInt8(decimalRepresentation: byteSpan2) else {
            return nil
        }
        self.address |= UInt32(byte2) &<< 16

        guard let (range3, _) = iterator.nextRange() else {
            return nil
        }
        let byteSpan3 = asciiSpan.extracting(unchecked: range3)
        guard let byte3 = UInt8(decimalRepresentation: byteSpan3) else {
            return nil
        }
        self.address |= UInt32(byte3) &<< 8

        guard let (range4, _) = iterator.nextRange() else {
            return nil
        }
        var endIndex = range4.upperBound
        if expectingRightSquareBracketAtTheEnd {
            /// Domain name labels can't be empty based on contract, so this &-1 is safe
            guard asciiSpan[unchecked: endIndex &- 1] == UInt8.asciiRightSquareBracket else {
                return nil
            }
            endIndex &-= 1
        }
        let byteSpan4 = asciiSpan.extracting(unchecked: range4.lowerBound..<endIndex)
        guard let byte4 = UInt8(decimalRepresentation: byteSpan4) else {
            return nil
        }
        self.address |= UInt32(byte4)

        if iterator.reachedEnd() {
            /// We've had exactly enough labels, let's return
            return
        } else {
            return nil
        }
    }
}
