import TestFlows

@main
enum ProgramsFlowTestMain {
    static func main() async {
        await TestFlowCLI.run(
            suite: ProgramsFlowSuite.self
        )
    }
}

enum ProgramsFlowSuite: TestFlowRegistry {
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
            try await ProgramsFlowTesting
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
            try await ProgramsFlowTesting
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
            try await ProgramsFlowTesting
                .runProgramInferenceBridge()
        },
        TestFlow(
            "select-next-action",
            tags: [
                "agentic-programs",
                "program",
                "inference",
                "decision",
                "composition",
            ]
        ) {
            try await ProgramsFlowTesting
                .runSelectNextAction()
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
            try await ProgramsFlowTesting
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
            try await ProgramsFlowTesting
                .runReviewedActionSelection()
        },
        TestFlow(
            "program-realization-parsing",
            tags: [
                "agentic-programs",
                "program",
                "inference",
                "realization",
                "parsing",
                "codable",
            ]
        ) {
            try await ProgramsFlowTesting
                .runProgramRealizationParsing()
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
            try await ProgramsFlowTesting
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
            try await ProgramsFlowTesting
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
            try await ProgramsFlowTesting
                .runProgramInferenceFailureHandling()
        },
    ]
}

enum ProgramsFlowTesting {}
