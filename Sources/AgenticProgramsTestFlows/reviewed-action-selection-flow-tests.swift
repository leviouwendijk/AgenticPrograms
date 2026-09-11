import AgenticInference
import AgenticPrograms
import Foundation
import TestFlows

private struct ReviewedActionObservation: Sendable {
    let inference: AgentInferenceIdentifier
    let strategy: AgentInferenceStrategyIdentifier
}

private actor ReviewedActionRecorder {
    private var observations: [ReviewedActionObservation] = []

    func append(
        _ observation: ReviewedActionObservation
    ) {
        observations.append(
            observation
        )
    }

    func snapshot() -> [ReviewedActionObservation] {
        observations
    }
}

private struct ReviewedActionFixtureExecutor:
    AgentInferenceExecuting,
    Sendable
{
    let selectedActionIdentifier: String
    let acceptable: Bool
    let assessment: String
    let recorder: ReviewedActionRecorder

    func execute<Inference: AgentInference>(
        _ inference: Inference.Type,
        input: Inference.Input,
        realization: AgentInferenceRealization
    ) async throws -> AgentInferenceExecutionResult<Inference.Output> {
        await recorder.append(
            ReviewedActionObservation(
                inference: inference.definition.identifier,
                strategy: realization.strategy
            )
        )

        let encoded: Data

        switch inference.definition.identifier {
        case DetermineNextAction.definition.identifier:
            encoded = try JSONEncoder().encode(
                DetermineNextAction.Output(
                    selectedActionIdentifier: selectedActionIdentifier
                )
            )

        case AssessCandidateAction.definition.identifier:
            encoded = try JSONEncoder().encode(
                AssessCandidateAction.Output(
                    acceptable: acceptable,
                    assessment: assessment
                )
            )

        default:
            throw ReviewedActionFixtureError.unexpectedInference(
                inference.definition.identifier
            )
        }

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
                    "fixture": "reviewed_action_selection",
                ]
            )
        )
    }
}

private enum ReviewedActionFixtureError: Error {
    case unexpectedInference(AgentInferenceIdentifier)
}

extension AgenticProgramsFlowTesting {
    static func runReviewedActionSelection()
        async throws
        -> [TestFlowDiagnostic]
    {
        let input = DetermineNextAction.Input(
            goal: "Publish the completed change safely.",
            state: "Implementation and all tests are complete.",
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

        let selectionRealization = AgentInferenceRealization(
            strategy: .native_reasoning,
            modelSelection: .executor,
            instructions: "Select the best next candidate.",
            budget: .singleAttempt,
            adapter: "fixture_adapter"
        )
        let assessmentRealization = AgentInferenceRealization(
            strategy: .direct,
            modelSelection: .reviewer,
            instructions: "Assess whether the selected candidate should proceed.",
            budget: .singleAttempt,
            adapter: "fixture_adapter"
        )

        let recorder = ReviewedActionRecorder()
        let executor = ReviewedActionFixtureExecutor(
            selectedActionIdentifier: "publish",
            acceptable: true,
            assessment: "The completed and tested change is ready to publish.",
            recorder: recorder
        )
        let realization = AgentProgramRealization<ReviewedActionSelection>(
            id: "fixture.reviewed_action_selection",
            inferences: [
                AgentInferenceRealizationBinding(
                    site: ReviewedActionSelection.selectionSite,
                    inference: DetermineNextAction.definition.identifier,
                    realization: selectionRealization
                ),
                AgentInferenceRealizationBinding(
                    site: ReviewedActionSelection.assessmentSite,
                    inference: AssessCandidateAction.definition.identifier,
                    realization: assessmentRealization
                ),
            ]
        )
        let invoker = AgentProgramInferenceInvoker(
            realization: realization,
            executor: executor
        )
        let context = AgentProgramContext(
            inference: invoker
        )

        let output = try await ReviewedActionSelection().run(
            input,
            in: context
        )
        let observations = await recorder.snapshot()

        try Expect.equal(
            output.candidate.identifier,
            "publish",
            "multi-stage program returns the deterministically resolved selected candidate"
        )
        try Expect.equal(
            output.assessment,
            "The completed and tested change is ready to publish.",
            "multi-stage program preserves the assessment result"
        )
        try Expect.equal(
            observations.count,
            2,
            "multi-stage program executes exactly two semantic inference sites"
        )
        try Expect.equal(
            observations[0].inference,
            DetermineNextAction.definition.identifier,
            "first stage selects the next action"
        )
        try Expect.equal(
            observations[0].strategy,
            .native_reasoning,
            "selection site uses its independently bound realization"
        )
        try Expect.equal(
            observations[1].inference,
            AssessCandidateAction.definition.identifier,
            "second stage assesses the selected action"
        )
        try Expect.equal(
            observations[1].strategy,
            .direct,
            "assessment site uses its independently bound realization"
        )

        let rejectedRecorder = ReviewedActionRecorder()
        let rejectedExecutor = ReviewedActionFixtureExecutor(
            selectedActionIdentifier: "publish",
            acceptable: false,
            assessment: "Publishing is not appropriate yet.",
            recorder: rejectedRecorder
        )
        let rejectedInvoker = AgentProgramInferenceInvoker(
            realization: realization,
            executor: rejectedExecutor
        )
        let rejectedContext = AgentProgramContext(
            inference: rejectedInvoker
        )

        var rejectedIdentifier: String?

        do {
            _ = try await ReviewedActionSelection().run(
                input,
                in: rejectedContext
            )
        } catch ReviewedActionSelectionError.selectedActionRejected(
            let identifier,
            _
        ) {
            rejectedIdentifier = identifier
        }

        try Expect.equal(
            rejectedIdentifier,
            "publish",
            "ordinary program control flow rejects an unacceptable assessed action"
        )

        return [
            .field(
                "program",
                ReviewedActionSelection.descriptor.identifier.rawValue
            ),
            .field(
                "selected",
                output.candidate.identifier
            ),
            .field(
                "stages",
                String(observations.count)
            ),
            .field(
                "selection_strategy",
                observations[0].strategy.rawValue
            ),
            .field(
                "assessment_strategy",
                observations[1].strategy.rawValue
            ),
            .field(
                "rejection_branch",
                String(rejectedIdentifier != nil)
            ),
        ]
    }
}
