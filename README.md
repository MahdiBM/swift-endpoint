<p>
    <a href="https://github.com/swift-dns/swift-endpoint/actions/workflows/unit-tests.yml">
        <img
            src="https://img.shields.io/github/actions/workflow/status/swift-dns/swift-endpoint/unit-tests.yml?event=push&style=plastic&logo=github&label=unit-tests&logoColor=%23ccc"
            alt="Unit Tests CI"
        >
    </a>
    <a href="https://github.com/swift-dns/swift-endpoint/actions/workflows/benchmarks.yml">
        <img
            src="https://img.shields.io/github/actions/workflow/status/swift-dns/swift-endpoint/benchmarks.yml?event=push&style=plastic&logo=github&label=benchmarks&logoColor=%23ccc"
            alt="Benchamrks CI"
        >
    </a>
    <a href="https://swift.org">
        <img
            src="https://design.vapor.codes/images/swift62up.svg"
            alt="Swift 6.2+"
        >
    </a>
</p>

# swift-endpoint

swift-endpoint is a high-performance package containing types representing an endpoint and related utilities.

The package contains a great amount of unit tests as well as benchmarks to ensure correctness and high performance.

## Implementations

- [x] `DomainName`
  - [x] Unicode-17-compliant IDNA support for non-ASCII domain names.
- [x] `IPv4Address`, `IPv6Address`, `AnyIPAddress`
- [x] `CIDR`
- [ ] `UnixDomainSocketAddress`

## Usage

swift-endpoint provides highly optimized implementations for converting its types to and from an String.

You can either initialize each type using a `String`, or initialize the exact underlying type they contain.

Here are some examples:

```swift
import Endpoint

/// Define a domain name. The type will parse the domain name and store it in DNS wire-format internally.
let domainName1 = try DomainName("mahdibm.com")
print(domainName1) /// prints "mahdibm.com"

/// Define a non-ASCII domain.
let domainName2 = try DomainName("新华网.中国")
print(domainName2) /// prints "新华网.中国"
print(domainName2.debugDescription) /// prints "xn--xkrr14bows.xn--fiqs8s"

/// Define a domain name containing an ip address.
let domainName3 = try DomainName("255.255.255.255")
print(domainName3) /// prints "255.255.255.255"

/// Define an ipv4 address. The type will parse the ip address into a UInt32 internally.
let ipv4Address1 = IPv4Address("127.0.0.1")!
let ipv4Address2 = IPv4Address(192, 168, 1, 1)!
print(ipv4Address1) /// prints "127.0.0.1"
print(ipv4Address2) /// prints "192.168.1.1"

/// Define an ipv6 address. The type will parse the ip address into a UInt128 internally.
let ipv6Address1 = IPv6Address("[FF::]")!
let ipv6Address2 = IPv6Address("2001:db8:85a3:0:0:0:0:100")!
let ipv6Address3 = IPv6Address("::FFFF:204.152.189.116")!
/// Prints the ipv6 representations according to RFC 5952
print(ipv6Address1) /// prints "[ff::]"
print(ipv6Address2) /// prints "[2001:db8:85a3::100]"
print(ipv6Address3) /// prints "[::ffff:cc98:bd74]"

/// Define an any-ip-address. The type will automatically parse the ip address into the corrext type.
let anyIPv4Address = AnyIPAddress("192.168.1.1")
let anyIPv6Address = AnyIPAddress("[2001:DB8:85A3::100]")
print(anyIPv4Address) /// prints "192.168.1.1"
print(anyIPv6Address) /// prints "[2001:db8:85a3::100]"

/// Define a CIDR. The type will store a `prefix` and a `mask`, representing this block of ips.
let cidr1 = CIDR(prefix: ipv4Address1, prefixLength: 8) /// ipv4Address1 == "127.0.0.1"
let cidr2 = CIDR<IPv4Address>("192.168.1.1")!
let containmentCheck1 = cidr1.contains(ipv4Address2) /// ipv4Address2 == "192.168.1.1"
let containmentCheck2 = cidr2.contains(ipv4Address2) /// ipv4Address2 == "192.168.1.1"
print(cidr1) /// prints "127.0.0.0/8"
print(cidr2) /// prints "192.168.1.1/32"
print(containmentCheck1) /// prints "false"
print(containmentCheck2) /// prints "true"
```

