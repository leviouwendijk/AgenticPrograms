import Agentic

extension ProgramRegistry: ProgramInvoking {
    public func invoke<ProgramType: ExecutableProgram>(
        _ program: ProgramType.Type,
        input: ProgramType.Input,
        in context: ProgramContext
    ) async throws -> ProgramType.Output {
        try await run(
            program,
            input: input,
            in: context
        )
    }
}
