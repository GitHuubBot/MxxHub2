import Foundation

struct X86ExecutionResult: Hashable {
    let eax: UInt32
    let instructionCount: Int
}

enum MiniX86Interpreter {
    /// Tiny correctness-first x86 interpreter used only for MexxBox runtime bring-up.
    /// It intentionally supports a very small instruction set. Portal/HL2 will need
    /// the future WineGlass/Box64 backend rather than this interpreter.
    static func executePE32(data: Data, info: PEInfo, instructionLimit: Int = 10_000) throws -> X86ExecutionResult {
        guard info.architecture == .x86, !info.isPE32Plus else {
            throw X86Error.requiresX86
        }

        var ip = try PEInspector.fileOffset(forRVA: info.entryPointRVA, info: info, dataCount: data.count)
        var eax: UInt32 = 0
        var executed = 0

        func require(_ count: Int) throws {
            guard ip >= 0, ip + count <= data.count else { throw X86Error.readPastEnd }
        }

        func imm32(at offset: Int) throws -> UInt32 {
            guard offset >= 0, offset + 4 <= data.count else { throw X86Error.readPastEnd }
            return UInt32(data[offset]) |
                (UInt32(data[offset + 1]) << 8) |
                (UInt32(data[offset + 2]) << 16) |
                (UInt32(data[offset + 3]) << 24)
        }

        while executed < instructionLimit {
            try require(1)
            let opcode = data[ip]
            executed += 1

            switch opcode {
            case 0x90: // NOP
                ip += 1

            case 0xB8: // MOV EAX, imm32
                try require(5)
                eax = try imm32(at: ip + 1)
                ip += 5

            case 0x05: // ADD EAX, imm32
                try require(5)
                eax &+= try imm32(at: ip + 1)
                ip += 5

            case 0x2D: // SUB EAX, imm32
                try require(5)
                eax &-= try imm32(at: ip + 1)
                ip += 5

            case 0x31: // XOR r/m32, r32 - only XOR EAX,EAX for bring-up
                try require(2)
                let modRM = data[ip + 1]
                guard modRM == 0xC0 else { throw X86Error.unsupportedModRM(opcode, modRM, ip) }
                eax = 0
                ip += 2

            case 0xEB: // JMP rel8
                try require(2)
                let displacement = Int(Int8(bitPattern: data[ip + 1]))
                ip = ip + 2 + displacement

            case 0xE9: // JMP rel32
                try require(5)
                let raw = try imm32(at: ip + 1)
                let displacement = Int(Int32(bitPattern: raw))
                ip = ip + 5 + displacement

            case 0xC3: // RET = successful end for the bring-up executable
                return X86ExecutionResult(eax: eax, instructionCount: executed)

            case 0xCC:
                throw X86Error.breakpoint(ip)

            default:
                throw X86Error.unsupportedOpcode(opcode, ip)
            }
        }

        throw X86Error.instructionLimit
    }

    enum X86Error: LocalizedError {
        case requiresX86
        case readPastEnd
        case unsupportedOpcode(UInt8, Int)
        case unsupportedModRM(UInt8, UInt8, Int)
        case breakpoint(Int)
        case instructionLimit

        var errorDescription: String? {
            switch self {
            case .requiresX86:
                return "The built-in v0.2 test runtime currently executes PE32 x86 code only."
            case .readPastEnd:
                return "The x86 interpreter tried to read past the end of the executable."
            case .unsupportedOpcode(let op, let offset):
                return String(format: "Windows PE loaded successfully, but v0.2 stopped at unsupported x86 opcode 0x%02X (file offset 0x%X). This is expected for real games until the WineGlass/Box64 backend is integrated.", op, offset)
            case .unsupportedModRM(let op, let modRM, let offset):
                return String(format: "PE loaded, but x86 instruction 0x%02X / ModRM 0x%02X at 0x%X is not in the tiny v0.2 interpreter yet.", op, modRM, offset)
            case .breakpoint(let offset):
                return String(format: "The executable hit an INT3 breakpoint at file offset 0x%X.", offset)
            case .instructionLimit:
                return "The v0.2 x86 safety instruction limit was reached."
            }
        }
    }
}
