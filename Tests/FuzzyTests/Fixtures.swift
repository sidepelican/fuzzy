import Foundation

enum Fixtures {
    static func linuxFilenames() throws -> [Substring] {
        let linuxURL = Bundle.module.url(forResource: "linux_filenames", withExtension: "txt")!
        return try String(contentsOf: linuxURL).split(separator: "\n")
    }

    static func ue4Filenames() throws -> [Substring] {
        let ue4URL = Bundle.module.url(forResource: "ue4_filenames", withExtension: "txt")!
        return try String(contentsOf: ue4URL).split(separator: "\n")
    }
}
