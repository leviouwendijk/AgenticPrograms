import Agentic
import AgenticRecovery
import Foundation

public struct ProgramToolFailure:
    ProgramFailure,
    LocalizedError
{
    public typealias Handling<Output: Sendable> =
        ProgramFailureDisposition<Output>

    public let tool: ToolIdentifier
    public let result: ToolResult
    public let recovery: Recovery.Record?

    public init(
        tool: ToolIdentifier,
        result: ToolResult,
        recovery: Recovery.Record? = nil
    ) {
        self.tool = tool
        self.result = result
        self.recovery = recovery
    }

    public var errorDescription: String? {
        "Program tool '\(tool.rawValue)' returned a failed tool result."
    }
}
