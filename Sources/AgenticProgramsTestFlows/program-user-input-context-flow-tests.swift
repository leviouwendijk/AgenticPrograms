import Agentic
import AgenticPrograms
import TestFlows

private struct ProgramUserInputContextFixture:
    ProgramUserInputInvoking
{
    let response: UserInputResponse

    func ask(
        _ request: UserInputRequest
    ) async throws -> UserInputResponse {
        _ = request
        return response
    }
}

extension ProgramsFlowTesting {
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
        let context = ProgramContext(
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
            _ = try await ProgramContext().ask(
                request
            )
        } catch ProgramContextError.userInputUnavailable {
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
