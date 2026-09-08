import Agentic
import AgenticPrograms
import TestFlows

extension AgenticProgramsFlowTesting {
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
            EchoProgram()
        )

        try Expect.equal(
            registry.count,
            1,
            "program registry contains registered program"
        )
        try Expect.equal(
            registry.descriptors.map(\.identifier),
            [EchoProgram.descriptor.identifier],
            "program registry projects registered descriptors"
        )

        let typedOutput = try await registry.run(
            EchoProgram.self,
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
            identifiedBy: EchoProgram.descriptor.identifier
        )
        let erasedOutput = try await registered.run(
            input: try JSONToolBridge.encode(
                EchoInput(
                    value: "erased"
                )
            ),
            in: .init()
        )
        let decodedOutput = try JSONToolBridge.decode(
            EchoOutput.self,
            from: erasedOutput
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
                EchoProgram()
            )
        } catch ProgramRegistryError.duplicateProgram(let identifier) {
            duplicateIdentifier = identifier
        }

        try Expect.equal(
            duplicateIdentifier,
            EchoProgram.descriptor.identifier.rawValue,
            "program registry rejects duplicate identifiers"
        )

        var unknownIdentifier: String?

        do {
            _ = try registry.requireProgram(
                identifiedBy: "fixture.unknown"
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
            registry.descriptors.map(\.identifier),
            [
                EchoProgram.descriptor.identifier,
                UppercaseProgram.descriptor.identifier,
            ],
            "program descriptors are projected in stable title order"
        )

        let echo = try await registry.run(
            EchoProgram.self,
            input: .init(
                value: "set"
            ),
            in: .init()
        )
        let uppercase = try await registry.run(
            UppercaseProgram.self,
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
                registry.descriptors
                    .map(\.identifier.rawValue)
                    .joined(separator: ",")
            ),
        ]
    }
}

private struct EchoInput:
    Sendable,
    Codable,
    Hashable
{
    let value: String
}

private struct EchoOutput:
    Sendable,
    Codable,
    Hashable
{
    let value: String
}

private struct EchoProgram: AgentProgram {
    typealias Input = EchoInput
    typealias Output = EchoOutput

    static let descriptor = AgentProgramDescriptor(
        identifier: "fixture.echo",
        title: "Echo",
        summary: "Echo fixture program."
    )

    func run(
        _ input: EchoInput,
        in _: AgentProgramContext
    ) async throws -> EchoOutput {
        .init(
            value: "echo:\(input.value)"
        )
    }
}

private struct UppercaseProgram: AgentProgram {
    typealias Input = EchoInput
    typealias Output = EchoOutput

    static let descriptor = AgentProgramDescriptor(
        identifier: "fixture.uppercase",
        title: "Uppercase",
        summary: "Uppercase fixture program."
    )

    func run(
        _ input: EchoInput,
        in _: AgentProgramContext
    ) async throws -> EchoOutput {
        .init(
            value: input.value.uppercased()
        )
    }
}

private struct FixtureProgramSet: AgentProgramSet {
    func register(
        into registry: inout ProgramRegistry
    ) throws {
        try registry.register(
            EchoProgram()
        )
    }
}

private struct FixtureProgramProvider: AgentProgramProvider {
    func registerPrograms(
        into registry: inout ProgramRegistry
    ) throws {
        try registry.register(
            UppercaseProgram()
        )
    }
}
