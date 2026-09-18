import Agentic
import AgenticInference
import AgenticPrograms
import Foundation
import TestFlows

@Inference
private struct FailureInference {
    struct Input:
        Sendable,
        Codable
    {
        let value: String
    }

    typealias Output = String

    static let purpose =
        "Prove Program inference failure handling."
}

@Program
private struct InferenceFailureFixture {
    typealias Input = String
    typealias Output = String

    static let purpose =
        "Prove typed Program inference failure handling."

    @InferenceSite
    static var failure:
        Site<FailureInference>

    func run(
        _ input: String,
        in context: ProgramContext
    ) async throws -> String {
        try await context.infer(
            Self.failure,
            input: .init(
                value: input
            )
        )
    }
}

@InferenceRealization
private struct FailureRealization {
    typealias InferenceType =
        FailureInference

    static let strategy:
        InferenceStrategyIdentifier = .direct

    static let instructions =
        "Fail deterministically."
}

private enum ProgramInferenceFailureFixtureError:
    Error,
    Sendable,
    LocalizedError
{
    case failed

    var errorDescription: String? {
        "fixture inference failure"
    }
}

private struct ProgramInferenceFailureFixtureExecutor:
    InferenceExecuting,
    Sendable
{
    func execute<InferenceType: Inference>(
        _ inference: InferenceType.Type,
        input: InferenceType.Input,
        realization: InferenceRealizationConfiguration,
        context: InferenceExecutionContext
    ) async throws
        -> InferenceExecutionResult<InferenceType.Output>
    {
        _ = inference
        _ = input
        _ = realization
        _ = context

        throw ProgramInferenceFailureFixtureError.failed
    }
}

private struct ProgramInferenceCanonicalFailureFixtureExecutor:
    InferenceExecuting,
    Sendable
{
    let failure: InferenceExecutionFailure

    func execute<InferenceType: Inference>(
        _ inference: InferenceType.Type,
        input: InferenceType.Input,
        realization: InferenceRealizationConfiguration,
        context: InferenceExecutionContext
    ) async throws
        -> InferenceExecutionResult<InferenceType.Output>
    {
        _ = inference
        _ = input
        _ = realization
        _ = context

        throw failure
    }
}

