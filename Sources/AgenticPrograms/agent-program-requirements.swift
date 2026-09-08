import Agentic

public struct AgentProgramRequirements:
    Sendable,
    Codable,
    Hashable
{
    public var toolIdentifiers: [AgentToolIdentifier]
    public var skillIdentifiers: [AgentSkillIdentifier]
    public var programIdentifiers: [AgentProgramIdentifier]
    public var modelCapabilities: [AgentModelCapability]
    public var routePurposes: [AgentModelRoutePurpose]

    public init(
        toolIdentifiers: [AgentToolIdentifier] = [],
        skillIdentifiers: [AgentSkillIdentifier] = [],
        programIdentifiers: [AgentProgramIdentifier] = [],
        modelCapabilities: [AgentModelCapability] = [],
        routePurposes: [AgentModelRoutePurpose] = []
    ) {
        self.toolIdentifiers = toolIdentifiers
        self.skillIdentifiers = skillIdentifiers
        self.programIdentifiers = programIdentifiers
        self.modelCapabilities = modelCapabilities
        self.routePurposes = routePurposes
    }

    public static let none = Self()
}
