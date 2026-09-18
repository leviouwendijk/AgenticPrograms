import Agentic
import AgenticInference
import AgenticPrograms
import Foundation
import TestFlows

@Inference
private struct BridgeInference {
    struct Input:
        Sendable,
        Codable
    {
        let value: String
    }

    typealias Output = String

    static let purpose =
        "Prove Program inference-site execution bridging."
}

@Program
private struct Bridge {
    typealias Input = String
    typealias Output = String

    static let purpose =
        "Prove a Program inference site can execute a bound inference realization."

    @InferenceSite
    static var determine:
        Site<BridgeInference>

    func run(
        _ input: String,
        in context: ProgramContext
    ) async throws -> String {
        try await context.infer(
            Self.determine,
            input: BridgeInference.Input(
                value: input
            )
        )
    }
}

extension Bridge:
    ExecutableProgram
{}

@Program
private struct OtherBridge {
    typealias Input = String
    typealias Output = String

    static let purpose =
        "Provide a distinct Program owner for typed-site boundary testing."

    @InferenceSite
    static var determine:
        Site<BridgeInference>
}

@InferenceRealization
private struct BridgeRealization {
    typealias InferenceType =
        BridgeInference

    static let strategy:
        InferenceStrategyIdentifier = .native_reasoning

    static let instructions =
        "Determine the fixture result."
}

private struct BridgeExecutionObservation: Sendable {
    let inference: InferenceIdentifier
    let strategy: InferenceStrategyIdentifier
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
    InferenceExecuting,
    Sendable
{
    let recorder: BridgeExecutionRecorder

    func execute<InferenceType: Inference>(
        _ inference: InferenceType.Type,
        input: InferenceType.Input,
        realization: InferenceRealizationConfiguration,
        context: InferenceExecutionContext
    ) async throws -> InferenceExecutionResult<InferenceType.Output> {
        _ = input
        _ = context

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
            InferenceType.Output.self,
            from: encoded
        )

        return InferenceExecutionResult(
            output: output,
            record: InferenceExecutionRecord(
                inference: inference.definition.identifier,
                strategy: realization.strategy,
                metadata: [
                    "fixture": "program_inference_bridge",
                ]
            )
        )
    }
}

extension ProgramsFlowTesting {
    static func runProgramInferenceBridge()
        async throws
        -> [TestFlowDiagnostic]
    {
        let recorder = BridgeExecutionRecorder()
        let executor = BridgeInferenceExecutor(
            recorder: recorder
        )
        let programRealization = Bridge.realization {
            Bridge.determine.use(
                BridgeRealization.self
            )
        }
        let resolvedInvocation =
            try ProgramInferenceInvocation(
                Bridge.determine,
                in: programRealization
            )

        try Expect.equal(
            resolvedInvocation.site,
            Bridge.determine,
            "resolved Program inference preserves its typed semantic site"
        )
        try Expect.equal(
            resolvedInvocation.inference,
            BridgeInference.definition.identifier,
            "resolved Program inference derives semantic inference identity from the typed site"
        )
        try Expect.equal(
            resolvedInvocation.configuration,
            BridgeRealization.definition.configuration,
            "resolved Program inference preserves the bound semantic realization configuration"
        )

        let inferenceInvoker = ProgramInferenceInvoker(
            realization: programRealization,
            executor: executor
        )
        let context = ProgramContext(
            inference: inferenceInvoker
        )

        let output = try await Bridge().run(
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
            "program inference bridge executes the typed site's semantic inference"
        )
        try Expect.equal(
            observations[0].strategy,
            .native_reasoning,
            "program inference bridge forwards the bound realization strategy"
        )

        var missingSite: InferenceSiteIdentifier?

        let missingInvoker = ProgramInferenceInvoker(
            realization: Bridge.realization {},
            executor: executor
        )
        let missingContext = ProgramContext(
            inference: missingInvoker
        )

        do {
            _ = try await Bridge().run(
                "missing",
                in: missingContext
            )
        } catch ProgramInferenceInvocationError.bindingUnavailable(
            let site,
            _
        ) {
            missingSite = site
        }

        try Expect.equal(
            missingSite,
            Bridge.determine.identifier,
            "missing Program inference bindings fail at the requested typed site"
        )

        var wrongProgram: ProgramIdentifier?

        do {
            _ = try await inferenceInvoker.infer(
                OtherBridge.determine,
                input: .init(
                    value: "wrong-program"
                )
            )
        } catch ProgramInferenceInvocationError.programMismatch(
            _,
            _,
            let received
        ) {
            wrongProgram = received
        }

        try Expect.equal(
            wrongProgram,
            OtherBridge.definition.identifier,
            "erased Program inference invocation rejects a site owned by another Program"
        )

        let finalObservations = await recorder.snapshot()

        try Expect.equal(
            finalObservations.count,
            1,
            "invalid Program/site ownership is rejected before inference execution"
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
                "wrong_program",
                wrongProgram?.rawValue ?? "nil"
            ),
        ]
    }
}
