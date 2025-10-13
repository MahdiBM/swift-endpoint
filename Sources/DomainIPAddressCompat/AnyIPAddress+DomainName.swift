public import Domain
public import IPAddress

import struct NIOCore.ByteBuffer

@available(swiftEndpointApplePlatforms 15, *)
extension DomainName {
    /// Initialize an `DomainName` from a `AnyIPAddress`.
    /// The ip address must be a valid IPv4 address.
    /// IPv6 addresses are incompatible with domain names and will return `nil`.
    /// For example an ip address like `.v4(127.0.0.1)` will turn into the domain name `"127.0.0.1"`.
    public init?(ip: AnyIPAddress) {
        switch ip {
        case .v4(let ipv4):
            self.init(ipv4: ipv4)
        case .v6:
            return nil
        }
    }
}
