import Agentic

public protocol AgentProgramUserInputInvoking: Sendable {
    func ask(
        _ request: UserInputRequest
    ) async throws -> UserInputResponse
}
