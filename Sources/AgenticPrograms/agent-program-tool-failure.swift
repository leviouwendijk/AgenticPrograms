import Agentic
import AgenticRecovery
import Foundation

public struct AgentProgramToolFailure:
    Error,
    Sendable,
    LocalizedError
{
    public enum Handling<Output: Sendable>: Sendable {
        case recover(Output)
        case propagate
    }

    public let tool: AgentToolIdentifier
    public let recovery: Recovery.Record?

    public init(
        tool: AgentToolIdentifier,
        recovery: Recovery.Record? = nil
    ) {
        self.tool = tool
        self.recovery = recovery
    }

    public var state: Recovery.State? {
        recovery?.state
    }

    public var effect: Recovery.EffectState? {
        state?.effect
    }

    public var retry: Recovery.RetrySafety? {
        state?.retry
    }

    public var outcome: Recovery.Outcome? {
        recovery?.outcome
    }

    public var errorDescription: String? {
        "Program tool '\(tool.rawValue)' returned a failed tool result."
    }
}

// Keep Handling as the small semantic substrate if a declarative recovery DSL
// is added later. Matched DSL clauses can lower to .recover and an unmatched
// failure can lower to .propagate without changing AgentProgramContext.invoke.
