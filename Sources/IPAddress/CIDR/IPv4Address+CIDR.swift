@available(swiftEndpointApplePlatforms 15, *)
extension CIDR<IPv4Address> {
    /// Representing 127.0.0.0/8
    @inlinable
    public static var loopback: Self {
        Self(
            prefix: 0x7F_00_00_00,
            prefixLength: 8
        )
    }

    /// Representing 224.0.0.0/4
    @inlinable
    public static var multicast: Self {
        Self(
            prefix: 0xE0_00_00_00,
            prefixLength: 4
        )
    }

    /// Representing 169.254.0.0/16
    @inlinable
    public static var linkLocal: Self {
        Self(
            prefix: 0xA9_FE_00_00,
            prefixLength: 16
        )
    }

    /// Representing 255.255.255.255/32
    @inlinable
    public static var broadcast: Self {
        Self(
            prefix: 0xFF_FF_FF_FF,
            prefixLength: 32
        )
    }
}
