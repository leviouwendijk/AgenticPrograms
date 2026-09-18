public protocol ProgramSet: Sendable {
    func register(
        into registry: inout ProgramRegistry
    ) throws
}
