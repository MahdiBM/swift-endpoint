public import Domain
public import IPAddress

public import struct NIOCore.ByteBuffer

@available(swiftEndpointApplePlatforms 15, *)
extension AnyIPAddress {
    /// Initialize an `AnyIPAddress` from a `DomainName`.
    /// The domain name must correspond to a valid IP address.
    /// For example a domain name like `"127.0.0.1"` will parse into the IP address `.v4(127.0.0.1)`.
    /// Or a domain name like `"::1"` will parse into the IP address `.v6(::1)`,
    /// or a domain name like `"2001:db8:1111::"` will parse into the IP address `.v6(2001:DB8:1111:0:0:0:0:0)`.
    @inlinable
    public init?(domainName: DomainName) {
        var iterator = domainName.makePositionIterator()

        guard let (range, _) = iterator.nextRange() else {
            return nil
        }

        guard
            let result = domainName._data.withUnsafeReadableBytes({ ptr -> AnyIPAddress? in
                ptr.withMemoryRebound(to: UInt8.self) { ptr -> AnyIPAddress? in
                    /// `DomainName.data` always only contains ASCII bytes
                    let asciiSpan = ptr.span
                    /// If it was only one label, then it must be an IPv6. Otherwise, it must be an IPv4.
                    if iterator.reachedEnd() {
                        return IPv6Address(
                            _uncheckedAssumingValidASCII: asciiSpan.extracting(unchecked: range)
                        ).map { .v6($0) }
                    } else {
                        var ipv4 = IPv4Address(0)

                        if let byte = UInt8(
                            decimalRepresentation: asciiSpan.extracting(unchecked: range)
                        ) {
                            ipv4.address |= UInt32(byte) &<< 24

                            var idx = 1
                            while let (range, _) = iterator.nextRange() {
                                guard
                                    let byte = UInt8(
                                        decimalRepresentation: asciiSpan.extracting(
                                            unchecked: range
                                        )
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
                                        return .v4(ipv4)
                                    } else {
                                        return nil
                                    }
                                }

                                idx &+= 1
                            }
                        } else {
                            /// Maybe it's an ipv4-mapped ipv6 address
                            /// like `::FFFF:1.1.1.1`
                            return IPv6Address.ipv4Mapped(
                                asciiSpan: asciiSpan,
                                iterator: &iterator,
                                firstRange: range
                            ).map { .v6($0) }
                        }
                    }

                    return nil
                }
            })
        else {
            return nil
        }

        self = result
    }
}
