import Agentic

public extension ProgramContext {
    func infer<
        ProgramType: Program,
        InferenceType: Inference
    >(
        _ site: InferenceSite<
            ProgramType,
            InferenceType
        >,
        input: InferenceType.Input,
        handling: ProgramFailureHandler<
            ProgramInferenceFailure,
            InferenceType.Output
        >
    ) async throws -> InferenceType.Output {
        do {
            return try await infer(
                site,
                input: input
            )
        } catch let failure as ProgramInferenceFailure {
            return try await handling(
                failure
            )
        }
    }

    func infer<
        ProgramType: Program,
        InferenceType: Inference
    >(
        _ site: InferenceSite<
            ProgramType,
            InferenceType
        >,
        input: InferenceType.Input,
        handling: ProgramFailureDispositionHandler<
            ProgramInferenceFailure,
            InferenceType.Output
        >
    ) async throws -> InferenceType.Output {
        do {
            return try await infer(
                site,
                input: input
            )
        } catch let failure as ProgramInferenceFailure {
            switch try await handling(
                failure
            ) {
            case .recover(let output):
                return output

            case .propagate:
                throw failure
            }
        }
    }
}
