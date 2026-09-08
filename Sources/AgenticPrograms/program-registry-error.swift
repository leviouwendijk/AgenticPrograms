import Foundation

public enum ProgramRegistryError:
    Error,
    Sendable,
    LocalizedError
{
    case duplicateProgram(String)
    case unknownProgram(String)

    public var errorDescription: String? {
        switch self {
        case .duplicateProgram(let identifier):
            return "A program with id '\(identifier)' is already registered."

        case .unknownProgram(let identifier):
            return "Unknown program: \(identifier)"
        }
    }
}
