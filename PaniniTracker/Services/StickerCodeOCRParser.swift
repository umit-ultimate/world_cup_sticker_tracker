import Foundation

// Lightweight, UI-independent parser + validator for sticker codes in OCR text.
//
// `parseLine` / `parse` do raw regex extraction only.
// `validate(lines:countries:)` filters those candidates against the album catalog
// and a confidence threshold, returning accepted codes + rejected candidates.
//
// Supported formats (case-insensitive):
//   AUT 20   AUT20   AUT-20   AUT_20
//
// Country code: 2-4 letters. Sticker number: 1-3 digits.
struct StickerCodeOCRParser {

    struct ParsedCode: Equatable, Identifiable {
        let countryCode: String   // normalized uppercase
        let number: Int
        let rawMatch: String      // the exact substring matched
        var id: String { "\(countryCode)-\(number)" }
        var display: String { String(format: "%@ %02d", countryCode, number) }
    }

    // Matches a 2-4 letter run, an optional single space/-/_ separator, then 1-3 digits.
    private static let pattern = "[A-Za-z]{2,4}[ \\-_]?[0-9]{1,3}"
    private let regex = try! NSRegularExpression(pattern: StickerCodeOCRParser.pattern)

    // Parses every line, deduplicating by (countryCode, number).
    func parse(lines: [String]) -> [ParsedCode] {
        var seen = Set<String>()
        var results: [ParsedCode] = []
        for line in lines {
            for code in parseLine(line) where seen.insert(code.id).inserted {
                results.append(code)
            }
        }
        return results
    }

    // Parses a single line, returning every code-shaped token it contains.
    func parseLine(_ line: String) -> [ParsedCode] {
        let ns = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: ns.length))
        return matches.compactMap { match in
            let raw = ns.substring(with: match.range)
            return Self.makeCode(from: raw)
        }
    }

    // Splits a matched token like "AUT-20" into ("AUT", 20).
    private static func makeCode(from raw: String) -> ParsedCode? {
        let letters = raw.prefix(while: { $0.isLetter })
        let rest = raw.dropFirst(letters.count)
        let digits = rest.drop(while: { $0 == " " || $0 == "-" || $0 == "_" })
        guard letters.count >= 2, let number = Int(digits) else { return nil }
        return ParsedCode(
            countryCode: letters.uppercased(),
            number: number,
            rawMatch: raw
        )
    }

    // MARK: - Validation layer

    // Why a candidate was rejected during validation.
    enum Rejection: Equatable {
        case lowConfidence(Float)
        case unknownCountry(String)
        case numberOutOfRange(number: Int, max: Int)

        var description: String {
            switch self {
            case .lowConfidence(let c):
                return String(format: "low OCR confidence (%.0f%%)", c * 100)
            case .unknownCountry(let code):
                return "country code \"\(code)\" not in album catalog"
            case .numberOutOfRange(let number, let max):
                return "sticker number \(number) out of range (1–\(max))"
            }
        }
    }

    struct RejectedCandidate: Identifiable {
        let parsed: ParsedCode
        let confidence: Float
        let reason: Rejection
        var id: String { "\(parsed.rawMatch)|\(reason.description)" }
    }

    struct ValidationOutput {
        let accepted: [ParsedCode]            // valid album stickers, deduped
        let rejected: [RejectedCandidate]     // everything filtered out, with reason
    }

    // Parses OCR lines (each carrying its own confidence) and keeps only candidates
    // that are real album stickers above the confidence threshold.
    //
    // A candidate is accepted only if ALL hold:
    //   1. confidence >= minConfidence
    //   2. countryCode exists in `countries`
    //   3. 1 <= number <= that country's stickerCount
    //
    // Checks run in order, so each rejected candidate reports its first failing reason.
    func validate(
        lines: [(text: String, confidence: Float)],
        countries: [Country],
        minConfidence: Float = 0.70
    ) -> ValidationOutput {
        let catalog = Dictionary(countries.map { ($0.code, $0.stickerCount) }, uniquingKeysWith: { a, _ in a })

        var acceptedSeen = Set<String>()
        var rejectedSeen = Set<String>()
        var accepted: [ParsedCode] = []
        var rejected: [RejectedCandidate] = []

        for line in lines {
            for code in parseLine(line.text) {
                // 1. Confidence gate
                if line.confidence < minConfidence {
                    addRejected(RejectedCandidate(parsed: code, confidence: line.confidence,
                                                  reason: .lowConfidence(line.confidence)),
                                into: &rejected, seen: &rejectedSeen)
                    continue
                }
                // 2. Country must exist
                guard let stickerCount = catalog[code.countryCode] else {
                    addRejected(RejectedCandidate(parsed: code, confidence: line.confidence,
                                                  reason: .unknownCountry(code.countryCode)),
                                into: &rejected, seen: &rejectedSeen)
                    continue
                }
                // 3. Number must be in range
                guard code.number >= 1, code.number <= stickerCount else {
                    addRejected(RejectedCandidate(parsed: code, confidence: line.confidence,
                                                  reason: .numberOutOfRange(number: code.number, max: stickerCount)),
                                into: &rejected, seen: &rejectedSeen)
                    continue
                }
                // Accept (dedupe by code+number)
                if acceptedSeen.insert(code.id).inserted {
                    accepted.append(code)
                }
            }
        }

        return ValidationOutput(accepted: accepted, rejected: rejected)
    }

    private func addRejected(_ candidate: RejectedCandidate,
                             into rejected: inout [RejectedCandidate],
                             seen: inout Set<String>) {
        if seen.insert(candidate.id).inserted {
            rejected.append(candidate)
        }
    }
}
