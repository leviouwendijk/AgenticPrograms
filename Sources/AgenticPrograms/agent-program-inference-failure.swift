import AgenticInference
import AgenticRecovery
import Foundation

public struct AgentProgramInferenceFailure:
    AgentProgramFailure,
    LocalizedError
{
    private enum Evidence: Sendable {
        case execution(AgentInferenceExecutionFailure)
        case fallback(
            recovery: Recovery.Record?,
            message: String
        )
    }

    public typealias Handling<Output: Sendable> =
        AgentProgramFailureDisposition<Output>

    public let site: AgentInferenceSiteIdentifier
    public let inference: AgentInferenceIdentifier
    private let evidence: Evidence

    public init(
        site: AgentInferenceSiteIdentifier,
        inference: AgentInferenceIdentifier,
        execution: AgentInferenceExecutionFailure
    ) {
        self.site = site
        self.inference = inference
        self.evidence = .execution(execution)
    }

    public init(
        site: AgentInferenceSiteIdentifier,
        inference: AgentInferenceIdentifier,
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

    public var execution: AgentInferenceExecutionFailure? {
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
