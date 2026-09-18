import Agentic

public protocol ExecutableProgram:
    Program
{
    func run(
        _ input: Input,
        in context: ProgramContext
    ) async throws -> Output
}
