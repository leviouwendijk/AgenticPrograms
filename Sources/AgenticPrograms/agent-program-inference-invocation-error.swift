import AgenticInference
import Foundation

public enum AgentProgramInferenceInvocationError:
    Error,
    Sendable,
    LocalizedError
{
    case bindingUnavailable(
        site: AgentInferenceSiteIdentifier,
        inference: AgentInferenceIdentifier
    )
    case inferenceMismatch(
        site: AgentInferenceSiteIdentifier,
        expected: AgentInferenceIdentifier,
        bound: AgentInferenceIdentifier
    )

    public var errorDescription: String? {
        switch self {
        case .bindingUnavailable(
            let site,
            let inference
        ):
            return "No inference realization is bound at site '\(site.rawValue)' for inference '\(inference.rawValue)'."

        case .inferenceMismatch(
            let site,
            let expected,
            let bound
        ):
            return "Inference site '\(site.rawValue)' is bound to '\(bound.rawValue)' but '\(expected.rawValue)' was requested."
        }
    }
}
