public protocol AgentProgramProvider: Sendable {
    func registerPrograms(
        into registry: inout ProgramRegistry
    ) throws
}
