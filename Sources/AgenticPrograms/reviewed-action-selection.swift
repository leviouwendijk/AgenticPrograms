import AgenticInference
import Foundation

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

public struct ReviewedActionSelection: AgentProgram, Sendable {
    public typealias Input = DetermineNextAction.Input

    public struct Output:
        Sendable,
        Codable,
        Hashable
    {
        public var candidate: DetermineNextAction.Candidate
        public var assessment: String

        public init(
            candidate: DetermineNextAction.Candidate,
            assessment: String
        ) {
            self.candidate = candidate
            self.assessment = assessment
        }
    }

    public static let selectionSite: AgentInferenceSiteIdentifier =
        "select_action"

    public static let assessmentSite: AgentInferenceSiteIdentifier =
        "assess_action"

    public static let descriptor = AgentProgramDescriptor(
        identifier: "reviewed_action_selection",
        title: "Reviewed Action Selection",
        summary: "Select an action, assess the selected candidate, and return it only when the assessment accepts it.",
        tags: [
            "decision",
            "assessment",
            "multi-stage",
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
            at: Self.selectionSite,
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
            AssessCandidateAction.self,
            at: Self.assessmentSite,
            input: AssessCandidateAction.Input(
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
