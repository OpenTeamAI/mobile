import XCTest
@testable import OpenTeamPortal

final class SSEParserTests: XCTestCase {
    func testParsesDeltaEvent() throws {
        var parser = SSEParser()
        XCTAssertNil(parser.feed(line: #"data: {"run_id":"run-1","sequence":4,"choices":[{"delta":{"content":"Hi"}}]}"#))
        let event = try XCTUnwrap(parser.feed(line: ""))
        let update = try XCTUnwrap(try PortalStreamDecoder.decode(event: event))

        XCTAssertFalse(update.done)
        XCTAssertEqual(update.runId, "run-1")
        XCTAssertEqual(update.sequence, 4)
        XCTAssertEqual(update.value, "Hi")
    }

    func testParsesCodexFinalEvent() throws {
        var parser = SSEParser()
        XCTAssertNil(parser.feed(line: #"data: {"run_id":"run-1","sequence":8,"codex_final":{"response_text":"Done","thread_id":"thread-1","run_id":"run-1"}}"#))
        let event = try XCTUnwrap(parser.feed(line: ""))
        let update = try XCTUnwrap(try PortalStreamDecoder.decode(event: event))

        XCTAssertEqual(update.codexFinal?.responseText, "Done")
        XCTAssertEqual(update.codexFinal?.threadId, "thread-1")
        XCTAssertEqual(update.codexFinal?.sequence, 8)
    }

    func testParsesCommandActivityEvent() throws {
        var parser = SSEParser()
        XCTAssertNil(parser.feed(line: #"data: {"sequence":3,"codex_event":{"kind":"command_execution","phase":"completed","id":"cmd-1","command":"pwd","status":"success","aggregated_output":"/tmp","exit_code":0}}"#))
        let event = try XCTUnwrap(parser.feed(line: ""))
        let update = try XCTUnwrap(try PortalStreamDecoder.decode(event: event))

        XCTAssertEqual(update.codexEvent?.id, "cmd-1")
        XCTAssertEqual(update.codexEvent?.kind, "command_execution")
        XCTAssertEqual(update.codexEvent?.aggregatedOutput, "/tmp")
        XCTAssertEqual(update.codexEvent?.sequence, 3)
    }

    func testParsesDoneMarker() throws {
        var parser = SSEParser()
        XCTAssertNil(parser.feed(line: "data: [DONE]"))
        let event = try XCTUnwrap(parser.feed(line: ""))
        let update = try XCTUnwrap(try PortalStreamDecoder.decode(event: event))

        XCTAssertTrue(update.done)
    }
}

