import Fuzzy
import XCTest

final class FuzzyTests: XCTestCase {
    func testFindWithUnicode() {
        let matches = find(pattern: "\u{1F41D}", in: ["\u{1F41D}"])
        XCTAssertEqual(matches.count, 1)
    }

    func testFindWithCannedData() {
        struct TestCase {
            init(pattern: String, data: [String], expected: [Match<[String]>], line: UInt = #line) {
                self.pattern = pattern
                self.data = data
                self.expected = expected
                self.line = line
            }
            var pattern: String
            var data: [String]
            var expected: [Match<[String]>]
            var line: UInt
        }

        let testCases: [TestCase] = [
            // first character and camel case bonuses, and unmatched characters penalty
            // (m = 10, n = 20, r = 20) - 18 unmatched chars = 32
            TestCase(
                pattern: "mnr",
                data: ["moduleNameResolver.ts"],
                expected: [Match(value: "moduleNameResolver.ts", index: 0, matchedIndices: [0, 6, 10], score: 32)]
            ),
            TestCase(
                pattern: "mmt",
                data: ["mémeTemps"],
                expected: [Match(value: "mémeTemps", index: 0, matchedIndices: [0, 2, 4], score: 24)]
            ),
            // Ranking
            TestCase(
                pattern: "mnr",
                data: ["moduleNameResolver.ts", "my name is_Ramsey"],
                expected: [
                    Match(value: "my name is_Ramsey", index: 1, matchedIndices: [0, 3, 11], score: 36),
                    Match(value: "moduleNameResolver.ts", index: 0, matchedIndices: [0, 6, 10], score: 32)
                ]
            ),
            // Simple repeated pattern and adjacent match bonus
            TestCase(
                pattern: "aaa",
                data: ["aaa", "bbb"],
                expected: [Match(value: "aaa", index: 0, matchedIndices: [0, 1, 2], score: 30)]
            ),
            // Exhaustive matching
            TestCase(
                pattern: "tk",
                data: ["The Black Knight"],
                expected: [Match(value: "The Black Knight", index: 0, matchedIndices: [0, 10], score: 16)]
            ),
            // Any unmatched character in the pattern removes the whole match
            TestCase(
                pattern: "cats",
                data: ["cat"],
                expected: []
            ),
            // Empty patterns return no matches
            TestCase(
                pattern: "",
                data: ["cat"],
                expected: []
            ),
            // Separator bonus
            TestCase(
                pattern: "abcx",
                data: ["abc\\x"],
                expected: [Match(value: "abc\\x", index: 0, matchedIndices: [0, 1, 2, 4], score: 49)]
            )
        ]

        for testCase in testCases {
            let matches = find(pattern: testCase.pattern, in: testCase.data)
            XCTAssertEqual(matches, testCase.expected, line: testCase.line)
        }
    }

    struct FileTestCase {
        init(pattern: String, matchesCount: Int, filenames: [String], line: UInt = #line) {
            self.pattern = pattern
            self.matchesCount = matchesCount
            self.filenames = filenames
            self.line = line
        }
        var pattern: String
        var matchesCount: Int
        var filenames: [String]
        var line: UInt
    }

    func testFindWithRealworldData_UE4() throws {
        let testCases: [FileTestCase] = [
            FileTestCase(pattern: "ue4", matchesCount: 4, filenames: [
                "UE4Game.cpp",
                "UE4Build.cs",
                "UE4Game.Build.cs",
                "UE4BuildUtils.cs",
            ]),
            FileTestCase(pattern: "lll", matchesCount: 3, filenames: [
                "LogFileLogger.cs",
                "LockFreeListImpl.h",
                "LevelExporterLOD.h",
            ]),
            FileTestCase(pattern: "aes", matchesCount: 3, filenames: [
                "AES.h",
                "AES.cpp",
                "ActiveSound.h",
            ]),
        ]

        let ue4Filenames = try Fixtures.ue4Filenames()

        for testCase in testCases {
            let matches = find(pattern: testCase.pattern, in: ue4Filenames)
            XCTAssertEqual(
                matches.prefix(testCase.matchesCount).map { String($0.value) },
                testCase.filenames,
                line: testCase.line
            )
        }
    }

    func testFindWithRealworldData_Linux() throws {
        let testCases: [FileTestCase] = [
            FileTestCase(pattern: "make", matchesCount: 4, filenames: [
                "make",
                "makelst",
                "Makefile",
                "Makefile",
            ]),
            FileTestCase(pattern: "alsa", matchesCount: 4, filenames: [
                "alsa.h",
                "alsa.c",
                "aw2-alsa.c",
                "cx88-alsa.c",
            ]),
        ]

        let linuxFilenames = try Fixtures.linuxFilenames()

        for testCase in testCases {
            let matches = find(pattern: testCase.pattern, in: linuxFilenames)
            XCTAssertEqual(
                matches.prefix(testCase.matchesCount).map { String($0.value) },
                testCase.filenames,
                line: testCase.line
            )
        }
    }
}
