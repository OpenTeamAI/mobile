import XCTest
@testable import OpenTeamPortal

final class PortalAPIDecodingTests: XCTestCase {
    func testParsesAssistantMarkdownMessageBlocks() throws {
        let markdown = """
        I checked the recent inbox for `reviewer@example.invalid`. The newest notable email is a **Google security alert**.

        Recent inbox also includes mostly promotions/newsletters:
        - Patreon emails from HarshSYC titled **“With 方也”**
        - Connect.ca Realty: **“Ready for Wasaga Walk? June 3 Deadline”**
        - Humans at Magica: **“Anthropic dethrones OpenAI”**

        There are about **201 inbox messages from the last 7 days**.
        """

        let blocks = PortalMarkdownParser.parse(markdown)

        XCTAssertEqual(blocks.count, 4)
        XCTAssertEqual(
            blocks[0],
            .paragraph("I checked the recent inbox for `reviewer@example.invalid`. The newest notable email is a **Google security alert**.")
        )
        XCTAssertEqual(
            blocks[1],
            .paragraph("Recent inbox also includes mostly promotions/newsletters:")
        )
        XCTAssertEqual(
            blocks[2],
            .unorderedList([
                "Patreon emails from HarshSYC titled **“With 方也”**",
                "Connect.ca Realty: **“Ready for Wasaga Walk? June 3 Deadline”**",
                "Humans at Magica: **“Anthropic dethrones OpenAI”**"
            ])
        )
        XCTAssertEqual(
            blocks[3],
            .paragraph("There are about **201 inbox messages from the last 7 days**.")
        )
    }

