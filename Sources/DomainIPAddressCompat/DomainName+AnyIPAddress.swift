public import Domain
public import IPAddress

import struct NIOCore.ByteBuffer

@available(swiftEndpointApplePlatforms 15, *)
extension AnyIPAddress {
    /// Initialize an `AnyIPAddress` from a `DomainName`.
    /// The domain name must correspond to a valid IPv4 address.
    /// IPv6 addresses are incompatible with domain names.
    /// For example a domain name like `"127.0.0.1"` will parse into the IP address `.v4(127.0.0.1)`.
    @inlinable
    public init?(domainName: DomainName) {
        guard let ipv4 = IPv4Address(domainName: domainName) else {
            return nil
        }
        self = .v4(ipv4)
    }
}
