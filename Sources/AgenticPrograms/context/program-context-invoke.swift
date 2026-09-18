import Agentic

public extension ProgramContext {
    func invoke<Input, Output>(
        _ identifier: ToolIdentifier,
        input: Input,
        as output: Output.Type,
        handling: ProgramFailureHandler<
            ProgramToolFailure,
            Output
        >
    ) async throws -> Output
    where
        Input: Encodable & Sendable,
        Output: Decodable & Sendable
    {
        do {
            return try await invoke(
                identifier,
                input: input,
                as: output
            )
        } catch let failure as ProgramToolFailure {
            return try await handling(
                failure
            )
        }
    }

    func invoke<Input, Output>(
        _ identifier: ToolIdentifier,
        input: Input,
        as output: Output.Type,
        handling: ProgramFailureDispositionHandler<
            ProgramToolFailure,
            Output
        >
    ) async throws -> Output
    where
        Input: Encodable & Sendable,
        Output: Decodable & Sendable
    {
        do {
            return try await invoke(
                identifier,
                input: input,
                as: output
            )
        } catch let failure as ProgramToolFailure {
            switch try await handling(
                failure
            ) {
            case .recover(let output):
                return output

            case .propagate:
                throw failure
            }
        }
    }
}
