import AgenticInference
import AgenticRecovery
import Foundation

public struct AgentProgramInferenceFailure:
    AgentProgramFailure,
    LocalizedError
{
    public typealias Handling<Output: Sendable> =
        AgentProgramFailureDisposition<Output>

    public let site: AgentInferenceSiteIdentifier
    public let inference: AgentInferenceIdentifier
    public let recovery: Recovery.Record?
    public let message: String

    public init(
        site: AgentInferenceSiteIdentifier,
        inference: AgentInferenceIdentifier,
        recovery: Recovery.Record? = nil,
        message: String
    ) {
        self.site = site
        self.inference = inference
        self.recovery = recovery
        self.message = message
    }

    public var errorDescription: String? {
        "Program inference '\(inference.rawValue)' at site '\(site.rawValue)' failed: \(message)"
    }
}
