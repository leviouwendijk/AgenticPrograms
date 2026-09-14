import AgenticRecovery

public protocol AgentProgramFailure:
    Error,
    Sendable
{
    var recovery: Recovery.Record? { get }
}

public extension AgentProgramFailure {
    var state: Recovery.State? {
        recovery?.state
    }

    var effect: Recovery.EffectState? {
        state?.effect
    }

    var retry: Recovery.RetrySafety? {
        state?.retry
    }

    var outcome: Recovery.Outcome? {
        recovery?.outcome
    }
}

public enum AgentProgramFailureDisposition<
    Output: Sendable
>: Sendable {
    case recover(Output)
    case propagate
}

public typealias AgentProgramFailureHandler<
    Failure: AgentProgramFailure,
    Output
> = @Sendable (Failure) async throws -> Output

public typealias AgentProgramFailureDispositionHandler<
    Failure: AgentProgramFailure,
    Output: Sendable
> = @Sendable (Failure) async throws
    -> AgentProgramFailureDisposition<Output>
