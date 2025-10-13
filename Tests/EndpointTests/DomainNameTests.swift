import Endpoint
import NIOCore
import Testing

@Suite
struct DomainNameTests {
    @available(swiftEndpointApplePlatforms 13, *)
    @Test(
        arguments: [
            (domainName: "*", isFQDN: false, data: ByteBuffer([1, 42])),
            (domainName: ".", isFQDN: true, data: ByteBuffer([])),
            (domainName: "\u{3002}", isFQDN: true, data: ByteBuffer([])),
            (domainName: "a", isFQDN: false, data: ByteBuffer([1, 97])),
            (domainName: "*.b", isFQDN: false, data: ByteBuffer([1, 42, 1, 98])),
            (domainName: "a.b", isFQDN: false, data: ByteBuffer([1, 97, 1, 98])),
            (domainName: "*.b.c", isFQDN: false, data: ByteBuffer([1, 42, 1, 98, 1, 99])),
            (domainName: "a.b.c", isFQDN: false, data: ByteBuffer([1, 97, 1, 98, 1, 99])),
            (domainName: "a.b.c.", isFQDN: true, data: ByteBuffer([1, 97, 1, 98, 1, 99])),
            (
                domainName: "Mijia Cloud",
                isFQDN: false,
                data: ByteBuffer([
                    11, 109, 105, 106, 105, 97, 32, 99, 108, 111, 117, 100,
                ])
            ),
            (
                domainName: "helloß.co.uk.",
                isFQDN: true,
                data: ByteBuffer([
                    13, 120, 110, 45, 45, 104, 101, 108, 108, 111, 45, 112, 113, 97,
                    2, 99, 111, 2, 117, 107,
                ])
            ),
        ]
    )
    func initFromString(domainName: String, isFQDN: Bool, data: ByteBuffer) throws {
        let domainName = try DomainName(domainName)
        #expect(domainName.isFQDN == isFQDN)
        #expect(domainName._data == data)
    }

