import Foundation

struct PortalEnvironment: Equatable {
    var baseURL: URL

    static let production = PortalEnvironment(baseURL: URL(string: "https://portal.openteam.ai")!)

    var apiRootURL: URL {
        baseURL.appendingPathComponent("api")
    }

    var apiBaseURL: URL {
        apiRootURL.appendingPathComponent("v1")
    }
}

enum PortalError: LocalizedError, Equatable {
    case invalidURL(String)
    case invalidResponse
    case backend(String)
    case missingToken
    case htmlOnlyView(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let path):
            return "Invalid API path: \(path)"
        case .invalidResponse:
            return "The server returned an invalid response."
        case .backend(let message):
            return message
        case .missingToken:
            return "No session token is available."
        case .htmlOnlyView(let title):
            return "\(title) is still HTML-only. Native rendering requires a structured view model."
        }
    }
}

struct PortalUser: Codable, Identifiable, Equatable {
    var id: String
    var email: String
    var name: String
    var role: String?
    var profileImageUrl: String?
    var token: String?
}

struct PortalSession: Codable, Equatable {
    var token: String
    var user: PortalUser
    var teams: [PortalTeam]
}

struct PortalTeam: Codable, Identifiable, Equatable {
    var id: String
    var gatewayId: String?
    var name: String
    var role: String
    var isDefault: Bool?

    var chatGatewayId: String {
        gatewayId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? gatewayId! : id
    }
}

struct PortalTeamsResponse: Codable, Equatable {
    var items: [PortalTeam]
}

struct PortalGateway: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var status: String
    var lastSeenAt: Int?
    var lastPairedAt: Int?
    var createdAt: Int
    var updatedAt: Int
}

struct PortalGatewayListResponse: Codable, Equatable {
    var items: [PortalGateway]
    var total: Int
}

struct NativeAuthStartResponse: Codable, Equatable {
    var success: Bool
    var expiresInSeconds: Int?
}

struct PortalHealth: Codable, Equatable {
    var status: Bool
}

struct PortalConfig: Codable, Equatable {
    var status: Bool
    var name: String
    var version: String
    var defaultLocale: String?
    var defaultModels: String?
    var defaultPromptSuggestions: [String]?
    var features: PortalFeatureFlags
}

struct PortalFeatureFlags: Codable, Equatable {
    var auth: Bool?
    var authTrustedHeader: Bool?
    var enableApiKeys: Bool?
    var enableSignup: Bool?
    var enableLoginForm: Bool?
    var enableWebSearch: Bool?
    var enableGoogleDriveIntegration: Bool?
    var enableOnedriveIntegration: Bool?
    var enableImageGeneration: Bool?
    var enableAdminExport: Bool?
    var enableAdminChatAccess: Bool?
    var enableAdminAnalytics: Bool?
    var enableCommunitySharing: Bool?
    var enableMemories: Bool?
    var enableAutocompleteGeneration: Bool?
    var enableDirectConnections: Bool?
    var enableVersionUpdateCheck: Bool?
    var enableVoiceTranscription: Bool?
}

struct PortalVersion: Codable, Equatable {
    var version: String
    var deploymentId: String?
}

struct PortalOfficialAppsCatalog: Codable, Equatable {
    var schemaVersion: Int
    var source: String
    var appHome: String?
    var apps: [PortalOfficialApp]
}

struct PortalOfficialApp: Codable, Identifiable, Equatable {
    var id: String
    var displayName: String
    var version: String
    var expectedVersion: String?
    var channel: String?
    var category: String?
    var description: String
    var icon: String?
    var websiteUrl: String?
    var skillCount: Int?
    var auth: PortalOfficialAppAuth?
    var app: PortalOfficialAppSurface?
    var capabilities: PortalOfficialAppCapabilities?
    var connect: PortalOfficialAppConnect?

    var surfaces: [String] {
        app?.surfaces ?? []
    }

    var supportsSkills: Bool {
        (skillCount ?? 0) > 0 || surfaces.contains("skills")
    }

    var supportsConnect: Bool {
        surfaces.contains("connect")
    }
}

struct PortalOfficialAppAuth: Codable, Equatable {
    var mode: String?
    var portalProvider: String?
    var runTokenRequired: Bool?
}

struct PortalOfficialAppSurface: Codable, Equatable {
    var kind: String?
    var surfaces: [String]
}

struct PortalOfficialAppCapabilities: Codable, Equatable {
    var requiresBrowser: Bool?
    var requiresFilesystem: Bool?
    var supportsTeamInstall: Bool?
    var supportsConfirmedWrites: Bool?
    var stateless: Bool?
}

struct PortalOfficialAppConnect: Codable, Equatable {
    var provider: String?
    var kind: String?
    var runtimeBinding: String?
    var mcpServerNames: [String]?
    var credentialBoundary: String?
    var sessionRequired: Bool?
    var browserProfileRequired: Bool?
}

