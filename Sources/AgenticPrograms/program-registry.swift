import Agentic
import Primitives

public struct ProgramRegistry: Sendable {
    private var programs:
        [AgentProgramIdentifier: RegisteredAgentProgram]

    public init() {
        self.programs = [:]
    }

    public var descriptors: [AgentProgramDescriptor] {
        programs.values
            .map(\.descriptor)
            .sorted { lhs, rhs in
                if lhs.title == rhs.title {
                    return lhs.identifier.rawValue
                        < rhs.identifier.rawValue
                }

                return lhs.title < rhs.title
            }
    }

    public var isEmpty: Bool {
        programs.isEmpty
    }

    public var count: Int {
        programs.count
    }

    public mutating func register<Program: AgentProgram>(
        _ program: Program
    ) throws {
        try register(
            RegisteredAgentProgram(
                program
            )
        )
    }

    public mutating func register(
        _ registered: RegisteredAgentProgram
    ) throws {
        let identifier = registered.identifier

        guard programs[identifier] == nil else {
            throw ProgramRegistryError.duplicateProgram(
                identifier.rawValue
            )
        }

        programs[identifier] = registered
    }

    public mutating func register(
        _ programSet: any AgentProgramSet
    ) throws {
        try programSet.register(
            into: &self
        )
    }

    public mutating func register(
        from provider: any AgentProgramProvider
    ) throws {
        try provider.registerPrograms(
            into: &self
        )
    }

    public func registeredProgram(
        identifiedBy identifier: AgentProgramIdentifier
    ) -> RegisteredAgentProgram? {
        programs[identifier]
    }

    public func registeredProgram(
        named name: String
    ) -> RegisteredAgentProgram? {
        registeredProgram(
            identifiedBy: .init(
                name
            )
        )
    }

    public func requireProgram(
        identifiedBy identifier: AgentProgramIdentifier
    ) throws -> RegisteredAgentProgram {
        guard let program = registeredProgram(
            identifiedBy: identifier
        ) else {
            throw ProgramRegistryError.unknownProgram(
                identifier.rawValue
            )
        }

        return program
    }

    public func run(
        identifiedBy identifier: AgentProgramIdentifier,
        input: JSONValue,
        in context: AgentProgramContext
    ) async throws -> JSONValue {
        let program = try requireProgram(
            identifiedBy: identifier
        )

        return try await program.run(
            input: input,
            in: context
        )
    }

    public func run<Program: AgentProgram>(
        _ program: Program.Type,
        input: Program.Input,
        in context: AgentProgramContext
    ) async throws -> Program.Output {
        let encodedInput = try JSONToolBridge.encode(
            input
        )
        let encodedOutput = try await run(
            identifiedBy: Program.descriptor.identifier,
            input: encodedInput,
            in: context
        )

        return try JSONToolBridge.decode(
            Program.Output.self,
            from: encodedOutput
        )
    }
}