    @Test(
        arguments: [".mahdibm.com", ""]
    )
    func initInvalidFromString(domainName: String) throws {
        #expect(throws: (any Error).self) {
            try DomainName(domainName)
        }
    }

    @available(swiftEndpointApplePlatforms 13, *)
    @Test(
        arguments: [
            (
                ascii: "royale.mahdibm.com.",
                unicode: "royale.mahdibm.com.",
                asciiNoRootLabel: "royale.mahdibm.com",
                unicodeNoRootLabel: "royale.mahdibm.com",
            ),
            (
                ascii: "xn--1lq90ic7f1rc.cn",
                unicode: "\u{5317}\u{4eac}\u{5927}\u{5b78}.cn",
                asciiNoRootLabel: "xn--1lq90ic7f1rc.cn",
                unicodeNoRootLabel: "\u{5317}\u{4eac}\u{5927}\u{5b78}.cn",
            ),
            (
                ascii: "xn--36c-tfa.com",
                unicode: "36°c.com",
                asciiNoRootLabel: "xn--36c-tfa.com",
                unicodeNoRootLabel: "36°c.com"
            ),
            (
                ascii: "www.xn--hello-pqa.co.uk.",
                unicode: "www.helloß.co.uk.",
                asciiNoRootLabel: "www.xn--hello-pqa.co.uk",
                unicodeNoRootLabel: "www.helloß.co.uk"
            ),
        ]
    )
    func description(
        ascii: String,
        unicode: String,
        asciiNoRootLabel: String,
        unicodeNoRootLabel: String
    ) throws {
        let domainName = try DomainName(unicode)
        let nameASCII = try DomainName(ascii)

        /// If the names are the same then we don't need to compare their descriptions
        #expect(domainName == nameASCII)

        #expect(
            domainName.description(format: .ascii, options: .includeRootLabelIndicator)
                == ascii
        )
        #expect(
            domainName.description(format: .unicode, options: .includeRootLabelIndicator)
                == unicode
        )
        #expect(
            domainName.description(format: .ascii)
                == asciiNoRootLabel
        )
        #expect(
            domainName.description(format: .unicode)
                == unicodeNoRootLabel
        )
    }

    @available(swiftEndpointApplePlatforms 13, *)
    @Test func equalityWhichMustBeCaseInsensitive() throws {
        let domainName = try DomainName("example.com.")
        let duplicate = try DomainName("example.com.")
        let uppercased = try DomainName("EXAMPLE.COM.")
        let partiallyUppercased = try DomainName("exaMple.com.")
        let notFQDN = try DomainName("example.com")
        let letterMismatch = try DomainName("exmmple.com.")
        let bordersMismatch = try DomainName("example.com.com.")
        let different = try DomainName("mahdibm.com.")
        let differentNotFQDN = try DomainName("mahdibm.com")

        #expect(domainName == duplicate)
        #expect(domainName.isExactlyEqual(to: duplicate))
        #expect(domainName == uppercased)
        #expect(domainName == partiallyUppercased)
        #expect(domainName == notFQDN)
        #expect(!domainName.isExactlyEqual(to: notFQDN))
        #expect(domainName != letterMismatch)
        #expect(domainName != bordersMismatch)
        #expect(domainName != different)
        #expect(domainName != differentNotFQDN)

        let weirdUnicodeLowercaseDomain = try DomainName("helloß.co.uk.")
        let weirdUnicodeLowercaseDomainASCII = try DomainName("xn--hello-pqa.co.uk")
        let weirdPartiallyUppercaseDomain = try DomainName("helloSS.co.uk")
        let weirdUppercaseDomain = try DomainName("HELLOSS.CO.UK.")

        /// The DomainName initializers turn non-ascii domain names to IDNA-encoded domain names.
        /// `ß` and `SS` are case-insensitively equal, so with no IDNA these 2 names would be equal.
        #expect(weirdUnicodeLowercaseDomain == weirdUnicodeLowercaseDomainASCII)
        #expect(weirdUnicodeLowercaseDomain != weirdPartiallyUppercaseDomain)
        #expect(weirdUnicodeLowercaseDomain != weirdUppercaseDomain)
        #expect(weirdPartiallyUppercaseDomain == weirdUppercaseDomain)
    }

    @available(swiftEndpointApplePlatforms 13, *)
    @Test(
        arguments: [
            (domainName: ".", isFQDN: true),
            (domainName: "www.example.com.", isFQDN: true),
            (domainName: "www.example", isFQDN: false),
            (domainName: "www", isFQDN: false),
            (domainName: "test.", isFQDN: true),
        ]
    )
    func `fqdnParsing`(domainName: String, isFQDN: Bool) throws {
        try #expect(DomainName(domainName).isFQDN == isFQDN)
    }

    @Test(
        arguments: [
            (domainName: ".", expected: "."),
            (domainName: "www.example.com.", expected: "www.example.com."),
            (domainName: "www.example", expected: "www.example"),
            (domainName: "www", expected: "www"),
            (domainName: "test.", expected: "test."),
        ]
    )
    func `parsingThenAsStringWorksAsExpected`(domainName: String, expected: String) throws {
        #expect(
            try DomainName(domainName).description(
                format: .unicode,
                options: .includeRootLabelIndicator
            ) == expected
        )
    }

    @Test(
        arguments: [
            (domainName: "*", expectedLabelsCount: 0),
            (domainName: "a", expectedLabelsCount: 1),
            (domainName: "*.b", expectedLabelsCount: 1),
            (domainName: "a.b", expectedLabelsCount: 2),
            (domainName: "*.b.c", expectedLabelsCount: 2),
            (domainName: "a.b.c", expectedLabelsCount: 3),
        ]
    )
    func `numberOfLabels`(domainName: String, expectedLabelsCount: Int) throws {
        try #expect(DomainName(domainName).labelsCount == expectedLabelsCount)
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func ipv4AddressToName() throws {
        let ipAddress = IPv4Address(192, 168, 1, 1)
        let name1 = DomainName(ipv4: ipAddress)
        let name2 = DomainName(ip: .v4(ipAddress))
        #expect(name1.description == "192.168.1.1")
        #expect(name2?.description == "192.168.1.1")
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func ipv6AddressToName() {
        let ipAddress: IPv6Address = 0x2a01_5cc0_0001_0002_0000_0000_0000_0004
        #expect(DomainName(ip: .v6(ipAddress)) == nil)
    }

    /// The file pointing to `Resources.topDomains` contains only 200 top domains, but you can
    /// try bigger files too.
    /// For example you can manually go to cloudflare radar (https://radar.cloudflare.com/domains)
    /// and download the top 1 million domains csv file (or really top any-number, just csv).
    /// Just make sure the download file is only 1 column (so only a new domain on each new line).
    /// Then put it in Tests/Resources/ directory named exactly as `top-domains.csv`.
    /// And untrack the file so it's not committed to git (it's 14+ MiB).
    /// The file is 14+ MiB in size so it's not included in the repo.
    ///
    /// Not using swift-testing arguments because that slows things down significantly if we're
    /// testing against 1 million domains.
    @Test func testAgainstTopCloudflareRadarDomains() throws {
        for (index, domainNameString) in enumeratedTopDomains() {
            let comment: Comment = "index: \(index), domainName: \(domainNameString)"
            #expect(throws: Never.self, comment) {
                let domainName = try DomainName(domainNameString)
                let recreatedDomainName = domainName.description(
                    format: .ascii,
                    options: .includeRootLabelIndicator
                )
                #expect(recreatedDomainName == domainNameString, comment)
            }
        }
    }
}

private func enumeratedTopDomains() -> EnumeratedSequence<[String]> {
    String(
        decoding: Resources.topDomains.data(),
        as: UTF8.self
    ).split(
        whereSeparator: \.isNewline
    )
    .dropFirst()
    .map(String.init)
    .enumerated()
}
