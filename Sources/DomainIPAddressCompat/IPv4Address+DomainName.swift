import struct NIOCore.ByteBuffer

extension DomainName {
    public init(ipv4: IPv4Address) {
        var buffer = ByteBuffer()
        /// 16 is the maximum number of bytes required to represent an IPv4 address here
        buffer.reserveCapacity(16)

        let bytes = ipv4.bytes

        buffer.writeInteger(.zero, as: UInt8.self)
        var segmentStartIndex = buffer.writerIndex
        bytes.0.asDecimal(writeUTF8Byte: { buffer.writeInteger($0) })
        buffer.setInteger(
            UInt8(truncatingIfNeeded: buffer.writerIndex &- segmentStartIndex),
            at: segmentStartIndex &- 1,
            as: UInt8.self
        )

        buffer.writeInteger(.zero, as: UInt8.self)
        segmentStartIndex = buffer.writerIndex
        bytes.1.asDecimal(writeUTF8Byte: { buffer.writeInteger($0) })
        buffer.setInteger(
            UInt8(truncatingIfNeeded: buffer.writerIndex &- segmentStartIndex),
            at: segmentStartIndex &- 1,
            as: UInt8.self
        )

        buffer.writeInteger(.zero, as: UInt8.self)
        segmentStartIndex = buffer.writerIndex
        bytes.2.asDecimal(writeUTF8Byte: { buffer.writeInteger($0) })
        buffer.setInteger(
            UInt8(truncatingIfNeeded: buffer.writerIndex &- segmentStartIndex),
            at: segmentStartIndex &- 1,
            as: UInt8.self
        )

        buffer.writeInteger(.zero, as: UInt8.self)
        segmentStartIndex = buffer.writerIndex
        bytes.3.asDecimal(writeUTF8Byte: { buffer.writeInteger($0) })
        buffer.setInteger(
            UInt8(truncatingIfNeeded: buffer.writerIndex &- segmentStartIndex),
            at: segmentStartIndex &- 1,
            as: UInt8.self
        )

        self.init(isFQDN: false, _uncheckedAssumingValidWireFormatBytes: buffer)
    }
}
