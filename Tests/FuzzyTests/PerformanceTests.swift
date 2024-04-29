import Fuzzy
import XCTest

@inline(never)
fileprivate func blackhole(_ value: some Any) {
}

final class PerformanceTests: XCTestCase {
    func testUE4() throws {
        let ue4Filenames = try Fixtures.ue4Filenames()

        self.measure {
            blackhole(find(pattern: "lll", in: ue4Filenames))
        }
    }

    func testLinux() throws {
        let linuxFilenames = try Fixtures.linuxFilenames()

        self.measure {
            blackhole(find(pattern: "alsa", in: linuxFilenames))
        }
    }
}