    func testParsesMarkdownCodeAndTableBlocks() throws {
        let markdown = """
        ## Result

        ```json
        {"ok":true}
        ```

        | Name | Count |
        | --- | ---: |
        | CanLII | 5 |
        | Westlaw | 3 |
        """

        let blocks = PortalMarkdownParser.parse(markdown)

        XCTAssertEqual(blocks.count, 3)
        XCTAssertEqual(blocks[0], .heading(level: 2, text: "Result"))
        XCTAssertEqual(blocks[1], .code(language: "json", text: #"{"ok":true}"#))
        XCTAssertEqual(
            blocks[2],
            .table(headers: ["Name", "Count"], rows: [["CanLII", "5"], ["Westlaw", "3"]])
        )
    }

    func testDecodesHealthResponse() throws {
        let json = #"{"status":true}"#.data(using: .utf8)!
        let response = try JSONDecoder.portal.decode(PortalHealth.self, from: json)

        XCTAssertTrue(response.status)
    }

    func testDecodesConfigResponse() throws {
        let json = """
        {
          "status": true,
          "name": "openteam.ai",
          "version": "0.8.12",
          "default_locale": "en-US",
          "default_models": "",
          "default_prompt_suggestions": [],
          "features": {
            "auth": true,
            "enable_login_form": true,
            "enable_voice_transcription": true
          },
          "oauth": { "providers": {} }
        }
        """.data(using: .utf8)!

        let config = try JSONDecoder.portal.decode(PortalConfig.self, from: json)

        XCTAssertEqual(config.name, "openteam.ai")
        XCTAssertEqual(config.version, "0.8.12")
        XCTAssertEqual(config.defaultLocale, "en-US")
        XCTAssertEqual(config.features.enableVoiceTranscription, true)
    }

    func testDecodesVersionResponse() throws {
        let json = #"{"version":"0.8.12","deployment_id":null}"#.data(using: .utf8)!
        let version = try JSONDecoder.portal.decode(PortalVersion.self, from: json)

        XCTAssertEqual(version.version, "0.8.12")
        XCTAssertNil(version.deploymentId)
    }

    func testDecodesOfficialAppsCatalogResponse() throws {
        let json = """
        {
          "schema_version": 1,
          "source": "portal_app_service",
          "app_home": "/home/openteam/.apps",
          "apps": [
            {
              "id": "canlii",
              "display_name": "CanLII",
              "version": "0.2.1",
              "expected_version": "0.2.1",
              "channel": "stable",
              "category": "Legal",
              "description": "Use the official CanLII API for Canadian case, legislation, and citator metadata.",
              "icon": "canlii",
              "website_url": "https://www.canlii.org/",
              "skill_count": 5,
              "auth": {
                "mode": "public",
                "portal_provider": "canlii",
                "run_token_required": true
              },
              "app": {
                "kind": "official_app",
                "surfaces": ["connect", "skills"]
              },
              "capabilities": {
                "requires_browser": false,
                "requires_filesystem": false,
                "supports_team_install": false,
                "supports_confirmed_writes": false,
                "stateless": true
              },
              "connect": {
                "provider": "canlii",
                "kind": "public_api_mcp",
                "runtime_binding": "podman_local_mcp",
                "mcp_server_names": ["canlii"],
                "credential_boundary": "portal_service_secret",
                "session_required": false,
                "browser_profile_required": false
              }
            }
          ]
        }
        """.data(using: .utf8)!

        let catalog = try JSONDecoder.portal.decode(PortalOfficialAppsCatalog.self, from: json)
        let app = try XCTUnwrap(catalog.apps.first)

        XCTAssertEqual(catalog.schemaVersion, 1)
        XCTAssertEqual(catalog.source, "portal_app_service")
        XCTAssertEqual(app.displayName, "CanLII")
        XCTAssertTrue(app.supportsConnect)
        XCTAssertTrue(app.supportsSkills)
        XCTAssertEqual(app.connect?.kind, "public_api_mcp")
    }

    func testDecodesEmailCodeResponse() throws {
        let json = #"{"success":true,"expires_in_seconds":600}"#.data(using: .utf8)!
        let response = try JSONDecoder.portal.decode(NativeAuthStartResponse.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.expiresInSeconds, 600)
    }

    func testDecodesEmailVerifyUserResponse() throws {
        let json = """
        {
          "id": "23eca1da-a9b8-42d0-82fb-f4f5d851bcae",
          "email": "reviewer@example.invalid",
          "name": "App Review",
          "role": "user",
          "profile_image_url": "/assets/user.svg",
          "timezone": "Africa/Bissau",
          "permissions": { "chat": { "stt": true } },
          "token": "session-token",
          "workspace_preparing": true
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder.portal.decode(PortalUser.self, from: json)

        XCTAssertEqual(user.email, "reviewer@example.invalid")
        XCTAssertEqual(user.token, "session-token")
        XCTAssertEqual(user.profileImageUrl, "/assets/user.svg")
    }

    func testDecodesGatewayTeamsResponse() throws {
        let json = """
        {
          "items": [
            {
              "id": "63136e56-f540-4d8a-9f00-6f3bc201f666",
              "gateway_id": "b43dfe0c-7796-4b09-b12f-7c65dbfa8f79",
              "name": "appreview-fcac0871",
              "slug": "appreview-fcac0871",
              "root_path": "/home/openteam",
              "active": true,
              "role": "owner",
              "gateway": {
                "id": "b43dfe0c-7796-4b09-b12f-7c65dbfa8f79",
                "name": "HW-appreview-fcac0871",
                "status": "online"
              }
            }
          ],
          "total": 1
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.portal.decode(PortalTeamsResponse.self, from: json)
        let team = try XCTUnwrap(response.items.first)

        XCTAssertEqual(team.name, "appreview-fcac0871")
        XCTAssertEqual(team.gatewayId, "b43dfe0c-7796-4b09-b12f-7c65dbfa8f79")
        XCTAssertEqual(team.chatGatewayId, "b43dfe0c-7796-4b09-b12f-7c65dbfa8f79")
    }

    func testDecodesGatewayScopedChatSummary() throws {
        let json = """
        {
          "id": "2ed897ac-3c86-4516-8fcb-38ed4166c4c9",
          "user_id": "23eca1da-a9b8-42d0-82fb-f4f5d851bcae",
          "user_email": "reviewer@example.invalid",
          "title": "could you read my email",
          "updated_at": "2026-06-04T15:40:33.000Z",
          "exec_path": "/home/openteam/chat/2ed897ac-3c86-4516-8fcb-38ed4166c4c9",
          "workdir": "/home/openteam/chat/2ed897ac-3c86-4516-8fcb-38ed4166c4c9",
          "gateway_id": "b43dfe0c-7796-4b09-b12f-7c65dbfa8f79",
          "team_id": "63136e56-f540-4d8a-9f00-6f3bc201f666",
          "team_name": "appreview-fcac0871",
          "agent_id": null,
          "space_id": null,
          "workplace_id": null,
          "published_workflow_id": null,
          "workflow_exec_path": null,
          "last_message_preview": "",
          "is_running": false,
          "is_queued": false,
          "queue_position": null,
          "response_mode": "standard",
          "speed_mode": "standard"
        }
        """.data(using: .utf8)!

        let chat = try JSONDecoder.portal.decode(PortalChatSummary.self, from: json)

        XCTAssertEqual(chat.id, "2ed897ac-3c86-4516-8fcb-38ed4166c4c9")
        XCTAssertEqual(chat.title, "could you read my email")
        XCTAssertEqual(chat.gatewayId, "b43dfe0c-7796-4b09-b12f-7c65dbfa8f79")
        XCTAssertFalse(chat.isRunning)
    }
}
