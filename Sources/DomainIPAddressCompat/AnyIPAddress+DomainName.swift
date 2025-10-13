public import Domain
public import IPAddress

import struct NIOCore.ByteBuffer

@available(swiftEndpointApplePlatforms 15, *)
extension DomainName {
    /// Initialize an `DomainName` from a `AnyIPAddress`.
    /// The ip address must be a valid IPv4 address.
    /// IPv6 addresses are incompatible with domain names and will return `nil` unless they can be translated to an IPv4 address.
    /// For example an ip address like `.v4(127.0.0.1)` will turn into the domain name `"127.0.0.1"`.
    public init?(ip: AnyIPAddress) {
        switch ip {
        case .v4(let ipv4):
            self.init(ipv4: ipv4)
        case .v6(let ipv6):
            guard let ipv4 = IPv4Address(ipv6: ipv6) else {
                return nil
            }
            self.init(ipv4: ipv4)
        }
    }
}
