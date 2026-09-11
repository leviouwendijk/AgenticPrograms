import AgenticPrograms
import TestFlows

private struct NestedProgramInput:
    Sendable,
    Codable,
    Equatable
{
    let value: String
}

private struct NestedProgramOutput:
    Sendable,
    Codable,
    Equatable
{
    let value: String
    let inheritedScope: String?
}

private struct NestedChildProgram: AgentProgram {
    typealias Input = NestedProgramInput
    typealias Output = NestedProgramOutput

    static let descriptor = AgentProgramDescriptor(
        identifier: "fixture.nested_child",
        title: "Nested Child",
        summary: "Fixture child program used to prove nested program invocation."
    )

    func run(
        _ input: Input,
        in context: AgentProgramContext
    ) async throws -> Output {
        Output(
            value: input.value.uppercased(),
            inheritedScope: context.metadata["scope"]
        )
    }
}

private struct NestedParentProgram: AgentProgram {
    typealias Input = NestedProgramInput
    typealias Output = NestedProgramOutput

    static let descriptor = AgentProgramDescriptor(
        identifier: "fixture.nested_parent",
        title: "Nested Parent",
        summary: "Fixture parent program that composes another registered program."
    )

    func run(
        _ input: Input,
        in context: AgentProgramContext
    ) async throws -> Output {
        let child = try await context.run(
            NestedChildProgram.self,
            input: input
        )

        return Output(
            value: "parent:\(child.value)",
            inheritedScope: child.inheritedScope
        )
    }
}

extension AgenticProgramsFlowTesting {
    static func runNestedProgramComposition()
        async throws
        -> [TestFlowDiagnostic]
    {
        var registry = ProgramRegistry()

        try registry.register(
            NestedChildProgram()
        )
        try registry.register(
            NestedParentProgram()
        )

        let context = AgentProgramContext(
            programs: registry,
            metadata: [
                "scope": "preserved",
            ]
        )

        let output = try await registry.run(
            NestedParentProgram.self,
            input: NestedProgramInput(
                value: "nested"
            ),
            in: context
        )

        try Expect.equal(
            output.value,
            "parent:NESTED",
            "parent program composes registered child program through context.run"
        )
        try Expect.equal(
            output.inheritedScope,
            "preserved",
            "nested program receives the same execution context metadata"
        )
        try Expect.equal(
            registry.count,
            2,
            "nested composition executes through the registered program set"
        )

        return [
            .field(
                "parent",
                NestedParentProgram.descriptor.identifier.rawValue
            ),
            .field(
                "child",
                NestedChildProgram.descriptor.identifier.rawValue
            ),
            .field(
                "output",
                output.value
            ),
            .field(
                "context_preserved",
                String(output.inheritedScope == "preserved")
            ),
        ]
    }
}