struct PortalChatSummary: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var updatedAt: String
    var execPath: String?
    var workflowExecPath: String?
    var workdir: String?
    var gatewayId: String?
    var agentId: String?
    var spaceId: String?
    var workplaceId: String?
    var publishedWorkflowId: String?
    var lastMessagePreview: String
    var isRunning: Bool
    var isQueued: Bool?
    var queuePosition: Int?
}

struct PortalChatDetail: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var updatedAt: String
    var execPath: String?
    var workflowExecPath: String?
    var workdir: String?
    var gatewayId: String?
    var agentId: String?
    var spaceId: String?
    var workplaceId: String?
    var publishedWorkflowId: String?
    var lastMessagePreview: String
    var isRunning: Bool
    var isQueued: Bool?
    var queuePosition: Int?
    var createdAt: String
    var messages: [PortalMessage]
    var queuedMessages: [PortalQueuedMessage]?
    var currentView: PortalStructuredViewModel?
    var liveRun: PortalChatLiveRun?
}

struct PortalChatLiveRun: Codable, Equatable {
    var runId: String
    var status: String
    var lastEventSequence: Int
    var queuePosition: Int?
    var startedAt: String
    var updatedAt: String
}

struct PortalMessage: Codable, Identifiable, Equatable {
    var id: String
    var role: String
    var content: String
    var createdAt: String
    var state: String?
    var activities: [PortalActivityEvent]?
    var images: [PortalMessageImage]?
    var files: [PortalMessageFile]?

    var isUser: Bool { role == "user" }
}

struct PortalQueuedMessage: Codable, Identifiable, Equatable {
    var id: String
    var content: String
    var createdAt: String
    var queueMode: String
    var images: [PortalMessageImage]?
    var files: [PortalMessageFile]?
}

struct PortalMessageImage: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var contentType: String
    var dataUrl: String?
    var sizeBytes: Int
    var fileId: String?
}

struct PortalMessageFile: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var contentType: String
    var sizeBytes: Int
    var fileId: String?
    var dataBase64: String?
    var previewText: String?
}

struct PortalActivityEvent: Codable, Identifiable, Equatable {
    var kind: String
    var phase: String
    var id: String
    var title: String?
    var detail: String?
    var text: String?
    var command: String?
    var status: String?
    var aggregatedOutput: String?
    var exitCode: Int?
    var updatedAt: String?
    var sequence: Int?
}

struct CreateChatRequest: Codable, Equatable {
    var title: String?
    var workdir: String?
    var agentId: String?
    var spaceId: String?
    var workplaceId: String?
    var publishedWorkflowId: String?
    var gatewayId: String?
}

struct SendMessageRequest: Codable, Equatable {
    var content: String
    var images: [PortalMessageImage]
    var files: [PortalMessageFile]
}

struct PortalSpaceViewStatus: Codable, Equatable {
    var available: Bool
    var entryPath: String?
    var entryKind: String?
    var source: String?
    var viewModel: PortalStructuredViewModel?
}

struct PortalStructuredViewModel: Codable, Equatable {
    var title: String?
    var subtitle: String?
    var blocks: [PortalStructuredBlock]
}

struct PortalStructuredBlock: Codable, Identifiable, Equatable {
    var id: String
    var type: String
    var title: String?
    var subtitle: String?
    var description: String?
    var content: String?
    var items: [PortalStructuredItem]?
    var columns: [PortalStructuredColumn]?
    var rows: [PortalStructuredRow]?
    var fields: [PortalStructuredField]?
}

struct PortalStructuredItem: Codable, Identifiable, Equatable {
    var label: String
    var value: PortalJSONValue
    var tone: String?

    var id: String { label }
}

struct PortalStructuredColumn: Codable, Identifiable, Equatable {
    var key: String
    var label: String
    var align: String?
    var width: String?

    var id: String { key }
}

struct PortalStructuredRow: Codable, Identifiable, Equatable {
    var id: String
    var cells: [PortalStructuredCell]
}

struct PortalStructuredCell: Codable, Equatable {
    var kind: String?
    var text: String?
    var primary: String?
    var secondary: String?
    var value: PortalJSONValue?
    var currency: String?
    var tone: String?
    var href: String?
}

struct PortalStructuredField: Codable, Identifiable, Equatable {
    var label: String
    var value: PortalJSONValue
    var kind: String?
    var tone: String?
    var placeholder: String?
    var description: String?

    var id: String { label }
}

enum PortalJSONValue: Codable, Equatable, CustomStringConvertible {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: PortalJSONValue])
    case array([PortalJSONValue])
    case null

    var description: String {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
        case .bool(let value):
            return value ? "Yes" : "No"
        case .object:
            return "Object"
        case .array(let values):
            return values.map(\.description).joined(separator: ", ")
        case .null:
            return ""
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([PortalJSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: PortalJSONValue].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}
