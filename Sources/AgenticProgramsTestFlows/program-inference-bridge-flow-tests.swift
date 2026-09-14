import Agentic
import AgenticInference
import AgenticPrograms
import Foundation
import TestFlows

private struct BridgeInference: AgentInference {
    struct Input:
        Sendable,
        Codable
    {
        let value: String
    }

    typealias Output = String

    static let definition = AgentInferenceDefinition(
        identifier: "fixture.bridge_inference",
        purpose: "Prove program inference-site execution bridging."
    )
}

private struct BridgeProgram: AgentProgram {
    typealias Input = String
    typealias Output = String

    static let descriptor = AgentProgramDescriptor(
        identifier: "fixture.bridge_program",
        title: "Inference Bridge",
        summary: "Proves a program inference site can execute a bound inference realization."
    )

    func run(
        _ input: String,
        in context: AgentProgramContext
    ) async throws -> String {
        try await context.infer(
            BridgeInference.self,
            at: "determine",
            input: BridgeInference.Input(
                value: input
            )
        )
    }
}

private struct BridgeExecutionObservation: Sendable {
    let inference: AgentInferenceIdentifier
    let strategy: AgentInferenceStrategyIdentifier
}

private actor BridgeExecutionRecorder {
    private var observations: [BridgeExecutionObservation] = []

    func append(
        _ observation: BridgeExecutionObservation
    ) {
        observations.append(
            observation
        )
    }

    func snapshot() -> [BridgeExecutionObservation] {
        observations
    }
}

private struct BridgeInferenceExecutor:
    AgentInferenceExecuting,
    Sendable
{
    let recorder: BridgeExecutionRecorder

    func execute<Inference: AgentInference>(
        _ inference: Inference.Type,
        input: Inference.Input,
        realization: AgentInferenceRealization
    ) async throws -> AgentInferenceExecutionResult<Inference.Output> {
        await recorder.append(
            BridgeExecutionObservation(
                inference: inference.definition.identifier,
                strategy: realization.strategy
            )
        )

        let encoded = try JSONEncoder().encode(
            "BRIDGED"
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
                    "fixture": "program_inference_bridge",
                ]
            )
        )
    }
}

extension AgenticProgramsFlowTesting {
    static func runProgramInferenceBridge()
        async throws
        -> [TestFlowDiagnostic]
    {
        let recorder = BridgeExecutionRecorder()
        let executor = BridgeInferenceExecutor(
            recorder: recorder
        )
        let boundRealization = AgentInferenceRealization(
            strategy: .native_reasoning,
            modelSelection: .executor,
            instructions: "Determine the fixture result.",
            budget: .singleAttempt,
            adapter: "fixture_adapter"
        )
        let programRealization = AgentProgramRealization<BridgeProgram>(
            id: "fixture.bridge_realization",
            inferences: try AgentProgramInferenceBindings(
                [
                    AgentInferenceRealizationBinding(
                        site: "determine",
                        inference: BridgeInference.definition.identifier,
                        realization: boundRealization
                    ),
                ]
            )
        )
        let resolvedInvocation =
            try AgentProgramInferenceInvocation<BridgeInference>(
                BridgeInference.self,
                at: "determine",
                in: programRealization
            )

        try Expect.equal(
            resolvedInvocation.site,
            AgentInferenceSiteIdentifier("determine"),
            "resolved Program inference preserves its semantic site"
        )
        try Expect.equal(
            resolvedInvocation.inference,
            BridgeInference.definition.identifier,
            "resolved Program inference preserves its semantic inference identity"
        )
        try Expect.equal(
            resolvedInvocation.realization,
            boundRealization,
            "resolved Program inference preserves the exact bound realization"
        )

        let inferenceInvoker = AgentProgramInferenceInvoker(
            realization: programRealization,
            executor: executor
        )
        let context = AgentProgramContext(
            inference: inferenceInvoker
        )

        let output = try await BridgeProgram().run(
            "hello",
            in: context
        )
        let observations = await recorder.snapshot()

        try Expect.equal(
            output,
            "BRIDGED",
            "program inference site returns typed executor output"
        )
        try Expect.equal(
            observations.count,
            1,
            "program inference site executes exactly one inference"
        )
        try Expect.equal(
            observations[0].inference,
            BridgeInference.definition.identifier,
            "program inference bridge executes the bound semantic inference"
        )
        try Expect.equal(
            observations[0].strategy,
            .native_reasoning,
            "program inference bridge forwards the bound realization strategy"
        )

        var missingSite: AgentInferenceSiteIdentifier?

        let missingInvoker = AgentProgramInferenceInvoker(
            realization: AgentProgramRealization<BridgeProgram>(
                id: "fixture.missing_binding"
            ),
            executor: executor
        )
        let missingContext = AgentProgramContext(
            inference: missingInvoker
        )

        do {
            _ = try await BridgeProgram().run(
                "missing",
                in: missingContext
            )
        } catch AgentProgramInferenceInvocationError.bindingUnavailable(
            let site,
            _
        ) {
            missingSite = site
        }

        try Expect.equal(
            missingSite,
            AgentInferenceSiteIdentifier("determine"),
            "missing program inference bindings fail at the requested site"
        )

        var mismatchExpected: AgentInferenceIdentifier?
        var mismatchBound: AgentInferenceIdentifier?

        let mismatchedInvoker = AgentProgramInferenceInvoker(
            realization: AgentProgramRealization<BridgeProgram>(
                id: "fixture.mismatched_binding",
                inferences: try AgentProgramInferenceBindings(
                    [
                        AgentInferenceRealizationBinding(
                            site: "determine",
                            inference: "fixture.other_inference",
                            realization: boundRealization
                        ),
                    ]
                )
            ),
            executor: executor
        )
        let mismatchedContext = AgentProgramContext(
            inference: mismatchedInvoker
        )

        do {
            _ = try await BridgeProgram().run(
                "mismatch",
                in: mismatchedContext
            )
        } catch AgentProgramInferenceInvocationError.inferenceMismatch(
            _,
            let expected,
            let bound
        ) {
            mismatchExpected = expected
            mismatchBound = bound
        }

        try Expect.equal(
            mismatchExpected,
            BridgeInference.definition.identifier,
            "program inference bridge reports the requested inference on mismatch"
        )
        try Expect.equal(
            mismatchBound,
            AgentInferenceIdentifier("fixture.other_inference"),
            "program inference bridge reports the incorrectly bound inference"
        )

        let finalObservations = await recorder.snapshot()

        try Expect.equal(
            finalObservations.count,
            1,
            "invalid site bindings are rejected before inference execution"
        )

        return [
            .field(
                "output",
                output
            ),
            .field(
                "executions",
                String(finalObservations.count)
            ),
            .field(
                "strategy",
                observations[0].strategy.rawValue
            ),
            .field(
                "missing_site",
                missingSite?.rawValue ?? "nil"
            ),
            .field(
                "mismatch_bound",
                mismatchBound?.rawValue ?? "nil"
            ),
        ]
    }
}
