import Foundation

enum PEArchitecture: String, Codable, Hashable {
    case x86 = "x86 (32-bit)"
    case x64 = "x86_64 (64-bit)"
    case arm64 = "ARM64"
    case unknown = "Unknown"
}

enum PESubsystem: String, Codable, Hashable {
    case windowsGUI = "Windows GUI"
    case windowsCUI = "Windows Console"
    case native = "Native"
    case unknown = "Unknown"
}

struct PESection: Hashable {
    let name: String
    let virtualAddress: UInt32
    let virtualSize: UInt32
    let rawOffset: UInt32
    let rawSize: UInt32
}

struct PEInfo: Hashable {
    let architecture: PEArchitecture
    let subsystem: PESubsystem
    let entryPointRVA: UInt32
    let imageBase: UInt64
    let isPE32Plus: Bool
    let sections: [PESection]

    var summary: String {
        "\(architecture.rawValue) • \(subsystem.rawValue)"
    }
}

enum PEInspector {
    static func inspect(url: URL) throws -> PEInfo {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        return try inspect(data: data)
    }

    static func inspect(data: Data) throws -> PEInfo {
        guard data.count >= 0x100 else { throw PEError.tooSmall }
        guard try u16(data, 0) == 0x5A4D else { throw PEError.notMZ }

        let peOffset = Int(try u32(data, 0x3C))
        guard peOffset >= 0, peOffset + 24 <= data.count else { throw PEError.invalidPEOffset }
        guard try u32(data, peOffset) == 0x0000_4550 else { throw PEError.notPE }

        let coff = peOffset + 4
        let machine = try u16(data, coff)
        let sectionCount = Int(try u16(data, coff + 2))
        let optionalSize = Int(try u16(data, coff + 16))
        let optional = coff + 20
        guard optional + optionalSize <= data.count else { throw PEError.truncated }

        let magic = try u16(data, optional)
        let is64: Bool
        switch magic {
        case 0x10B: is64 = false
        case 0x20B: is64 = true
        default: throw PEError.unsupportedOptionalHeader(magic)
        }

        let architecture: PEArchitecture
        switch machine {
        case 0x014C: architecture = .x86
        case 0x8664: architecture = .x64
        case 0xAA64: architecture = .arm64
        default: architecture = .unknown
        }

        let entryPoint = try u32(data, optional + 16)
        let imageBase: UInt64 = is64 ? try u64(data, optional + 24) : UInt64(try u32(data, optional + 28))
        let subsystemOffset = optional + (is64 ? 68 : 68)
        let subsystemValue = try u16(data, subsystemOffset)
        let subsystem: PESubsystem
        switch subsystemValue {
        case 1: subsystem = .native
        case 2: subsystem = .windowsGUI
        case 3: subsystem = .windowsCUI
        default: subsystem = .unknown
        }

        let sectionTable = optional + optionalSize
        guard sectionCount >= 0, sectionCount <= 96 else { throw PEError.invalidSectionCount }
        guard sectionTable + sectionCount * 40 <= data.count else { throw PEError.truncated }

        var sections: [PESection] = []
        sections.reserveCapacity(sectionCount)
        for index in 0..<sectionCount {
            let base = sectionTable + index * 40
            let nameBytes = data[base..<(base + 8)]
            let name = String(bytes: nameBytes.prefix { $0 != 0 }, encoding: .ascii) ?? "?"
            sections.append(PESection(
                name: name,
                virtualAddress: try u32(data, base + 12),
                virtualSize: try u32(data, base + 8),
                rawOffset: try u32(data, base + 20),
                rawSize: try u32(data, base + 16)
            ))
        }

        return PEInfo(
            architecture: architecture,
            subsystem: subsystem,
            entryPointRVA: entryPoint,
            imageBase: imageBase,
            isPE32Plus: is64,
            sections: sections
        )
    }

    static func fileOffset(forRVA rva: UInt32, info: PEInfo, dataCount: Int) throws -> Int {
        for section in info.sections {
            let span = max(section.virtualSize, section.rawSize)
            guard rva >= section.virtualAddress, rva < section.virtualAddress &+ span else { continue }
            let delta = rva - section.virtualAddress
            guard delta < section.rawSize else { throw PEError.rvaOutsideRawData }
            let offset = UInt64(section.rawOffset) + UInt64(delta)
            guard offset < UInt64(dataCount) else { throw PEError.truncated }
            return Int(offset)
        }
        throw PEError.entryPointNotMapped
    }

    private static func u16(_ data: Data, _ offset: Int) throws -> UInt16 {
        guard offset >= 0, offset + 2 <= data.count else { throw PEError.truncated }
        return UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func u32(_ data: Data, _ offset: Int) throws -> UInt32 {
        guard offset >= 0, offset + 4 <= data.count else { throw PEError.truncated }
        return UInt32(data[offset]) |
            (UInt32(data[offset + 1]) << 8) |
            (UInt32(data[offset + 2]) << 16) |
            (UInt32(data[offset + 3]) << 24)
    }

    private static func u64(_ data: Data, _ offset: Int) throws -> UInt64 {
        let lo = UInt64(try u32(data, offset))
        let hi = UInt64(try u32(data, offset + 4))
        return lo | (hi << 32)
    }

    enum PEError: LocalizedError {
        case tooSmall
        case notMZ
        case invalidPEOffset
        case notPE
        case truncated
        case unsupportedOptionalHeader(UInt16)
        case invalidSectionCount
        case entryPointNotMapped
        case rvaOutsideRawData

        var errorDescription: String? {
            switch self {
            case .tooSmall: return "The file is too small to be a Windows executable."
            case .notMZ: return "This file does not have a valid Windows MZ header."
            case .invalidPEOffset: return "The Windows PE header offset is invalid."
            case .notPE: return "This file does not contain a valid PE header."
            case .truncated: return "The Windows executable is truncated or malformed."
            case .unsupportedOptionalHeader(let value): return String(format: "Unsupported PE optional header 0x%04X.", value)
            case .invalidSectionCount: return "The PE section table is invalid."
            case .entryPointNotMapped: return "The Windows entry point is not mapped to a file section."
            case .rvaOutsideRawData: return "The entry point points outside the executable's stored section data."
            }
        }
    }
}
