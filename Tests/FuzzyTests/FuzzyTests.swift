import Fuzzy
import Testing

@Suite struct FuzzyTests {
    @Test func findWithUnicode() {
        let matches = find(pattern: "\u{1F41D}", in: ["\u{1F41D}"])
        #expect(matches.count == 1)
    }

    struct CannedDataTestCase {
        var pattern: String
        var data: [String]
        var expected: [Match<[String]>]
    }
    @Test(arguments: [
        // first character and camel case bonuses, and unmatched characters penalty
        // (m = 10, n = 20, r = 20) - 18 unmatched chars = 32
        CannedDataTestCase(
            pattern: "mnr",
            data: ["moduleNameResolver.ts"],
            expected: [Match(value: "moduleNameResolver.ts", index: 0, matchedIndices: [0, 6, 10], score: 32)]
        ),
        CannedDataTestCase(
            pattern: "mmt",
            data: ["mémeTemps"],
            expected: [Match(value: "mémeTemps", index: 0, matchedIndices: [0, 2, 4], score: 24)]
        ),
        // Ranking
        CannedDataTestCase(
            pattern: "mnr",
            data: ["moduleNameResolver.ts", "my name is_Ramsey"],
            expected: [
                Match(value: "my name is_Ramsey", index: 1, matchedIndices: [0, 3, 11], score: 36),
                Match(value: "moduleNameResolver.ts", index: 0, matchedIndices: [0, 6, 10], score: 32)
            ]
        ),
        // Simple repeated pattern and adjacent match bonus
        CannedDataTestCase(
            pattern: "aaa",
            data: ["aaa", "bbb"],
            expected: [Match(value: "aaa", index: 0, matchedIndices: [0, 1, 2], score: 30)]
        ),
        // Exhaustive matching
        CannedDataTestCase(
            pattern: "tk",
            data: ["The Black Knight"],
            expected: [Match(value: "The Black Knight", index: 0, matchedIndices: [0, 10], score: 16)]
        ),
        // Any unmatched character in the pattern removes the whole match
        CannedDataTestCase(
            pattern: "cats",
            data: ["cat"],
            expected: []
        ),
        // Empty patterns return no matches
        CannedDataTestCase(
            pattern: "",
            data: ["cat"],
            expected: []
        ),
        // Separator bonus
        CannedDataTestCase(
            pattern: "abcx",
            data: ["abc\\x"],
            expected: [Match(value: "abc\\x", index: 0, matchedIndices: [0, 1, 2, 4], score: 49)]
        )
    ])
    func findWithCannedData(testCase: CannedDataTestCase) {
        let matches = find(pattern: testCase.pattern, in: testCase.data)
        #expect(matches == testCase.expected)
    }

    struct FileTestCase {
        var pattern: String
        var matchesCount: Int
        var filenames: [String]
    }

    @Test(arguments: [
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
    ])
    func findWithRealworldData_UE4(testCase: FileTestCase) throws {
        let matches = find(pattern: testCase.pattern, in: Fixtures.ue4Filenames)
        #expect(
            matches.prefix(testCase.matchesCount).map { String($0.value) } == testCase.filenames
        )
    }

    @Test(arguments: [
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
    ])
    func findWithRealworldData_Linux(testCase: FileTestCase) throws {
        let matches = find(pattern: testCase.pattern, in: Fixtures.linuxFilenames)
        #expect(
            matches.prefix(testCase.matchesCount).map { String($0.value) } == testCase.filenames
        )
    }
}