## Type Conversions

All types are convertible to each other in a performant way. Some examples:

```swift
import Endpoint

let ipInDomainName = try DomainName("255.255.255.255")

let fastIPv4 = IPv4Address(domainName: ipInDomainName)! /// ✅ Converts the domain into the equivalent ipv4 address
let slowIPv4 = IPv4Address(ipInDomainName.description)! /// ❌ This does work, but has worse performance

let fastIPv4Conversion = try DomainName(ipv4: fastIPv4)! /// ✅ Converts the ipv4 into the equivalent domain name
let slowIPv4Conversion = DomainName(fastIPv4.description)! /// ❌ This does work, but has worse performance

let anyIPAddress = AnyIPAddress(domainName: ipInDomainName)
print(anyIPAddress) /// prints "255.255.255.255"
```

## Performance

In [this post](https://forums.swift.org/t/pitch-standard-network-address-types/82288/11) on the Swift forums I was asked to compare IP parsing implementations with the native C libraries which provide functions such as `inet_ntop` and `inet_pton` which are commonly used by everyone, including swift-nio.

Here's the result at that point in time. Note that I made a lot of effort to make sure the C related functions are performing at their best.

In 7 out of the 8 benchmarks this library performs better than the C libraries.   
In the "IPv6 string decoding" benchmark it performs only 30% worse than Glibc, at ~23 millions rounds per second.

#### Against Darwin

These were performed on my M1 Pro MacBook, on macOS 26.0.

| Benchmark Name                              | Rounds      | Swift | inet_pton/ntop | Speedup |
| ------------------------------------------- | ----------- | ----- | -------------- | ------- |
| IPv4_String_Encoding_Mixed                  | 15 Millions | 153ms | 3036ms         | 19.84x  |
| IPv4_String_Decoding_Local_Broadcast        | 10 Millions | 251ms | 468ms          | 1.86x   |
| IPv6_String_Encoding_Mixed                  | 4 Millions  | 281ms | 1473ms         | 5.24x   |
| IPv6_String_Decoding_2_Groups_Compressed... | 3 Millions  | 180ms | 360ms          | 2x      |

#### Against Glibc

These were performed on a dedicated-cpu-core machine from Hetzner in the Falkenstein region.

> Host with 2 'x86_64' processors with 7 GB memory, running: #85-Ubuntu SMP PREEMPT_DYNAMIC

| Benchmark Name                              | Rounds      | Swift | inet_pton/ntop | Speedup |
| ------------------------------------------- | ----------- | ----- | -------------- | ------- |
| IPv4_String_Encoding_Mixed                  | 15 Millions | 190ms | 1570ms         | 8.26x   |
| IPv4_String_Decoding_Local_Broadcast        | 10 Millions | 180ms | 240ms          | 1.33x   |
| IPv6_String_Encoding_Mixed                  | 4 Millions  | 200ms | 1830ms         | 9.15x   |
| IPv6_String_Decoding_2_Groups_Compressed... | 3 Millions  | 130ms | 100ms          | 0.77x  |

#### Notes

* To see up to date information about performance of this package, please go to this [benchmarks list](https://github.com/swift-dns/swift-endpoint/actions/workflows/benchmarks.yml?query=branch%3Amain), and choose the most recent benchmark. You'll see a summary of the benchmark there.
* The results above are all reproducible by simply running `scripts/benchmark.bash` on a machine of your own.
* All benchmarks on all platforms commit similar allocations.   
* 3 of the benchmarks always do `0`, `IPv6_String_Encoding_Mixed` always does `1`.
