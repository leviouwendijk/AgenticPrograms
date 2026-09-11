import AgenticInference

public struct AgentProgramRealization<Program: AgentProgram>:
    Sendable,
    Codable,
    Hashable,
    Identifiable
{
    public var id: AgentProgramRealizationIdentifier
    public var inferences: AgentProgramInferenceBindings
    public var metadata: [String: String]

    public init(
        id: AgentProgramRealizationIdentifier,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.inferences = .empty
        self.metadata = metadata
    }

    public init(
        id: AgentProgramRealizationIdentifier,
        inferences: AgentProgramInferenceBindings,
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
        inferences[site]
    }

    public func realization(
        at site: AgentInferenceSiteIdentifier
    ) -> AgentInferenceRealization? {
        inference(
            at: site
        )?.realization
    }
}
