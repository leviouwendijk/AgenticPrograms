import TestFlows

@main
enum AgenticProgramsFlowTestMain {
    static func main() async {
        await TestFlowCLI.run(
            suite: AgenticProgramsFlowSuite.self
        )
    }
}

enum AgenticProgramsFlowSuite: TestFlowRegistry {
    static let title = "AgenticPrograms flow tests"

    static let flows: [TestFlow] = [
        TestFlow(
            "program-registry",
            tags: [
                "agentic-programs",
                "program",
                "registry",
                "type-erasure",
            ]
        ) {
            try await AgenticProgramsFlowTesting
                .runProgramRegistry()
        },
        TestFlow(
            "program-registration-composition",
            tags: [
                "agentic-programs",
                "program",
                "provider",
                "set",
                "registration",
            ]
        ) {
            try await AgenticProgramsFlowTesting
                .runProgramRegistrationComposition()
        },
        TestFlow(
            "program-inference-bridge",
            tags: [
                "agentic-programs",
                "inference",
                "realization",
                "site",
                "execution",
            ]
        ) {
            try await AgenticProgramsFlowTesting
                .runProgramInferenceBridge()
        },
        TestFlow(
            "determine-next-action-program",
            tags: [
                "agentic-programs",
                "program",
                "inference",
                "decision",
                "composition",
            ]
        ) {
            try await AgenticProgramsFlowTesting
                .runDetermineNextActionProgram()
        },
        TestFlow(
            "nested-program-composition",
            tags: [
                "agentic-programs",
                "program",
                "composition",
                "registry",
                "nested",
            ]
        ) {
            try await AgenticProgramsFlowTesting
                .runNestedProgramComposition()
        },
        TestFlow(
            "reviewed-action-selection",
            tags: [
                "agentic-programs",
                "program",
                "inference",
                "multi-stage",
                "decision",
                "assessment",
            ]
        ) {
            try await AgenticProgramsFlowTesting
                .runReviewedActionSelection()
        },
        TestFlow(
            "program-inference-binding-parsing",
            tags: [
                "agentic-programs",
                "program",
                "inference",
                "realization",
                "parsing",
                "codable",
            ]
        ) {
            try await AgenticProgramsFlowTesting
                .runProgramInferenceBindingParsing()
        },
        TestFlow(
            "program-user-input-context",
            tags: [
                "agentic-programs",
                "program",
                "user-input",
                "interaction",
                "context",
            ]
        ) {
            try await AgenticProgramsFlowTesting
                .runProgramUserInputContext()
        },
        TestFlow(
            "program-tool-failure-handling",
            tags: [
                "agentic-programs",
                "program",
                "tool",
                "failure",
                "recovery",
                "handling",
            ]
        ) {
            try await AgenticProgramsFlowTesting
                .runProgramToolFailureHandling()
        },
        TestFlow(
            "program-inference-failure-handling",
            tags: [
                "agentic-programs",
                "program",
                "inference",
                "failure",
                "recovery",
                "handling",
            ]
        ) {
            try await AgenticProgramsFlowTesting
                .runProgramInferenceFailureHandling()
        },
    ]
}

enum AgenticProgramsFlowTesting {}
