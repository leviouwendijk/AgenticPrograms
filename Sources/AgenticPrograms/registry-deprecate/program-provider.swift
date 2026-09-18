public protocol ProgramProvider: Sendable {
    func registerPrograms(
        into registry: inout ProgramRegistry
    ) throws
}
