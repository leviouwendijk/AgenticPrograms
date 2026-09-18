import Agentic
import AgenticInference
import AgenticRecovery
import Foundation

public struct ProgramInferenceFailure:
    ProgramFailure,
    LocalizedError
{
    private enum Evidence: Sendable {
        case execution(InferenceExecutionFailure)
        case fallback(
            recovery: Recovery.Record?,
            message: String
        )
    }

    public typealias Handling<Output: Sendable> =
        ProgramFailureDisposition<Output>

    public let site: InferenceSiteIdentifier
    public let inference: InferenceIdentifier
    private let evidence: Evidence

    public init(
        site: InferenceSiteIdentifier,
        inference: InferenceIdentifier,
        execution: InferenceExecutionFailure
    ) {
        self.site = site
        self.inference = inference
        self.evidence = .execution(execution)
    }

    public init(
        site: InferenceSiteIdentifier,
        inference: InferenceIdentifier,
        recovery: Recovery.Record? = nil,
        message: String
    ) {
        self.site = site
        self.inference = inference
        self.evidence = .fallback(
            recovery: recovery,
            message: message
        )
    }

    public var execution: InferenceExecutionFailure? {
        switch evidence {
        case .execution(let execution):
            return execution

        case .fallback:
            return nil
        }
    }

    public var recovery: Recovery.Record? {
        switch evidence {
        case .execution(let execution):
            return execution.recovery

        case .fallback(let recovery, _):
            return recovery
        }
    }

    public var message: String {
        switch evidence {
        case .execution(let execution):
            return execution.failure.message

        case .fallback(_, let message):
            return message
        }
    }

    public var errorDescription: String? {
        "Program inference '\(inference.rawValue)' at site '\(site.rawValue)' failed: \(message)"
    }
}
