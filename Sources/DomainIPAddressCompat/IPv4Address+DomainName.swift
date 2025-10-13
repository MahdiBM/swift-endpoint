import struct NIOCore.ByteBuffer

extension DomainName {
    public init(ipv4: IPv4Address) {
        var buffer = ByteBuffer()
        /// 16 is the maximum number of bytes required to represent an IPv4 address here
        buffer.reserveCapacity(16)

        let lengthPrefixIndex = buffer.writerIndex
        // Write a zero as a placeholder which will later be overwritten by the actual number of bytes written
        buffer.writeInteger(.zero, as: UInt8.self)

        let startWriterIndex = buffer.writerIndex

        let bytes = ipv4.bytes

        bytes.0.asDecimal(
            writeUTF8Byte: {
                buffer.writeInteger($0)
            }
        )
        buffer.writeInteger(UInt8.asciiDot)

        bytes.1.asDecimal(
            writeUTF8Byte: {
                buffer.writeInteger($0)
            }
        )
        buffer.writeInteger(UInt8.asciiDot)

        bytes.2.asDecimal(
            writeUTF8Byte: {
                buffer.writeInteger($0)
            }
        )
        buffer.writeInteger(UInt8.asciiDot)

        bytes.3.asDecimal(
            writeUTF8Byte: {
                buffer.writeInteger($0)
            }
        )

        let endWriterIndex = buffer.writerIndex
        let bytesWritten = endWriterIndex - startWriterIndex

        /// This is safe to unwrap.
        /// The implementation above cannot write more bytes than a UInt8 can represent.
        let lengthPrefix = UInt8(exactly: bytesWritten).unsafelyUnwrapped

        buffer.setInteger(
            lengthPrefix,
            at: lengthPrefixIndex,
            as: UInt8.self
        )

        self.init(isFQDN: false, _uncheckedAssumingValidWireFormatBytes: buffer)
    }
}
