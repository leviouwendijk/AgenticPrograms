import Agentic
import AgenticInference
import Foundation

/// One Program-authored typed inference site after its realization binding has
/// been resolved.
///
/// Program binding semantics remain here; typed inference execution is routed
/// through the bound InferenceSite.
public struct ProgramInferenceInvocation<
    ProgramType: Program,
    InferenceType: Inference
>: Sendable {
    public let site: InferenceSite<
        ProgramType,
        InferenceType
    >
    public let configuration: InferenceRealizationConfiguration

    public init(
        _ site: InferenceSite<
            ProgramType,
            InferenceType
        >,
        in realization: ProgramRealization<ProgramType>?
    ) throws {
        guard let binding = realization?.binding(
            for: site
        ) else {
            throw ProgramInferenceInvocationError
                .bindingUnavailable(
                    site: site.identifier,
                    inference: site.inference
                )
        }

        self.site = site
        self.configuration = binding.configuration
    }

    public var inference: InferenceIdentifier {
        site.inference
    }

    public func execute(
        input: InferenceType.Input,
        using executor: any InferenceExecuting
    ) async throws
        -> InferenceExecutionResult<InferenceType.Output>
    {
        do {
            return try await site.execute(
                using: executor,
                input: input,
                realization: configuration
            )
        } catch let error as InferenceExecutionFailure {
            throw ProgramInferenceFailure(
                site: site.identifier,
                inference: inference,
                execution: error
            )
        } catch let error as InferenceRecoveryError {
            throw ProgramInferenceFailure(
                site: site.identifier,
                inference: inference,
                recovery: error.record,
                message: error.message
            )
        } catch {
            throw ProgramInferenceFailure(
                site: site.identifier,
                inference: inference,
                message: error.localizedDescription
            )
        }
    }
}
