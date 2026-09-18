import Agentic
import Foundation

public enum ProgramInferenceInvocationError:
    Error,
    Sendable,
    LocalizedError
{
    case programMismatch(
        site: InferenceSiteIdentifier,
        expected: ProgramIdentifier,
        received: ProgramIdentifier
    )
    case bindingUnavailable(
        site: InferenceSiteIdentifier,
        inference: InferenceIdentifier
    )

    public var errorDescription: String? {
        switch self {
        case .programMismatch(
            let site,
            let expected,
            let received
        ):
            return "Inference site '\(site.rawValue)' belongs to Program '\(received.rawValue)' but the invoker is bound to '\(expected.rawValue)'."

        case .bindingUnavailable(
            let site,
            let inference
        ):
            return "No inference realization is bound at site '\(site.rawValue)' for inference '\(inference.rawValue)'."
        }
    }
}
