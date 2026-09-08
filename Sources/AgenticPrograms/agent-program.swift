public struct AgentProgramDescriptor:
    Sendable,
    Codable,
    Hashable
{
    public var identifier: AgentProgramIdentifier
    public var title: String
    public var summary: String
    public var version: String?
    public var requirements: AgentProgramRequirements
    public var tags: [String]
    public var metadata: [String: String]

    public init(
        identifier: AgentProgramIdentifier,
        title: String,
        summary: String,
        version: String? = nil,
        requirements: AgentProgramRequirements = .none,
        tags: [String] = [],
        metadata: [String: String] = [:]
    ) {
        self.identifier = identifier
        self.title = title
        self.summary = summary
        self.version = version
        self.requirements = requirements
        self.tags = tags
        self.metadata = metadata
    }
}

public protocol AgentProgram<Input, Output>: Sendable {
    associatedtype Input:
        Sendable &
        Codable

    associatedtype Output:
        Sendable &
        Codable

    static var descriptor: AgentProgramDescriptor { get }

    func run(
        _ input: Input,
        in context: AgentProgramContext
    ) async throws -> Output
}
