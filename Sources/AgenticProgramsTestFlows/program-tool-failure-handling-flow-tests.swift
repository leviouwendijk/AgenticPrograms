import Agentic
import AgenticPrograms
import TestFlows

private struct ProgramToolFailureFixtureInvoker:
    AgentProgramToolInvoking
{
    let failure: AgentProgramToolFailure

    func invoke<Input, Output>(
        _ identifier: AgentToolIdentifier,
        input: Input,
        as output: Output.Type
    ) async throws -> Output
    where
        Input: Encodable & Sendable,
        Output: Decodable & Sendable
    {
        _ = identifier
        _ = input
        _ = output
        throw failure
    }
}

extension AgenticProgramsFlowTesting {
    static func runProgramToolFailureHandling()
        async throws
        -> [TestFlowDiagnostic]
    {
        let identifier: AgentToolIdentifier =
            "fixture.program_tool_failure"
        let result = AgentToolResult(
            toolCallID: "fixture-program-tool-failure-call",
            name: identifier.rawValue,
            output: .null,
            isError: true
        )
        let context = AgentProgramContext(
            tools: ProgramToolFailureFixtureInvoker(
                failure: AgentProgramToolFailure(
                    tool: identifier,
                    result: result
                )
            )
        )

        let manual: String = try await context.invoke(
            identifier,
            input: "input",
            as: String.self
        ) { failure in
            guard
                failure.tool == identifier,
                failure.result.toolCallID == result.toolCallID,
                failure.result.name == result.name,
                failure.result.isError
            else {
                throw failure
            }

            return "manual"
        }

        let disposition: String = try await context.invoke(
            identifier,
            input: "input",
            as: String.self
        ) { failure in
            guard
                failure.tool == identifier,
                failure.result.toolCallID == result.toolCallID,
                failure.result.name == result.name,
                failure.result.isError
            else {
                return .propagate
            }

            return .recover("disposition")
        }

        var propagated = false

        do {
            let _: String = try await context.invoke(
                identifier,
                input: "input",
                as: String.self
            ) { _ in
                .propagate
            }
        } catch let failure as AgentProgramToolFailure {
            propagated =
                failure.tool == identifier
                && failure.result.toolCallID == result.toolCallID
                && failure.result.name == result.name
                && failure.result.isError
        }

        try Expect.equal(
            manual,
            "manual",
            "Output-returning handling overload permits ordinary Swift handling"
        )
        try Expect.equal(
            disposition,
            "disposition",
            "Handling-returning overload recovers with an authored output"
        )
        try Expect.equal(
            propagated,
            true,
            ".propagate rethrows the original Program tool failure"
        )

        return [
            .field("manual", manual),
            .field("disposition", disposition),
            .field("propagated", String(propagated)),
            .field("failed_result", result.name ?? "<none>"),
        ]
    }
}
