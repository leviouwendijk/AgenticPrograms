import Agentic
import AgenticRecovery
import Foundation

public struct AgentProgramToolFailure:
    AgentProgramFailure,
    LocalizedError
{
    public typealias Handling<Output: Sendable> =
        AgentProgramFailureDisposition<Output>

    public let tool: AgentToolIdentifier
    public let result: AgentToolResult
    public let recovery: Recovery.Record?

    public init(
        tool: AgentToolIdentifier,
        result: AgentToolResult,
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

// Keep Handling as the small semantic substrate if a declarative recovery DSL
// is added later. Matched DSL clauses can lower to .recover and an unmatched
// failure can lower to .propagate without changing AgentProgramContext.invoke.
