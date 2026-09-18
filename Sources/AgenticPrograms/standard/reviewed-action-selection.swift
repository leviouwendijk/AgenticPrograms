import Agentic
import AgenticInference
import Foundation

extension Standard.Programs {
    public enum ReviewedActionSelectionError:
        Error,
        Sendable,
        LocalizedError
    {
        case selectedActionUnavailable(String)
        case selectedActionRejected(
            identifier: String,
            assessment: String
        )

        public var errorDescription: String? {
            switch self {
            case .selectedActionUnavailable(let identifier):
                return "DetermineNextAction selected candidate '\(identifier)', but no supplied candidate has that identifier."

            case .selectedActionRejected(
                let identifier,
                let assessment
            ):
                return "Selected candidate '\(identifier)' was rejected: \(assessment)"
            }
        }
    }

    @Program
    public struct ReviewedActionSelection {
        public typealias Input = Standard.Inferences.DetermineNextAction.Input

        public struct Output:
            Sendable,
            Codable,
            Hashable
        {
            public var candidate: Standard.Inferences.DetermineNextAction.Candidate
            public var assessment: String

            public init(
                candidate: Standard.Inferences.DetermineNextAction.Candidate,
                assessment: String
            ) {
                self.candidate = candidate
                self.assessment = assessment
            }
        }

        public static let purpose =
            "Select an action, assess the selected candidate, and return it only when the assessment accepts it."

        @InferenceSite
        public static var selection:
            Site<Standard.Inferences.DetermineNextAction>

        @InferenceSite
        public static var assessment:
            Site<Standard.Inferences.AssessCandidateAction>

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
                throw ReviewedActionSelectionError.selectedActionUnavailable(
                    decision.selectedActionIdentifier
                )
            }

            let assessment = try await context.infer(
                Self.assessment,
                input: Standard.Inferences.AssessCandidateAction.Input(
                    goal: input.goal,
                    state: input.state,
                    candidate: candidate
                )
            )

            guard assessment.acceptable else {
                throw ReviewedActionSelectionError.selectedActionRejected(
                    identifier: candidate.identifier,
                    assessment: assessment.assessment
                )
            }

            return Output(
                candidate: candidate,
                assessment: assessment.assessment
            )
        }
    }
}
