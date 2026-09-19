import Agentic
import AgenticPrograms
import TestFlows

private struct NestedProgramInput:
    SemanticInput,
    Equatable
{
    let value: String
}

private struct NestedProgramOutput:
    SemanticOutput,
    Equatable
{
    let value: String
    let inheritedScope: String?
}

@Program
private struct NestedChild {
    typealias Input = NestedProgramInput
    typealias Output = NestedProgramOutput

    static let purpose =
        "Fixture child program used to prove nested program invocation."

    func run(
        _ input: Input,
        in context: ProgramContext
    ) async throws -> Output {
        Output(
            value: input.value.uppercased(),
            inheritedScope: context.metadata["scope"]
        )
    }
}

@Program
private struct NestedParent {
    typealias Input = NestedProgramInput
    typealias Output = NestedProgramOutput

    static let purpose =
        "Fixture parent program that composes another registered program."

    func run(
        _ input: Input,
        in context: ProgramContext
    ) async throws -> Output {
        let child = try await context.run(
            NestedChild.self,
            input: input
        )

        return Output(
            value: "parent:\(child.value)",
            inheritedScope: child.inheritedScope
        )
    }
}

extension ProgramsFlowTesting {
    static func runNestedProgramComposition()
        async throws
        -> [TestFlowDiagnostic]
    {
        var registry = ProgramRegistry()

        try registry.register(
            NestedChild()
        )
        try registry.register(
            NestedParent()
        )

        let context = ProgramContext(
            programs: registry,
            metadata: [
                "scope": "preserved",
            ]
        )

        let output = try await registry.run(
            NestedParent.self,
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
                NestedParent.definition.identifier.rawValue
            ),
            .field(
                "child",
                NestedChild.definition.identifier.rawValue
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
