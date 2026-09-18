import Agentic

public protocol ProgramUserInputInvoking: Sendable {
    func ask(
        _ request: UserInputRequest
    ) async throws -> UserInputResponse
}
