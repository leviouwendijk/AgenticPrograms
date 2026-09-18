import Agentic
import AgenticInference

public enum ProgramContextError:
    Error,
    Sendable,
    Equatable
{
    case inferenceUnavailable
    case toolInvocationUnavailable
    case programInvocationUnavailable
    case userInputUnavailable
    case artifactStorageUnavailable
}

public protocol ProgramToolInvoking: Sendable {
    func invoke<Input, Output>(
        _ identifier: ToolIdentifier,
        input: Input,
        as output: Output.Type
    ) async throws -> Output
    where
        Input: Encodable & Sendable,
        Output: Decodable & Sendable
}

public protocol ProgramInvoking: Sendable {
    func invoke<ProgramType: ExecutableProgram>(
        _ program: ProgramType.Type,
        input: ProgramType.Input,
        in context: ProgramContext
    ) async throws -> ProgramType.Output
}

public struct ProgramContext: Sendable {
    private let inferenceInvoker: (any InferenceInvoking)?
    private let toolInvoker: (any ProgramToolInvoking)?
    private let programInvoker: (any ProgramInvoking)?
    private let userInputInvoker: (any ProgramUserInputInvoking)?
    private let artifactStore: (any AgentArtifactStore)?

    public let metadata: [String: String]

    public init(
        inference: (any InferenceInvoking)? = nil,
        tools: (any ProgramToolInvoking)? = nil,
        programs: (any ProgramInvoking)? = nil,
        userInput: (any ProgramUserInputInvoking)? = nil,
        artifacts: (any AgentArtifactStore)? = nil,
        metadata: [String: String] = [:]
    ) {
        self.inferenceInvoker = inference
        self.toolInvoker = tools
        self.programInvoker = programs
        self.userInputInvoker = userInput
        self.artifactStore = artifacts
        self.metadata = metadata
    }

    public func infer<
        ProgramType: Program,
        InferenceType: Inference
    >(
        _ site: InferenceSite<
            ProgramType,
            InferenceType
        >,
        input: InferenceType.Input
    ) async throws -> InferenceType.Output {
        guard let inferenceInvoker else {
            throw ProgramContextError.inferenceUnavailable
        }

        return try await inferenceInvoker.infer(
            site,
            input: input
        )
    }

    public func infer<
        ProgramType: Program,
        InferenceType: Inference
    >(
        _ site: InferenceSite<
            ProgramType,
            InferenceType
        >,
        input: InferenceType.Input,
        handling: ProgramFailureHandler<
            ProgramInferenceFailure,
            InferenceType.Output
        >
    ) async throws -> InferenceType.Output {
        do {
            return try await infer(
                site,
                input: input
            )
        } catch let failure as ProgramInferenceFailure {
            return try await handling(
                failure
            )
        }
    }

    public func infer<
        ProgramType: Program,
        InferenceType: Inference
    >(
        _ site: InferenceSite<
            ProgramType,
            InferenceType
        >,
        input: InferenceType.Input,
        handling: ProgramFailureDispositionHandler<
            ProgramInferenceFailure,
            InferenceType.Output
        >
    ) async throws -> InferenceType.Output {
        do {
            return try await infer(
                site,
                input: input
            )
        } catch let failure as ProgramInferenceFailure {
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

    public func invoke<Input, Output>(
        _ identifier: ToolIdentifier,
        input: Input,
        as output: Output.Type
    ) async throws -> Output
    where
        Input: Encodable & Sendable,
        Output: Decodable & Sendable
    {
        guard let toolInvoker else {
            throw ProgramContextError.toolInvocationUnavailable
        }

        return try await toolInvoker.invoke(
            identifier,
            input: input,
            as: output
        )
    }

    public func invoke<Input, Output>(
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
            return try await handling(failure)
        }
    }

    public func invoke<Input, Output>(
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
            switch try await handling(failure) {
            case .recover(let output):
                return output

            case .propagate:
                throw failure
            }
        }
    }

    public func ask(
        _ request: UserInputRequest
    ) async throws -> UserInputResponse {
        guard let userInputInvoker else {
            throw ProgramContextError.userInputUnavailable
        }

        return try await userInputInvoker.ask(
            request
        )
    }

    public func run<ProgramType: ExecutableProgram>(
        _ program: ProgramType.Type,
        input: ProgramType.Input
    ) async throws -> ProgramType.Output {
        guard let programInvoker else {
            throw ProgramContextError.programInvocationUnavailable
        }

        return try await programInvoker.invoke(
            program,
            input: input,
            in: self
        )
    }

    public func requireArtifactStore() throws -> any AgentArtifactStore {
        guard let artifactStore else {
            throw ProgramContextError.artifactStorageUnavailable
        }

        return artifactStore
    }
}
