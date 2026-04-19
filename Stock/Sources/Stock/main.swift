import Foundation
import PathKit
import XcodeProj

@MainActor
enum Verifier {
    static let repoRoot = Path(#filePath).parent().parent().parent().parent()
    static let fixturePath = repoRoot + "Fixtures" + "ProjectWithSwiftPackageTraits.xcodeproj"

    static func header(_ s: String) {
        print("\n--- \(s) ---")
    }

    static func readTraitsLines(from pbxprojPath: Path) throws -> [String] {
        let content = try String(contentsOf: pbxprojPath.url, encoding: .utf8)
        var result: [String] = []
        var inside = false
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("traits = (") {
                inside = true
                result.append(trimmed)
                if trimmed.contains(");") {
                    inside = false
                }
            } else if inside {
                result.append(trimmed)
                if trimmed.hasPrefix(");") || trimmed.hasSuffix(");") {
                    inside = false
                }
            }
        }
        return result
    }

    static func run() throws -> Bool {
        header("Stock XcodeProj 9.11.0: load fixture, write, inspect traits survival")

        let tmpDir = try Path.uniqueTemporary()
        defer { try? tmpDir.delete() }

        print("fixture: \(fixturePath.string)")
        let before = try readTraitsLines(from: fixturePath + "project.pbxproj")
        print("fixture has \(before.count) trait-related lines:")
        for line in before { print("  \(line)") }

        let xcodeproj = try XcodeProj(path: fixturePath)
        let outPath = tmpDir + "roundtrip.xcodeproj"
        try xcodeproj.write(path: outPath)

        let after = try readTraitsLines(from: outPath + "project.pbxproj")
        print("\nafter load -> write: \(after.count) trait-related lines:")
        for line in after { print("  \(line)") }

        let preserved = !after.isEmpty
        print("\nResult: traits preserved in output pbxproj = \(preserved ? "YES" : "NO")")
        // Expected for stock 9.11.0: NO (the field is unknown so the library drops it on write)
        return !preserved
    }
}

let demonstratesBug = try Verifier.run()
print(demonstratesBug
      ? "EXPECTED: Stock dropped traits on write. Upgrading to the branch is required to preserve them."
      : "UNEXPECTED: Stock preserved traits. The branch may not be needed here.")
exit(demonstratesBug ? 0 : 1)
