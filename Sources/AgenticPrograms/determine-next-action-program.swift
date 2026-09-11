import AgenticInference
import Foundation

public enum DetermineNextActionProgramError:
    Error,
    Sendable,
    LocalizedError
{
    case selectedActionUnavailable(String)

    public var errorDescription: String? {
        switch self {
        case .selectedActionUnavailable(let identifier):
            return "DetermineNextAction selected candidate '\(identifier)', but no supplied candidate has that identifier."
        }
    }
}

public struct DetermineNextActionProgram:
    AgentProgram,
    Sendable
{
    public typealias Input = DetermineNextAction.Input
    public typealias Output = DetermineNextAction.Candidate

    public static let inferenceSite: AgentInferenceSiteIdentifier =
        "determine_next_action"

    public static let descriptor = AgentProgramDescriptor(
        identifier: "select_next_action",
        title: "Select Next Action",
        summary: "Select and resolve the next action from an explicit candidate set using DetermineNextAction.",
        tags: [
            "decision",
            "action-selection",
            "inference",
        ]
    )

    public init() {}

    public func run(
        _ input: Input,
        in context: AgentProgramContext
    ) async throws -> Output {
        let decision = try await context.infer(
            DetermineNextAction.self,
            at: Self.inferenceSite,
            input: input
        )

        guard let candidate = input.candidates.first(
            where: {
                $0.identifier == decision.selectedActionIdentifier
            }
        ) else {
            throw DetermineNextActionProgramError.selectedActionUnavailable(
                decision.selectedActionIdentifier
            )
        }

        return candidate
    }
}
