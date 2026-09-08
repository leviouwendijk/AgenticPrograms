public struct AgentInferenceRealizationBinding:
    Sendable,
    Codable,
    Hashable
{
    public var site: AgentInferenceSiteIdentifier
    public var inference: AgentInferenceIdentifier
    public var realization: AgentInferenceRealization

    public init(
        site: AgentInferenceSiteIdentifier,
        inference: AgentInferenceIdentifier,
        realization: AgentInferenceRealization
    ) {
        self.site = site
        self.inference = inference
        self.realization = realization
    }
}

public struct AgentProgramRealization<Program: AgentProgram>:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public var id: AgentProgramRealizationIdentifier
    public var inferences: [AgentInferenceRealizationBinding]
    public var metadata: [String: String]

    public init(
        id: AgentProgramRealizationIdentifier,
        inferences: [AgentInferenceRealizationBinding] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.inferences = inferences
        self.metadata = metadata
    }

    public var programIdentifier: AgentProgramIdentifier {
        Program.descriptor.identifier
    }

    public func inference(
        at site: AgentInferenceSiteIdentifier
    ) -> AgentInferenceRealizationBinding? {
        inferences.first {
            $0.site == site
        }
    }

    public func realization(
        at site: AgentInferenceSiteIdentifier
    ) -> AgentInferenceRealization? {
        inference(
            at: site
        )?.realization
    }
}
