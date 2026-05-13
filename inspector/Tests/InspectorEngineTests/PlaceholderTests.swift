import XCTest
@testable import CosmicFitInspectorLib

final class PlaceholderTests: XCTestCase {
    func testResourcePathsCompute() {
        let root = ResourcePaths.packageRoot
        XCTAssertFalse(root.path.isEmpty)
    }
}
