import AgenticInference
import Foundation

public enum AgentProgramInferenceBindingsParsingError:
    Error,
    Sendable,
    LocalizedError
{
    case duplicateSite(AgentInferenceSiteIdentifier)

    public var errorDescription: String? {
        switch self {
        case .duplicateSite(let site):
            return "Program inference bindings contain duplicate site '\(site.rawValue)'."
        }
    }
}

public struct AgentProgramInferenceBindings:
    Sendable,
    Codable,
    Hashable,
    RandomAccessCollection
{
    public typealias Element = AgentInferenceRealizationBinding
    public typealias Index = Int

    private var storage: [AgentInferenceRealizationBinding]

    public var startIndex: Int {
        storage.startIndex
    }

    public var endIndex: Int {
        storage.endIndex
    }

    public subscript(
        position: Int
    ) -> AgentInferenceRealizationBinding {
        storage[position]
    }

    public subscript(
        site: AgentInferenceSiteIdentifier
    ) -> AgentInferenceRealizationBinding? {
        storage.first {
            $0.site == site
        }
    }

    private init(
        validatedStorage storage: [AgentInferenceRealizationBinding]
    ) {
        self.storage = storage
    }

    public init(
        _ bindings: [AgentInferenceRealizationBinding]
    ) throws {
        var seen: Set<AgentInferenceSiteIdentifier> = []

        for binding in bindings {
            guard seen.insert(binding.site).inserted else {
                throw AgentProgramInferenceBindingsParsingError
                    .duplicateSite(
                        binding.site
                    )
            }
        }

        self.storage = bindings
    }

    public static let empty = Self(
        validatedStorage: []
    )


    public mutating func set(
        _ binding: AgentInferenceRealizationBinding
    ) {
        if let index = storage.firstIndex(
            where: {
                $0.site == binding.site
            }
        ) {
            storage[index] = binding
        } else {
            storage.append(
                binding
            )
        }
    }

    public init(
        from decoder: Decoder
    ) throws {
        let container = try decoder.singleValueContainer()
        try self.init(
            try container.decode(
                [AgentInferenceRealizationBinding].self
            )
        )
    }

    public func encode(
        to encoder: Encoder
    ) throws {
        var container = encoder.singleValueContainer()
        try container.encode(
            storage
        )
    }
}
