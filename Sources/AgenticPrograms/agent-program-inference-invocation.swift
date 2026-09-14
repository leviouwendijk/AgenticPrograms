import AgenticInference
import Foundation

/// One Program-authored semantic inference after its site binding has been
/// resolved and proven to belong to the requested inference.
///
/// This is the Program-specific adapter around AgenticInference's canonical
/// execution port. It owns Program binding semantics and Program failure
/// translation, but does not implement inference execution itself.
public struct AgentProgramInferenceInvocation<
    Inference: AgentInference
>: Sendable {
    public let binding: AgentInferenceRealizationBinding

    public init<Program: AgentProgram>(
        _ inference: Inference.Type,
        at site: AgentInferenceSiteIdentifier,
        in realization: AgentProgramRealization<Program>?
    ) throws {
        let inferenceIdentifier =
            inference.definition.identifier

        guard let binding = realization?.inference(
            at: site
        ) else {
            throw AgentProgramInferenceInvocationError
                .bindingUnavailable(
                    site: site,
                    inference: inferenceIdentifier
                )
        }

        guard binding.inference == inferenceIdentifier else {
            throw AgentProgramInferenceInvocationError
                .inferenceMismatch(
                    site: site,
                    expected: inferenceIdentifier,
                    bound: binding.inference
                )
        }

        self.binding = binding
    }

    public var site: AgentInferenceSiteIdentifier {
        binding.site
    }

    public var inference: AgentInferenceIdentifier {
        binding.inference
    }

    public var realization: AgentInferenceRealization {
        binding.realization
    }

    public func execute(
        input: Inference.Input,
        using executor: any AgentInferenceExecuting
    ) async throws
        -> AgentInferenceExecutionResult<Inference.Output>
    {
        do {
            return try await executor.execute(
                Inference.self,
                input: input,
                realization: realization
            )
        } catch let failure as AgentProgramInferenceFailure {
            throw failure
        } catch let error as AgentInferenceExecutionFailure {
            throw AgentProgramInferenceFailure(
                site: site,
                inference: inference,
                execution: error
            )
        } catch let error as AgentInferenceRecoveryError {
            throw AgentProgramInferenceFailure(
                site: site,
                inference: inference,
                recovery: error.record,
                message: error.message
            )
        } catch {
            throw AgentProgramInferenceFailure(
                site: site,
                inference: inference,
                message: error.localizedDescription
            )
        }
    }
}
