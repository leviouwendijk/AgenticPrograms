public protocol AgentProgramSet: Sendable {
    func register(
        into registry: inout ProgramRegistry
    ) throws
}
