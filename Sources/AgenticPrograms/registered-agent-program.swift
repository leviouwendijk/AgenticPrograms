import Agentic
import Primitives

/// Registry-facing executable representation of one typed AgentProgram.
///
/// Registration captures the concrete Program/Input/Output types once. Dynamic
/// registry storage thereafter operates on JSONValue only at this explicit
/// lowering boundary while authored AgentProgram implementations remain typed.
public struct RegisteredAgentProgram: Sendable {
    public let descriptor: AgentProgramDescriptor

    private let runHandler:
        @Sendable (
            JSONValue,
            AgentProgramContext
        ) async throws -> JSONValue

    public init<Program: AgentProgram>(
        _ program: Program
    ) {
        self.descriptor = Program.descriptor
        self.runHandler = { input, context in
            let decoded = try JSONToolBridge.decode(
                Program.Input.self,
                from: input
            )
            let output = try await program.run(
                decoded,
                in: context
            )

            return try JSONToolBridge.encode(
                output
            )
        }
    }

    public var identifier: AgentProgramIdentifier {
        descriptor.identifier
    }

    public func run(
        input: JSONValue,
        in context: AgentProgramContext
    ) async throws -> JSONValue {
        try await runHandler(
            input,
            context
        )
    }
}
