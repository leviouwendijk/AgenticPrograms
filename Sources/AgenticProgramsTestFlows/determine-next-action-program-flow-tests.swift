import AgenticInference
import AgenticPrograms
import Foundation
import TestFlows

private struct DetermineNextActionExecutionObservation: Sendable {
    let inference: AgentInferenceIdentifier
    let strategy: AgentInferenceStrategyIdentifier
}

private actor DetermineNextActionExecutionRecorder {
    private var observations: [DetermineNextActionExecutionObservation] = []

    func append(
        _ observation: DetermineNextActionExecutionObservation
    ) {
        observations.append(
            observation
        )
    }

    func snapshot() -> [DetermineNextActionExecutionObservation] {
        observations
    }
}

private struct DetermineNextActionFixtureExecutor:
    AgentInferenceExecuting,
    Sendable
{
    let selectedActionIdentifier: String
    let recorder: DetermineNextActionExecutionRecorder

    func execute<Inference: AgentInference>(
        _ inference: Inference.Type,
        input: Inference.Input,
        realization: AgentInferenceRealization
    ) async throws -> AgentInferenceExecutionResult<Inference.Output> {
        await recorder.append(
            DetermineNextActionExecutionObservation(
                inference: inference.definition.identifier,
                strategy: realization.strategy
            )
        )

        let encoded = try JSONEncoder().encode(
            DetermineNextAction.Output(
                selectedActionIdentifier: selectedActionIdentifier
            )
        )
        let output = try JSONDecoder().decode(
            Inference.Output.self,
            from: encoded
        )

        return AgentInferenceExecutionResult(
            output: output,
            record: AgentInferenceExecutionRecord(
                inference: inference.definition.identifier,
                strategy: realization.strategy,
                metadata: [
                    "fixture": "determine_next_action_program",
                ]
            )
        )
    }
}

extension AgenticProgramsFlowTesting {
    static func runDetermineNextActionProgram()
        async throws
        -> [TestFlowDiagnostic]
    {
        let input = DetermineNextAction.Input(
            goal: "Finish publishing the completed change.",
            state: "Implementation and tests are complete.",
            candidates: [
                .init(
                    identifier: "review",
                    description: "Review the completed changes."
                ),
                .init(
                    identifier: "publish",
                    description: "Publish the completed changes."
                ),
            ]
        )
        let boundRealization = AgentInferenceRealization(
            strategy: .native_reasoning,
            modelSelection: .executor,
            instructions: "Select the best next candidate.",
            budget: .singleAttempt,
            adapter: "fixture_adapter"
        )

        let recorder = DetermineNextActionExecutionRecorder()
        let executor = DetermineNextActionFixtureExecutor(
            selectedActionIdentifier: "publish",
            recorder: recorder
        )
        let realization = AgentProgramRealization<DetermineNextActionProgram>(
            id: "fixture.select_next_action",
            inferences: try AgentProgramInferenceBindings(
                [
                    AgentInferenceRealizationBinding(
                        site: DetermineNextActionProgram.inferenceSite,
                        inference: DetermineNextAction.definition.identifier,
                        realization: boundRealization
                    ),
                ]
            )
        )
        let inferenceInvoker = AgentProgramInferenceInvoker(
            realization: realization,
            executor: executor
        )
        let context = AgentProgramContext(
            inference: inferenceInvoker
        )

        let selected = try await DetermineNextActionProgram().run(
            input,
            in: context
        )
        let observations = await recorder.snapshot()

        try Expect.equal(
            selected.identifier,
            "publish",
            "program resolves model selection to the exact supplied candidate"
        )
        try Expect.equal(
            selected.description,
            "Publish the completed changes.",
            "program preserves deterministic candidate data after inference"
        )
        try Expect.equal(
            observations.count,
            1,
            "program performs exactly one semantic inference"
        )
        try Expect.equal(
            observations[0].inference,
            DetermineNextAction.definition.identifier,
            "program invokes DetermineNextAction rather than embedding decision semantics"
        )
        try Expect.equal(
            observations[0].strategy,
            .native_reasoning,
            "program inference site uses its bound realization"
        )

        let invalidRecorder = DetermineNextActionExecutionRecorder()
        let invalidExecutor = DetermineNextActionFixtureExecutor(
            selectedActionIdentifier: "invented_action",
            recorder: invalidRecorder
        )
        let invalidInvoker = AgentProgramInferenceInvoker(
            realization: realization,
            executor: invalidExecutor
        )
        let invalidContext = AgentProgramContext(
            inference: invalidInvoker
        )

        var unavailableIdentifier: String?

        do {
            _ = try await DetermineNextActionProgram().run(
                input,
                in: invalidContext
            )
        } catch DetermineNextActionProgramError.selectedActionUnavailable(
            let identifier
        ) {
            unavailableIdentifier = identifier
        }

        try Expect.equal(
            unavailableIdentifier,
            "invented_action",
            "program rejects inferred identifiers outside the supplied candidate set"
        )

        return [
            .field(
                "program",
                DetermineNextActionProgram.descriptor.identifier.rawValue
            ),
            .field(
                "inference",
                observations[0].inference.rawValue
            ),
            .field(
                "selected",
                selected.identifier
            ),
            .field(
                "strategy",
                observations[0].strategy.rawValue
            ),
            .field(
                "invalid_selection_rejected",
                String(unavailableIdentifier != nil)
            ),
        ]
    }
}
