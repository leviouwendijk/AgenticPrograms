import AgenticInference
import Foundation

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
        let inferenceIdentifier = inference.definition.identifier

        guard let binding = realization.inference(
            at: site
        ) else {
            throw AgentProgramInferenceInvocationError.bindingUnavailable(
                site: site,
                inference: inferenceIdentifier
            )
        }

        guard binding.inference == inferenceIdentifier else {
            throw AgentProgramInferenceInvocationError.inferenceMismatch(
                site: site,
                expected: inferenceIdentifier,
                bound: binding.inference
            )
        }

        do {
            let result = try await executor.execute(
                inference,
                input: input,
                realization: binding.realization
            )

            return result.output
        } catch let error as AgentInferenceRecoveryError {
            throw AgentProgramInferenceFailure(
                site: site,
                inference: inferenceIdentifier,
                recovery: error.record,
                message: error.message
            )
        } catch {
            throw AgentProgramInferenceFailure(
                site: site,
                inference: inferenceIdentifier,
                message: error.localizedDescription
            )
        }
    }
}
