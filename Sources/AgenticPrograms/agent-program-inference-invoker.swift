import AgenticInference

public struct AgentProgramInferenceInvoker<Program: AgentProgram>:
    AgentInferenceInvoking,
    Sendable
{
    private let realization: AgentProgramRealization<Program>
    private let executor: any AgentInferenceExecuting

    public init(
        realization: AgentProgramRealization<Program>,
        executor: any AgentInferenceExecuting
    ) {
        self.realization = realization
        self.executor = executor
    }

    public func infer<Inference: AgentInference>(
        _ inference: Inference.Type,
        at site: AgentInferenceSiteIdentifier,
        input: Inference.Input
    ) async throws -> Inference.Output {
        let invocation = try AgentProgramInferenceInvocation<Inference>(
            inference,
            at: site,
            in: realization
        )
        let result = try await invocation.execute(
            input: input,
            using: executor
        )

        return result.output
    }
}
