import AgenticInference
import AgenticPrograms
import Foundation
import TestFlows

private struct ProgramInferenceFailureFixtureInference:
    AgentInference
{
    struct Input:
        Sendable,
        Codable
    {
        let value: String
    }

    typealias Output = String

    static let definition = AgentInferenceDefinition(
        identifier: "fixture.program_inference_failure",
        purpose: "Prove Program inference failure handling."
    )
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
    AgentInferenceExecuting,
    Sendable
{
    func execute<Inference: AgentInference>(
        _ inference: Inference.Type,
        input: Inference.Input,
        realization: AgentInferenceRealization
    ) async throws
        -> AgentInferenceExecutionResult<Inference.Output>
    {
        throw ProgramInferenceFailureFixtureError.failed
    }
}

private struct ProgramInferenceCanonicalFailureFixtureExecutor:
    AgentInferenceExecuting,
    Sendable
{
    let failure: AgentInferenceExecutionFailure

    func execute<Inference: AgentInference>(
        _ inference: Inference.Type,
        input: Inference.Input,
        realization: AgentInferenceRealization
    ) async throws
        -> AgentInferenceExecutionResult<Inference.Output>
    {
        throw failure
    }
}

private struct ProgramInferenceFailureFixtureProgram:
    AgentProgram
{
    typealias Input = String
    typealias Output = String

    static let site: AgentInferenceSiteIdentifier =
        "fixture.program_inference_failure.site"

    static let descriptor = AgentProgramDescriptor(
        identifier: "fixture.program_inference_failure_program",
        title: "Program Inference Failure",
        summary: "Proves typed Program inference failure handling."
    )

    func run(
        _ input: String,
        in context: AgentProgramContext
    ) async throws -> String {
        try await context.infer(
            ProgramInferenceFailureFixtureInference.self,
            at: Self.site,
            input: .init(
                value: input
            )
        )
    }
}

extension AgenticProgramsFlowTesting {
    static func runProgramInferenceFailureHandling()
        async throws
        -> [TestFlowDiagnostic]
    {
        let boundRealization = AgentInferenceRealization(
            strategy: .direct,
            modelSelection: .executor,
            instructions: "Fail deterministically.",
            budget: .singleAttempt
        )

        let realization =
            AgentProgramRealization<
                ProgramInferenceFailureFixtureProgram
            >(
                id: "fixture.program_inference_failure_realization",
                inferences: try AgentProgramInferenceBindings(
                    [
                        AgentInferenceRealizationBinding(
                            site:
                                ProgramInferenceFailureFixtureProgram
                                    .site,
                            inference:
                                ProgramInferenceFailureFixtureInference
                                    .definition
                                    .identifier,
                            realization: boundRealization
                        ),
                    ]
                )
            )

        let invoker = AgentProgramInferenceInvoker(
            realization: realization,
            executor: ProgramInferenceFailureFixtureExecutor()
        )

        let context = AgentProgramContext(
            inference: invoker
        )

        var plainFailure: AgentProgramInferenceFailure?

        do {
            _ = try await ProgramInferenceFailureFixtureProgram()
                .run(
                    "plain",
                    in: context
                )
        } catch let failure as AgentProgramInferenceFailure {
            plainFailure = failure
        }

        let observed = try Expect.notNil(
            plainFailure,
            "plain Program inference failure is typed"
        )

        try Expect.equal(
            observed.site,
            ProgramInferenceFailureFixtureProgram.site,
            "typed inference failure preserves Program site"
        )
        try Expect.equal(
            observed.inference,
            ProgramInferenceFailureFixtureInference
                .definition
                .identifier,
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

        let canonicalExecutionFailure = AgentInferenceExecutionFailure(
            capturing: ProgramInferenceFailureFixtureError.failed,
            inference: ProgramInferenceFailureFixtureInference
                .definition
                .identifier,
            strategy: .direct,
            budget: boundRealization.budget,
            metadata: [
                "fixture": "canonical_program_failure",
            ]
        )
        let canonicalContext = AgentProgramContext(
            inference: AgentProgramInferenceInvoker(
                realization: realization,
                executor: ProgramInferenceCanonicalFailureFixtureExecutor(
                    failure: canonicalExecutionFailure
                )
            )
        )
        var canonicalProgramFailure: AgentProgramInferenceFailure?

        do {
            _ = try await ProgramInferenceFailureFixtureProgram()
                .run(
                    "canonical",
                    in: canonicalContext
                )
        } catch let failure as AgentProgramInferenceFailure {
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
            ProgramInferenceFailureFixtureInference.self,
            at: ProgramInferenceFailureFixtureProgram.site,
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
            ProgramInferenceFailureFixtureInference.self,
            at: ProgramInferenceFailureFixtureProgram.site,
            input: .init(
                value: "manual"
            )
        ) { failure -> String in
            guard
                failure.site ==
                    ProgramInferenceFailureFixtureProgram.site,
                failure.inference ==
                    ProgramInferenceFailureFixtureInference
                        .definition
                        .identifier
            else {
                throw failure
            }

            return "manual"
        }

        let disposition: String = try await context.infer(
            ProgramInferenceFailureFixtureInference.self,
            at: ProgramInferenceFailureFixtureProgram.site,
            input: .init(
                value: "disposition"
            )
        ) { failure -> AgentProgramInferenceFailure.Handling<String> in
            guard
                failure.site ==
                    ProgramInferenceFailureFixtureProgram.site,
                failure.inference ==
                    ProgramInferenceFailureFixtureInference
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
                ProgramInferenceFailureFixtureInference.self,
                at: ProgramInferenceFailureFixtureProgram.site,
                input: .init(
                    value: "propagate"
                )
            ) { _ -> AgentProgramInferenceFailure.Handling<String> in
                .propagate
            }
        } catch let failure as AgentProgramInferenceFailure {
            propagated =
                failure.site ==
                    ProgramInferenceFailureFixtureProgram.site &&
                failure.inference ==
                    ProgramInferenceFailureFixtureInference
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
