import Agentic
import Primitives

public struct ProgramRegistry: Sendable {
    private var programs:
        [ProgramIdentifier: RegisteredProgram]

    public init() {
        self.programs = [:]
    }

    public var definitions: [ProgramDefinition] {
        programs.values
            .map(\.definition)
            .sorted { lhs, rhs in
                let left =
                    lhs.title
                    ?? lhs.identifier.rawValue
                let right =
                    rhs.title
                    ?? rhs.identifier.rawValue

                if left == right {
                    return lhs.identifier.rawValue
                        < rhs.identifier.rawValue
                }

                return left < right
            }
    }

    public var isEmpty: Bool {
        programs.isEmpty
    }

    public var count: Int {
        programs.count
    }

    public mutating func register<
        ProgramType: Program
    >(
        _ program: ProgramType
    ) throws {
        try register(
            RegisteredProgram(
                program
            )
        )
    }

    public mutating func register(
        _ registered: RegisteredProgram
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
        _ programSet: any ProgramSet
    ) throws {
        try programSet.register(
            into: &self
        )
    }

    public mutating func register(
        from provider: any ProgramProvider
    ) throws {
        try provider.registerPrograms(
            into: &self
        )
    }

    public func registeredProgram(
        identifiedBy identifier: ProgramIdentifier
    ) -> RegisteredProgram? {
        programs[identifier]
    }

    public func registeredProgram(
        named name: String
    ) -> RegisteredProgram? {
        registeredProgram(
            identifiedBy: .init(
                rawValue: name
            )
        )
    }

    public func requireProgram(
        identifiedBy identifier: ProgramIdentifier
    ) throws -> RegisteredProgram {
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
        identifiedBy identifier: ProgramIdentifier,
        input: JSONValue,
        in context: ProgramContext
    ) async throws -> JSONValue {
        let program = try requireProgram(
            identifiedBy: identifier
        )

        return try await program.run(
            input: input,
            in: context
        )
    }

    public func run<
        ProgramType: Program
    >(
        _ program: ProgramType.Type,
        input: ProgramType.Input,
        in context: ProgramContext
    ) async throws -> ProgramType.Output {
        let encodedInput = try JSONValueCodec.encodeValue(
            input
        )
        let encodedOutput = try await run(
            identifiedBy: ProgramType.definition.identifier,
            input: encodedInput,
            in: context
        )

        return try encodedOutput.as(
            ProgramType.Output.self
        )
    }
}
