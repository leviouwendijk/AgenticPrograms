import Agentic
import AgenticInference

public struct ProgramInferenceInvoker<
    ProgramType: Program
>:
    InferenceInvoking,
    Sendable
{
    private let realization: ProgramRealization<ProgramType>
    private let executor: any InferenceExecuting

    public init(
        realization: ProgramRealization<ProgramType>,
        executor: any InferenceExecuting
    ) {
        self.realization = realization
        self.executor = executor
    }

    public func infer<
        SiteProgramType: Program,
        InferenceType: Inference
    >(
        _ site: InferenceSite<
            SiteProgramType,
            InferenceType
        >,
        input: InferenceType.Input
    ) async throws -> InferenceType.Output {
        guard site.program == ProgramType.definition.identifier else {
            throw ProgramInferenceInvocationError
                .programMismatch(
                    site: site.identifier,
                    expected: ProgramType.definition.identifier,
                    received: site.program
                )
        }

        let ownedsite = InferenceSite<
            ProgramType,
            InferenceType
        >(
            identifier: site.identifier
        )
        let invocation = try ProgramInferenceInvocation(
            ownedsite,
            in: realization
        )
        let result = try await invocation.execute(
            input: input,
            using: executor
        )

        return result.output
    }
}
