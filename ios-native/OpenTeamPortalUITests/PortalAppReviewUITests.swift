import XCTest

final class PortalAppReviewUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppReviewLoginLoadsChatDetail() throws {
        #if OPENTEAM_UI_SMOKE
        let environment = ProcessInfo.processInfo.environment
        guard let email = environment["OPENTEAM_APP_REVIEW_EMAIL"], !email.isEmpty,
              let code = environment["OPENTEAM_APP_REVIEW_CODE"], !code.isEmpty else {
            throw XCTSkip("Set OPENTEAM_APP_REVIEW_EMAIL and OPENTEAM_APP_REVIEW_CODE to run production UI smoke tests.")
        }

        let app = XCUIApplication()
        app.launchArguments = ["--reset-session"]
        app.launchEnvironment["OPENTEAM_APP_REVIEW_EMAIL"] = email
        app.launch()

        let emailField = app.textFields["auth-email-field"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 10), "Email field should appear after resetting session.")
        emailField.tap()
        emailField.typeText(email)
        app.buttons["auth-submit-button"].tap()

        let codeField = app.textFields["auth-code-field"]
        XCTAssertTrue(codeField.waitForExistence(timeout: 10), "Code field should appear after requesting the email code.")
        codeField.tap()
        codeField.typeText(code)
        app.buttons["auth-submit-button"].tap()

        let teamName = app.staticTexts["appreview-fcac0871"]
        XCTAssertTrue(teamName.waitForExistence(timeout: 30), "App Review login should land on the review team home.")

        let switchTeam = app.buttons["Switch team"]
        XCTAssertTrue(switchTeam.waitForExistence(timeout: 10), "Home should expose native team switching.")
        switchTeam.tap()
        XCTAssertTrue(app.navigationBars["OpenTeam"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["appreview-fcac0871"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        let connectedApps = app.buttons["Connected apps"]
        XCTAssertTrue(connectedApps.waitForExistence(timeout: 10), "Home composer should expose connected apps.")
        connectedApps.tap()
        XCTAssertTrue(app.staticTexts["CanLII"].waitForExistence(timeout: 20), "Official apps catalog should render in native sheet.")
        XCTAssertTrue(app.staticTexts["Westlaw Canada"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        let reviewChat = app.buttons["chat-card-2ed897ac-3c86-4516-8fcb-38ed4166c4c9"]
        XCTAssertTrue(reviewChat.waitForExistence(timeout: 20), "Gateway-scoped App Review chat should render in Recent.")
        reviewChat.tap()

        let gmailButton = app.buttons["Gmail"]
        XCTAssertTrue(gmailButton.waitForExistence(timeout: 20), "Tapping the Recent chat should open native chat detail.")
        XCTAssertTrue(app.staticTexts["could you read my email"].waitForExistence(timeout: 10))
        XCTAssertTrue(gmailButton.exists)
        #else
        throw XCTSkip("Build with OTHER_SWIFT_FLAGS='-D OPENTEAM_UI_SMOKE' to run production UI smoke tests.")
        #endif
    }
}
