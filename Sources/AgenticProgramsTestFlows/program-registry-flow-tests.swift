import Agentic
import AgenticPrograms
import Macros
import Primitives
import Schema
import TestFlows

extension ProgramsFlowTesting {
    static func runProgramRegistry()
        async throws
        -> [TestFlowDiagnostic]
    {
        var registry = ProgramRegistry()

        try Expect.equal(
            registry.isEmpty,
            true,
            "new program registry is empty"
        )

        try registry.register(
            Echo()
        )

        try Expect.equal(
            registry.count,
            1,
            "program registry contains registered program"
        )
        try Expect.equal(
            registry.definitions.map(\.identifier),
            [Echo.definition.identifier],
            "program registry projects canonical Program definitions"
        )

        let typedOutput = try await registry.run(
            Echo.self,
            input: .init(
                value: "typed"
            ),
            in: .init()
        )

        try Expect.equal(
            typedOutput,
            .init(
                value: "echo:typed"
            ),
            "typed program execution survives registry storage"
        )

        let registered = try registry.requireProgram(
            identifiedBy: Echo.definition.identifier
        )
        let erasedOutput = try await registered.run(
            input: try JSONValueCodec.encodeValue(
                EchoInput(
                    value: "erased"
                )
            ),
            in: .init()
        )
        let decodedOutput = try erasedOutput.as(
            EchoOutput.self
        )

        try Expect.equal(
            decodedOutput,
            .init(
                value: "echo:erased"
            ),
            "registered program lowers and restores typed values only at the registry boundary"
        )

        var duplicateIdentifier: String?

        do {
            try registry.register(
                Echo()
            )
        } catch ProgramRegistryError.duplicateProgram(let identifier) {
            duplicateIdentifier = identifier
        }

        try Expect.equal(
            duplicateIdentifier,
            Echo.definition.identifier.rawValue,
            "program registry rejects duplicate identifiers"
        )

        var unknownIdentifier: String?

        do {
            _ = try registry.requireProgram(
                identifiedBy: .init(
                    rawValue: "fixture.unknown"
                )
            )
        } catch ProgramRegistryError.unknownProgram(let identifier) {
            unknownIdentifier = identifier
        }

        try Expect.equal(
            unknownIdentifier,
            "fixture.unknown",
            "program registry reports unknown identifiers"
        )

        return [
            .field(
                "registered",
                String(registry.count)
            ),
            .field(
                "typed_output",
                typedOutput.value
            ),
            .field(
                "erased_output",
                decodedOutput.value
            ),
        ]
    }

    static func runProgramRegistrationComposition()
        async throws
        -> [TestFlowDiagnostic]
    {
        var registry = ProgramRegistry()

        try registry.register(
            FixtureProgramSet()
        )
        try registry.register(
            from: FixtureProgramProvider()
        )

        try Expect.equal(
            registry.count,
            2,
            "program set and provider compose into one registry"
        )
        try Expect.equal(
            registry.definitions.map(\.identifier),
            [
                Echo.definition.identifier,
                Uppercase.definition.identifier,
            ],
            "program definitions are projected in stable semantic order"
        )

        let echo = try await registry.run(
            Echo.self,
            input: .init(
                value: "set"
            ),
            in: .init()
        )
        let uppercase = try await registry.run(
            Uppercase.self,
            input: .init(
                value: "provider"
            ),
            in: .init()
        )

        try Expect.equal(
            echo.value,
            "echo:set",
            "program set registration remains executable"
        )
        try Expect.equal(
            uppercase.value,
            "PROVIDER",
            "program provider registration remains executable"
        )

        return [
            .field(
                "registered",
                String(registry.count)
            ),
            .field(
                "programs",
                registry.definitions
                    .map(\.identifier.rawValue)
                    .joined(separator: ",")
            ),
        ]
    }
}

@JSONSchema
private struct EchoInput:
    Source,
    Hashable
{
    let value: String
}

@JSONSchema
private struct EchoOutput:
    Result,
    Hashable
{
    let value: String
}

@Program
private struct Echo {
    typealias Input = EchoInput
    typealias Output = EchoOutput

    static let purpose =
        "Echo fixture program."

    func run(
        _ input: EchoInput,
        in _: ProgramContext
    ) async throws -> EchoOutput {
        .init(
            value: "echo:\(input.value)"
        )
    }
}

@Program
private struct Uppercase {
    typealias Input = EchoInput
    typealias Output = EchoOutput

    static let purpose =
        "Uppercase fixture program."

    func run(
        _ input: EchoInput,
        in _: ProgramContext
    ) async throws -> EchoOutput {
        .init(
            value: input.value.uppercased()
        )
    }
}

private struct FixtureProgramSet: ProgramSet {
    func register(
        into registry: inout ProgramRegistry
    ) throws {
        try registry.register(
            Echo()
        )
    }
}

private struct FixtureProgramProvider: ProgramProvider {
    func registerPrograms(
        into registry: inout ProgramRegistry
    ) throws {
        try registry.register(
            Uppercase()
        )
    }
}
