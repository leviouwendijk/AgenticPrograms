import Agentic
import AgenticPrograms
import TestFlows

private struct ProgramUserInputContextFixture:
    AgentProgramUserInputInvoking
{
    let response: UserInputResponse

    func ask(
        _ request: UserInputRequest
    ) async throws -> UserInputResponse {
        _ = request
        return response
    }
}

extension AgenticProgramsFlowTesting {
    static func runProgramUserInputContext()
        async throws
        -> [TestFlowDiagnostic]
    {
        let request = try UserInputRequest(
            prompt: "Provide a fixture value."
        )
        let expected = try UserInputResponse(
            answer: .text(
                "fixture"
            ),
            for: request
        )
        let context = AgentProgramContext(
            userInput: ProgramUserInputContextFixture(
                response: expected
            )
        )
        let observed = try await context.ask(
            request
        )

        try Expect.equal(
            observed,
            expected,
            "Program context delegates native user input through its semantic interaction port"
        )

        var unavailable = false

        do {
            _ = try await AgentProgramContext().ask(
                request
            )
        } catch AgentProgramContextError.userInputUnavailable {
            unavailable = true
        }

        try Expect.equal(
            unavailable,
            true,
            "Program context fails explicitly when native user input is unavailable"
        )

        return [
            .field(
                "answer",
                String(
                    describing: observed.answer
                )
            ),
            .field(
                "unavailable",
                String(unavailable)
            ),
        ]
    }
}
