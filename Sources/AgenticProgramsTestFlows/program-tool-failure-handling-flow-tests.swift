import Agentic
import AgenticPrograms
import TestFlows

private struct ProgramToolFailureFixtureInvoker:
    ProgramToolInvoking
{
    let failure: ProgramToolFailure

    func invoke<Input, Output>(
        _ identifier: ToolIdentifier,
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

extension ProgramsFlowTesting {
    static func runProgramToolFailureHandling()
        async throws
        -> [TestFlowDiagnostic]
    {
        let identifier: ToolIdentifier =
            "fixture.program_tool_failure"
        let result = ToolResult(
            toolCallID: "fixture-program-tool-failure-call",
            tool: identifier,
            output: .null,
            isError: true
        )
        let context = ProgramContext(
            tools: ProgramToolFailureFixtureInvoker(
                failure: ProgramToolFailure(
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
                failure.result.tool == result.tool,
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
                failure.result.tool == result.tool,
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
        } catch let failure as ProgramToolFailure {
            propagated =
                failure.tool == identifier
                && failure.result.toolCallID == result.toolCallID
                && failure.result.tool == result.tool
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
            .field(
                "failed_result",
                result.tool?.rawValue ?? "<none>"
            ),
        ]
    }
}
