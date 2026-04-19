import Foundation
import PathKit
import XcodeProj

@MainActor
enum Verifier {
    static let repoRoot = Path(#filePath).parent().parent().parent()
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

    static func describe(_ traits: [String]?) -> String {
        switch traits {
        case nil: "nil"
        case let .some(arr) where arr.isEmpty: "[]"
        case let .some(arr): "\(arr)"
        }
    }

    static func mutateRemoteAndCheck(_ traits: [String]?, tmpDir: Path) throws -> [String] {
        let proj = try XcodeProj(path: fixturePath)
        guard let first = proj.pbxproj.rootObject?.remotePackages.first else {
            fatalError("No remote package in fixture")
        }
        first.traits = traits
        let outPath = tmpDir + "out-\(UUID().uuidString).xcodeproj"
        try proj.write(path: outPath)
        return try readTraitsLines(from: outPath + "project.pbxproj")
    }

    static func run() throws -> Bool {
        // MARK: Phase 1 — decode
        header("Phase 1: decode traits from fixture")

        let xcodeproj = try XcodeProj(path: fixturePath)
        guard let project = xcodeproj.pbxproj.rootObject else {
            fatalError("No root project")
        }

        for ref in project.remotePackages {
            print("Remote  \(ref.name ?? "?") traits = \(describe(ref.traits))")
        }
        for ref in project.localPackages {
            print("Local   \(ref.name ?? "?") traits = \(describe(ref.traits))")
        }

        // MARK: Phase 2 — serialization for nil / empty / populated
        header("Phase 2: nil vs [] vs populated — pbxproj traits lines")

        let tmpDir = try Path.uniqueTemporary()
        defer { try? tmpDir.delete() }

        print("remote traits = nil")
        for line in try mutateRemoteAndCheck(nil, tmpDir: tmpDir) { print("  \(line)") }
        print("\nremote traits = []")
        for line in try mutateRemoteAndCheck([], tmpDir: tmpDir) { print("  \(line)") }
        print("\nremote traits = [\"SQLCipher\"]")
        for line in try mutateRemoteAndCheck(["SQLCipher"], tmpDir: tmpDir) { print("  \(line)") }

        // MARK: Phase 3 — round-trip assertion
        header("Phase 3: round-trip — mutate -> write -> reload -> verify")

        let mutated = try XcodeProj(path: fixturePath)
        let target = ["SQLCipher", "FTS5", "JSON1"]
        for ref in mutated.pbxproj.rootObject?.localPackages ?? [] {
            ref.traits = target
        }

        let roundTripPath = tmpDir + "roundtrip.xcodeproj"
        try mutated.write(path: roundTripPath)

        let reloaded = try XcodeProj(path: roundTripPath)
        var allMatch = true
        for ref in reloaded.pbxproj.rootObject?.localPackages ?? [] {
            let ok = ref.traits == target
            print("  \(ref.name ?? "?") traits = \(describe(ref.traits)) \(ok ? "[OK]" : "[FAIL]")")
            if !ok { allMatch = false }
        }

        // MARK: Phase 4 — nil/empty semantic invariant
        header("Phase 4: nil vs [] semantic invariant")

        let refNil = XCRemoteSwiftPackageReference(repositoryURL: "https://example.com/A", versionRequirement: .exact("1.0.0"), traits: nil)
        let refEmpty = XCRemoteSwiftPackageReference(repositoryURL: "https://example.com/A", versionRequirement: .exact("1.0.0"), traits: [])
        let refFoo = XCRemoteSwiftPackageReference(repositoryURL: "https://example.com/A", versionRequirement: .exact("1.0.0"), traits: ["Foo"])

        let nilVsEmpty = refNil != refEmpty
        let emptyVsFoo = refEmpty != refFoo
        let nilVsFoo = refNil != refFoo
        print("  refNil   != refEmpty  \(nilVsEmpty ? "[OK]" : "[FAIL]")")
        print("  refEmpty != refFoo    \(emptyVsFoo ? "[OK]" : "[FAIL]")")
        print("  refNil   != refFoo    \(nilVsFoo ? "[OK]" : "[FAIL]")")

        let invariantOK = nilVsEmpty && emptyVsFoo && nilVsFoo

        // MARK: Summary
        header("Summary")
        return allMatch && invariantOK
    }
}

let ok = try Verifier.run()
print(ok ? "ALL CHECKS PASSED" : "SOME CHECKS FAILED")
exit(ok ? 0 : 1)
