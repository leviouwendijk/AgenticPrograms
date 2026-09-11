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
    ]
}

enum AgenticProgramsFlowTesting {}
