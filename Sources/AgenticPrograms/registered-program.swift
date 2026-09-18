import Agentic
import Primitives

/// Registry-facing executable representation of one typed Program.
///
/// Registration captures the concrete Program/Input/Output types once. Dynamic
/// registry storage thereafter operates on JSONValue only at this explicit
/// lowering boundary while authored Programs remain typed.
public struct RegisteredProgram: Sendable {
    public let definition: ProgramDefinition

    private let runHandler:
        @Sendable (
            JSONValue,
            ProgramContext
        ) async throws -> JSONValue

    public init<ProgramType: ExecutableProgram>(
        _ program: ProgramType
    ) {
        self.definition = ProgramType.definition
        self.runHandler = { input, context in
            let decoded = try input.as(
                ProgramType.Input.self
            )
            let output = try await program.run(
                decoded,
                in: context
            )

            return try JSONValueCodec.encodeValue(
                output
            )
        }
    }

    public var identifier: ProgramIdentifier {
        definition.identifier
    }

    public func run(
        input: JSONValue,
        in context: ProgramContext
    ) async throws -> JSONValue {
        try await runHandler(
            input,
            context
        )
    }
}
