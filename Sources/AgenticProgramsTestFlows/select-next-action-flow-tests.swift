import Agentic
import AgenticInference
import AgenticPrograms
import Foundation
import TestFlows

private struct SelectNextActionExecutionObservation: Sendable {
    let inference: InferenceIdentifier
    let strategy: InferenceStrategyIdentifier
}

private actor SelectNextActionExecutionRecorder {
    private var observations: [SelectNextActionExecutionObservation] = []

    func append(
        _ observation: SelectNextActionExecutionObservation
    ) {
        observations.append(
            observation
        )
    }

    func snapshot() -> [SelectNextActionExecutionObservation] {
        observations
    }
}

private struct SelectNextActionFixtureExecutor:
    InferenceExecuting,
    Sendable
{
    let selectedActionIdentifier: String
    let recorder: SelectNextActionExecutionRecorder

    func execute(
        _ invocation: InferenceInvocation
    ) async throws -> InferenceInvocationResult {
        await recorder.append(
            SelectNextActionExecutionObservation(
                inference: invocation.definition.identifier,
                strategy: invocation.realization.strategy
            )
        )

        let encoded = try JSONEncoder().encode(
            Standard.Inferences.DetermineNextAction.Output(
                selectedActionIdentifier: selectedActionIdentifier
            )
        )

        return InferenceInvocationResult(
            output: encoded,
            record: InferenceExecutionRecord(
                inference: invocation.definition.identifier,
                strategy: invocation.realization.strategy,
                metadata: [
                    "fixture": "select_next_action",
                ]
            )
        )
    }
}

@InferenceRealization
private struct SelectNextActionRealization {
    typealias InferenceType =
        Standard.Inferences.DetermineNextAction

    static let strategy:
        InferenceStrategyIdentifier = .native_reasoning

    static let instructions =
        "Select the best next candidate."
}

extension ProgramsFlowTesting {
    static func runSelectNextAction()
        async throws
        -> [TestFlowDiagnostic]
    {
        let input = Standard.Inferences.DetermineNextAction.Input(
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

        let recorder = SelectNextActionExecutionRecorder()
        let executor = SelectNextActionFixtureExecutor(
            selectedActionIdentifier: "publish",
            recorder: recorder
        )
        let realization = Standard.Programs.SelectNextAction.realization {
            Standard.Programs.SelectNextAction.selection.use(
                SelectNextActionRealization.self
            )
        }
        let inferenceInvoker = ProgramInferenceInvoker(
            realization: realization,
            executor: executor
        )
        let context = ProgramContext(
            inference: inferenceInvoker
        )

        let selected = try await Standard.Programs.SelectNextAction().run(
            input,
            in: context
        )
        let observations = await recorder.snapshot()

        try Expect.equal(
            Standard.Programs.SelectNextAction.definition.identifier,
            ProgramIdentifier("standard.programs.select_next_action"),
            "standard SelectNextAction exposes namespaced semantic Program identifier"
        )
        try Expect.equal(
            selected.identifier,
            "publish",
            "program resolves the inferred identifier to the exact supplied candidate"
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
            Standard.Inferences.DetermineNextAction.definition.identifier,
            "program invokes Standard.Inferences.DetermineNextAction rather than embedding decision semantics"
        )
        try Expect.equal(
            observations[0].strategy,
            .native_reasoning,
            "program inference site uses its independently bound realization"
        )

        let invalidRecorder = SelectNextActionExecutionRecorder()
        let invalidExecutor = SelectNextActionFixtureExecutor(
            selectedActionIdentifier: "invented_action",
            recorder: invalidRecorder
        )
        let invalidInvoker = ProgramInferenceInvoker(
            realization: realization,
            executor: invalidExecutor
        )
        let invalidContext = ProgramContext(
            inference: invalidInvoker
        )

        var unavailableIdentifier: String?

        do {
            _ = try await Standard.Programs.SelectNextAction().run(
                input,
                in: invalidContext
            )
        } catch Standard.Programs.SelectNextActionError.selectedActionUnavailable(
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
                Standard.Programs.SelectNextAction.definition.identifier.rawValue
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