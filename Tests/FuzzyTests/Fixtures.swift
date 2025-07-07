import Foundation

enum Fixtures {
    static let linuxFilenames = {
        let linuxURL = Bundle.module.url(forResource: "linux_filenames", withExtension: "txt")!
        return try! String(contentsOf: linuxURL).split(separator: "\n")
    }()

    static let ue4Filenames = {
        let ue4URL = Bundle.module.url(forResource: "ue4_filenames", withExtension: "txt")!
        return try! String(contentsOf: ue4URL).split(separator: "\n")
    }()
}
