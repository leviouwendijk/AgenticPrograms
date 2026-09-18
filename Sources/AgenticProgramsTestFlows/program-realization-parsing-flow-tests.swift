import Agentic
import AgenticPrograms
import Foundation
import TestFlows

@Inference
private struct FirstBindingInference {
    typealias Input = String
    typealias Output = String

    static let purpose =
        "Provide the first typed Program realization fixture."
}

@Inference
private struct SecondBindingInference {
    typealias Input = String
    typealias Output = String

    static let purpose =
        "Provide the second typed Program realization fixture."
}

@Program
private struct BindingParsingFixture {
    typealias Input = String
    typealias Output = String

    static let purpose =
        "Prove canonical Program realizations preserve typed unique-site bindings."

    @InferenceSite
    static var first:
        Site<FirstBindingInference>

    @InferenceSite
    static var second:
        Site<SecondBindingInference>
}

@InferenceRealization
private struct FirstDirectRealization {
    typealias InferenceType =
        FirstBindingInference

    static let strategy:
        InferenceStrategyIdentifier = .direct

    static let instructions =
        "Direct."
}

@InferenceRealization
private struct FirstReasoningRealization {
    typealias InferenceType =
        FirstBindingInference

    static let strategy:
        InferenceStrategyIdentifier = .native_reasoning

    static let instructions =
        "Reason."
}

@InferenceRealization
private struct SecondReasoningRealization {
    typealias InferenceType =
        SecondBindingInference

    static let strategy:
        InferenceStrategyIdentifier = .native_reasoning

    static let instructions =
        "Reason."
}

extension ProgramsFlowTesting {
    static func runProgramRealizationParsing()
        async throws
        -> [TestFlowDiagnostic]
    {
        let first =
            ProgramRealization<BindingParsingFixture>.Binding(
                BindingParsingFixture.first,
                realization: FirstDirectRealization.definition
            )
        let replacement =
            ProgramRealization<BindingParsingFixture>.Binding(
                BindingParsingFixture.first,
                realization: FirstReasoningRealization.definition
            )
        let second =
            ProgramRealization<BindingParsingFixture>.Binding(
                BindingParsingFixture.second,
                realization: SecondReasoningRealization.definition
            )

        let parsed = try ProgramRealization<BindingParsingFixture>(
            bindings: [
                first,
                second,
            ]
        )

        try Expect.equal(
            parsed.bindings.count,
            2,
            "parsed Program realization preserves every unique typed inference site"
        )
        try Expect.equal(
            parsed.binding(
                for: BindingParsingFixture.first
            )?.inference,
            FirstBindingInference.definition.identifier,
            "typed Program realization lookup derives the site's inference identity"
        )

        let replaced = parsed.replacing(
            BindingParsingFixture.first,
            with: FirstReasoningRealization.definition
        )

        try Expect.equal(
            replaced.bindings.count,
            2,
            "replacing an existing typed site does not duplicate its binding"
        )
        try Expect.equal(
            replaced.binding(
                for: BindingParsingFixture.first
            )?.configuration.strategy,
            .native_reasoning,
            "typed replacement changes only the selected site's realization"
        )

        var duplicateRejected = false

        do {
            _ = try ProgramRealization<BindingParsingFixture>(
                bindings: [
                    first,
                    replacement,
                ]
            )
        } catch ProgramRealizationParsingError
            .duplicateInferenceSite(let site) {
            duplicateRejected =
                site == BindingParsingFixture.first.identifier
        }

        try Expect.equal(
            duplicateRejected,
            true,
            "the explicit parsed Program-realization boundary rejects duplicate sites"
        )

        let decoded = try JSONDecoder().decode(
            ProgramRealization<BindingParsingFixture>.self,
            from: JSONEncoder().encode(
                parsed
            )
        )

        try Expect.equal(
            decoded,
            parsed,
            "valid canonical Program realizations survive durable codec round trip"
        )
        try Expect.equal(
            decoded.binding(
                for: BindingParsingFixture.second
            )?.configuration,
            SecondReasoningRealization.definition.configuration,
            "decoded Program realization lookup consumes the canonical binding representation"
        )

        return [
            .field(
                "bindings",
                String(parsed.bindings.count)
            ),
            .field(
                "duplicate_rejected",
                String(duplicateRejected)
            ),
            .field(
                "replacement_count",
                String(replaced.bindings.count)
            ),
        ]
    }
}
