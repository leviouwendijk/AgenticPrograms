import Agentic
import AgenticInference
import Foundation

extension Standard.Programs {
    public enum SelectNextActionError:
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

    @Program
    public struct SelectNextAction {
        public typealias Input = Standard.Inferences.DetermineNextAction.Input
        public typealias Output = Standard.Inferences.DetermineNextAction.Candidate

        public static let purpose = """
        Select and resolve the next action from an explicit candidate set using DetermineNextAction.
        """

        @InferenceSite
        public static var selection: Site<Standard.Inferences.DetermineNextAction>

        public init() {}

        public func run(
            _ input: Input,
            in context: ProgramContext
        ) async throws -> Output {
            let decision = try await context.infer(
                Self.selection,
                input: input
            )

            guard let candidate = input.candidates.first(
                where: {
                    $0.identifier == decision.selectedActionIdentifier
                }
            ) else {
                throw SelectNextActionError.selectedActionUnavailable(
                    decision.selectedActionIdentifier
                )
            }

            return candidate
        }
    }
}
