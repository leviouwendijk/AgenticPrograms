public struct AgentProgramInvocation<Program: AgentProgram>:
    Sendable,
    Codable
{
    public var input: Program.Input
    public var realization: AgentProgramRealization<Program>?
    public var metadata: [String: String]

    public init(
        input: Program.Input,
        realization: AgentProgramRealization<Program>? = nil,
        metadata: [String: String] = [:]
    ) {
        self.input = input
        self.realization = realization
        self.metadata = metadata
    }

    public var programIdentifier: AgentProgramIdentifier {
        Program.descriptor.identifier
    }
}

public struct AgentProgramResult<Program: AgentProgram>:
    Sendable,
    Codable
{
    public var output: Program.Output
    public var realization: AgentProgramRealization<Program>?
    public var metadata: [String: String]

    public init(
        output: Program.Output,
        realization: AgentProgramRealization<Program>? = nil,
        metadata: [String: String] = [:]
    ) {
        self.output = output
        self.realization = realization
        self.metadata = metadata
    }

    public var programIdentifier: AgentProgramIdentifier {
        Program.descriptor.identifier
    }
}
