import XCTest
@testable import MyApp

final class MyAppTests: XCTestCase {
    /// build-app.sh copies Sources/MyApp/Info.plist; a renamed executable that isn't renamed there won't launch.
    func testInfoPlistNamesTheExecutable() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/MyApp/Info.plist")
        let plist = try XCTUnwrap(NSDictionary(contentsOf: url))
        XCTAssertEqual(plist["CFBundleExecutable"] as? String, "MyApp")
    }
}
