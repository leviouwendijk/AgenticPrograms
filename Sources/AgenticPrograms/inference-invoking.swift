import Agentic

public protocol InferenceInvoking: Sendable {
    func infer<
        ProgramType: Program,
        InferenceType: Inference
    >(
        _ site: InferenceSite<
            ProgramType,
            InferenceType
        >,
        input: InferenceType.Input
    ) async throws -> InferenceType.Output
}
