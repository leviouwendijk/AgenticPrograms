import Agentic

public enum AgentProgramContextError:
    Error,
    Sendable,
    Equatable
{
    case inferenceUnavailable
    case toolInvocationUnavailable
    case programInvocationUnavailable
    case artifactStorageUnavailable
}

public protocol AgentInferenceInvoking: Sendable {
    func infer<Inference: AgentInference>(
        _ inference: Inference.Type,
        at site: AgentInferenceSiteIdentifier,
        input: Inference.Input
    ) async throws -> Inference.Output
}

public protocol AgentProgramToolInvoking: Sendable {
    func invoke<Input, Output>(
        _ identifier: AgentToolIdentifier,
        input: Input,
        as output: Output.Type
    ) async throws -> Output
    where
        Input: Encodable & Sendable,
        Output: Decodable & Sendable
}

public protocol AgentProgramInvoking: Sendable {
    func invoke<Program: AgentProgram>(
        _ program: Program.Type,
        input: Program.Input
    ) async throws -> Program.Output
}

public struct AgentProgramContext: Sendable {
    private let inferenceInvoker: (any AgentInferenceInvoking)?
    private let toolInvoker: (any AgentProgramToolInvoking)?
    private let programInvoker: (any AgentProgramInvoking)?
    private let artifactStore: (any AgentArtifactStore)?

    public let metadata: [String: String]

    public init(
        inference: (any AgentInferenceInvoking)? = nil,
        tools: (any AgentProgramToolInvoking)? = nil,
        programs: (any AgentProgramInvoking)? = nil,
        artifacts: (any AgentArtifactStore)? = nil,
        metadata: [String: String] = [:]
    ) {
        self.inferenceInvoker = inference
        self.toolInvoker = tools
        self.programInvoker = programs
        self.artifactStore = artifacts
        self.metadata = metadata
    }

    public func infer<Inference: AgentInference>(
        _ inference: Inference.Type,
        at site: AgentInferenceSiteIdentifier,
        input: Inference.Input
    ) async throws -> Inference.Output {
        guard let inferenceInvoker else {
            throw AgentProgramContextError.inferenceUnavailable
        }

        return try await inferenceInvoker.infer(
            inference,
            at: site,
            input: input
        )
    }

    public func invoke<Input, Output>(
        _ identifier: AgentToolIdentifier,
        input: Input,
        as output: Output.Type
    ) async throws -> Output
    where
        Input: Encodable & Sendable,
        Output: Decodable & Sendable
    {
        guard let toolInvoker else {
            throw AgentProgramContextError.toolInvocationUnavailable
        }

        return try await toolInvoker.invoke(
            identifier,
            input: input,
            as: output
        )
    }

    public func run<Program: AgentProgram>(
        _ program: Program.Type,
        input: Program.Input
    ) async throws -> Program.Output {
        guard let programInvoker else {
            throw AgentProgramContextError.programInvocationUnavailable
        }

        return try await programInvoker.invoke(
            program,
            input: input
        )
    }

    public func requireArtifactStore() throws -> any AgentArtifactStore {
        guard let artifactStore else {
            throw AgentProgramContextError.artifactStorageUnavailable
        }

        return artifactStore
    }
}
