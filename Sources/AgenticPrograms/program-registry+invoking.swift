extension ProgramRegistry: AgentProgramInvoking {
    public func invoke<Program: AgentProgram>(
        _ program: Program.Type,
        input: Program.Input,
        in context: AgentProgramContext
    ) async throws -> Program.Output {
        try await run(
            program,
            input: input,
            in: context
        )
    }
}
