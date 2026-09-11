import AgenticInference
import AgenticPrograms
import Foundation
import TestFlows

private struct BindingParsingFixtureProgram: AgentProgram {
    typealias Input = String
    typealias Output = String

    static let descriptor = AgentProgramDescriptor(
        identifier: "fixture.binding_parsing",
        title: "Binding Parsing Fixture",
        summary: "Proves program inference bindings are unique by construction."
    )

    func run(
        _ input: String,
        in context: AgentProgramContext
    ) async throws -> String {
        input
    }
}

extension AgenticProgramsFlowTesting {
    static func runProgramInferenceBindingParsing()
        async throws
        -> [TestFlowDiagnostic]
    {
        let direct = AgentInferenceRealization(
            strategy: .direct,
            modelSelection: .executor,
            instructions: "Direct.",
            budget: .singleAttempt
        )
        let reasoning = AgentInferenceRealization(
            strategy: .native_reasoning,
            modelSelection: .reviewer,
            instructions: "Reason.",
            budget: .singleAttempt
        )
        let first = AgentInferenceRealizationBinding(
            site: "first",
            inference: "fixture.first",
            realization: direct
        )
        let second = AgentInferenceRealizationBinding(
            site: "second",
            inference: "fixture.second",
            realization: reasoning
        )

        let bindings = try AgentProgramInferenceBindings(
            [
                first,
                second,
            ]
        )

        try Expect.equal(
            bindings.count,
            2,
            "parsed binding collection preserves every unique inference site"
        )
        try Expect.equal(
            bindings["first"]?.inference,
            AgentInferenceIdentifier(
                "fixture.first"
            ),
            "parsed binding collection resolves a site without first-match ambiguity"
        )

        var replaced = bindings
        replaced.set(
            AgentInferenceRealizationBinding(
                site: "first",
                inference: "fixture.replacement",
                realization: reasoning
            )
        )

        try Expect.equal(
            replaced.count,
            2,
            "setting an existing site replaces rather than duplicates its binding"
        )
        try Expect.equal(
            replaced["first"]?.inference,
            AgentInferenceIdentifier(
                "fixture.replacement"
            ),
            "binding replacement preserves the unique-site invariant"
        )

        var duplicateRejected = false

        do {
            _ = try AgentProgramInferenceBindings(
                [
                    first,
                    AgentInferenceRealizationBinding(
                        site: "first",
                        inference: "fixture.duplicate",
                        realization: reasoning
                    ),
                ]
            )
        } catch AgentProgramInferenceBindingsParsingError
            .duplicateSite(let site) {
            duplicateRejected = site == "first"
        }

        try Expect.equal(
            duplicateRejected,
            true,
            "duplicate inference sites are rejected while parsing raw bindings"
        )

        let duplicateData = try JSONEncoder().encode(
            [
                first,
                AgentInferenceRealizationBinding(
                    site: "first",
                    inference: "fixture.decoded_duplicate",
                    realization: reasoning
                ),
            ]
        )
        var duplicateDecodeRejected = false

        do {
            _ = try JSONDecoder().decode(
                AgentProgramInferenceBindings.self,
                from: duplicateData
            )
        } catch AgentProgramInferenceBindingsParsingError
            .duplicateSite(let site) {
            duplicateDecodeRejected = site == "first"
        }

        try Expect.equal(
            duplicateDecodeRejected,
            true,
            "Codable decoding cannot bypass the unique-site parsing invariant"
        )

        let decodedBindings = try JSONDecoder().decode(
            AgentProgramInferenceBindings.self,
            from: JSONEncoder().encode(
                bindings
            )
        )

        try Expect.equal(
            decodedBindings,
            bindings,
            "valid parsed inference bindings survive durable codec round trip"
        )

        let realization = AgentProgramRealization<BindingParsingFixtureProgram>(
            id: "fixture.binding_parsing.realization",
            inferences: bindings,
            metadata: [
                "marker": "preserved",
            ]
        )
        let decodedRealization = try JSONDecoder().decode(
            AgentProgramRealization<BindingParsingFixtureProgram>.self,
            from: JSONEncoder().encode(
                realization
            )
        )

        try Expect.equal(
            decodedRealization,
            realization,
            "program realization preserves parsed bindings and metadata through Codable"
        )
        try Expect.equal(
            decodedRealization.realization(
                at: "second"
            ),
            reasoning,
            "program realization lookup consumes the parsed binding collection"
        )

        return [
            .field(
                "bindings",
                String(bindings.count)
            ),
            .field(
                "duplicate_rejected",
                String(duplicateRejected)
            ),
            .field(
                "duplicate_decode_rejected",
                String(duplicateDecodeRejected)
            ),
            .field(
                "replacement_count",
                String(replaced.count)
            ),
        ]
    }
}