extension ProgramsFlowTesting {
    static func runProgramInferenceFailureHandling()
        async throws
        -> [TestFlowDiagnostic]
    {
        let realization = InferenceFailureFixture.realization {
            InferenceFailureFixture.failure.use(
                FailureRealization.self
            )
        }

        let invoker = ProgramInferenceInvoker(
            realization: realization,
            executor: ProgramInferenceFailureFixtureExecutor()
        )

        let context = ProgramContext(
            inference: invoker
        )

        var plainFailure: ProgramInferenceFailure?

        do {
            _ = try await InferenceFailureFixture()
                .run(
                    "plain",
                    in: context
                )
        } catch let failure as ProgramInferenceFailure {
            plainFailure = failure
        }

        let observed = try Expect.notNil(
            plainFailure,
            "plain Program inference failure is typed"
        )

        try Expect.equal(
            observed.site,
            InferenceFailureFixture.failure.identifier,
            "typed inference failure preserves Program site"
        )
        try Expect.equal(
            observed.inference,
            FailureInference.definition.identifier,
            "typed inference failure preserves semantic inference"
        )
        try Expect.equal(
            observed.recovery == nil,
            true,
            "unclassified inference failure does not invent recovery evidence"
        )
        try Expect.equal(
            observed.message,
            ProgramInferenceFailureFixtureError.failed
                .localizedDescription,
            "typed inference failure preserves executor error message"
        )
        try Expect.equal(
            observed.execution == nil,
            true,
            "arbitrary custom executor errors retain the fallback Program failure representation"
        )

        let canonicalExecutionFailure = InferenceExecutionFailure(
            capturing: ProgramInferenceFailureFixtureError.failed,
            inference: FailureInference
                .definition
                .identifier,
            strategy: .direct,
            budget: FailureRealization.definition.configuration.budget,
            metadata: [
                "fixture": "canonical_program_failure",
            ]
        )
        let canonicalContext = ProgramContext(
            inference: ProgramInferenceInvoker(
                realization: realization,
                executor: ProgramInferenceCanonicalFailureFixtureExecutor(
                    failure: canonicalExecutionFailure
                )
            )
        )
        var canonicalProgramFailure: ProgramInferenceFailure?

        do {
            _ = try await InferenceFailureFixture()
                .run(
                    "canonical",
                    in: canonicalContext
                )
        } catch let failure as ProgramInferenceFailure {
            canonicalProgramFailure = failure
        }

        let canonicalObserved = try Expect.notNil(
            canonicalProgramFailure,
            "canonical inference execution failure reaches Program semantics"
        )
        let retainedExecution = try Expect.notNil(
            canonicalObserved.execution,
            "Program inference failure retains the exact lower-level execution failure"
        )

        try Expect.equal(
            retainedExecution.record,
            canonicalExecutionFailure.record,
            "Program inference failure preserves the complete canonical execution record"
        )
        try Expect.equal(
            canonicalObserved.recovery,
            canonicalExecutionFailure.recovery,
            "Program recovery projection comes from the canonical execution failure"
        )
        try Expect.equal(
            canonicalObserved.message,
            canonicalExecutionFailure.failure.message,
            "Program message projection comes from the canonical execution failure"
        )
        try Expect.equal(
            retainedExecution.record.failure,
            canonicalExecutionFailure.record.failure,
            "durable lower-level execution failure evidence is not reconstructed"
        )
        try Expect.equal(
            retainedExecution.record.metadata["fixture"],
            "canonical_program_failure",
            "Program failure retains canonical execution metadata"
        )

        let canonicalHandled: String = try await canonicalContext.infer(
            InferenceFailureFixture.failure,
            input: .init(
                value: "canonical-handler"
            )
        ) { failure -> String in
            guard
                failure.execution?.record ==
                    canonicalExecutionFailure.record
            else {
                throw failure
            }

            return "canonical"
        }

        try Expect.equal(
            canonicalHandled,
            "canonical",
            "authored Program failure handlers can inspect exact lower-level inference execution evidence"
        )

        let manual: String = try await context.infer(
            InferenceFailureFixture.failure,
            input: .init(
                value: "manual"
            )
        ) { failure -> String in
            guard
                failure.site ==
                    InferenceFailureFixture.failure.identifier,
                failure.inference ==
                    FailureInference
                        .definition
                        .identifier
            else {
                throw failure
            }

            return "manual"
        }

        let disposition: String = try await context.infer(
            InferenceFailureFixture.failure,
            input: .init(
                value: "disposition"
            )
        ) { failure -> ProgramInferenceFailure.Handling<String> in
            guard
                failure.site ==
                    InferenceFailureFixture.failure.identifier,
                failure.inference ==
                    FailureInference
                        .definition
                        .identifier
            else {
                return .propagate
            }

            return .recover(
                "disposition"
            )
        }

        var propagated = false

        do {
            _ = try await context.infer(
                InferenceFailureFixture.failure,
                input: .init(
                    value: "propagate"
                )
            ) { _ -> ProgramInferenceFailure.Handling<String> in
                .propagate
            }
        } catch let failure as ProgramInferenceFailure {
            propagated =
                failure.site ==
                    InferenceFailureFixture.failure.identifier
                && failure.inference ==
                    FailureInference
                        .definition
                        .identifier
        }

        try Expect.equal(
            manual,
            "manual",
            "ordinary inference failure handler recovers with output"
        )
        try Expect.equal(
            disposition,
            "disposition",
            "disposition inference handler recovers explicitly"
        )
        try Expect.equal(
            propagated,
            true,
            "disposition propagate rethrows original typed inference failure"
        )

        return [
            .field(
                "manual",
                manual
            ),
            .field(
                "disposition",
                disposition
            ),
            .field(
                "propagated",
                String(propagated)
            ),
            .field(
                "inference",
                observed.inference.rawValue
            ),
            .field(
                "canonical_execution_failure",
                String(canonicalObserved.execution != nil)
            ),
            .field(
                "canonical_handler",
                canonicalHandled
            ),
        ]
    }
}
