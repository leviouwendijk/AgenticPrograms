import AgenticRecovery

public protocol ProgramFailure:
    Error,
    Sendable
{
    var recovery: Recovery.Record? { get }
}

public extension ProgramFailure {
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

public enum ProgramFailureDisposition<
    Output: Sendable
>: Sendable {
    case recover(Output)
    case propagate
}

public typealias ProgramFailureHandler<
    Failure: ProgramFailure,
    Output
> = @Sendable (Failure) async throws -> Output

public typealias ProgramFailureDispositionHandler<
    Failure: ProgramFailure,
    Output: Sendable
> = @Sendable (Failure) async throws
    -> ProgramFailureDisposition<Output>
