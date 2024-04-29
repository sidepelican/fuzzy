public protocol SourceElement {
    var searchRepresentation: [Character] { get }
}

public struct Match<Collection>: CustomDebugStringConvertible where Collection: RandomAccessCollection, Collection.Element: SourceElement {
    public typealias Element = Collection.Element
    public typealias Index = Collection.Index
    public init(value: Element, index: Index, matchedIndices: [Index], score: Int) {
        self.value = value
        self.index = index
        self.matchedIndices = matchedIndices
        self.score = score
    }
    public var value: Element
    public var index: Index
    public var matchedIndices: [Index]
    public var score: Int

    public var debugDescription: String {
        "\(index):\(value) matched=\(matchedIndices) score=\(score)"
    }
}

extension Match: Equatable where Match.Element: Equatable {}

fileprivate enum Bounus {
    static let firstCharMatch = 10
    static let matchFollowingSeparator = 20
    static let camelCaseMatch = 20
    static let adjacentMatch = 5
}

fileprivate enum Penalty {
    static let unmatchedLeadingChar = -5
    static let maxUnmatchedLeadingChar = -15
}

extension String: SourceElement {
    @inlinable
    public var searchRepresentation: [Character] {
        Array(self)
    }
}

extension Substring: SourceElement {
    @inlinable
    public var searchRepresentation: [Character] {
        Array(self)
    }
}

public func find<Collection>(
    pattern: String,
    in data: Collection
) -> [Match<Collection>]
where Collection: RandomAccessCollection,
      Collection.Element: SourceElement,
      Collection.Index == Int
{
    var matches = findNoSort(pattern: pattern, in: data)
    matches.sort { $0.score >= $1.score }
    return matches
}

public func findNoSort<Collection>(
    pattern: String,
    in data: Collection
) -> [Match<Collection>]
where Collection: RandomAccessCollection,
      Collection.Element: SourceElement,
      Collection.Index == Int
{
    guard !pattern.isEmpty else { return [] }

    let patternRunes: [Character] = Array(pattern)
    var matches = [Match<Collection>]()

    for i in data.indices {
        let candidateElement = data[i]
        var match = Match<Collection>(value: candidateElement, index: i, matchedIndices: [], score: 0)
        var bestScore = -1
        var matchedIndex = -1
        var currentAdjacentMatchBonus = 0

        let candidateRunes = candidateElement.searchRepresentation
        var lastIndex = data.endIndex
        var lastRune = Character("\0")

        for (j, candidateRune) in candidateRunes.enumerated() {
            if patternRunes.count > j && equalFold(candidateRune, patternRunes[j]) {
                var score = 0
                if j == 0 {
                    score += Bounus.firstCharMatch
                }
                if lastRune.isLowercase && candidateRune.isUppercase {
                    score += Bounus.camelCaseMatch
                }
                if j != 0 && isSeparator(lastRune) {
                    score += Bounus.matchFollowingSeparator
                }
                if let lastMatch = match.matchedIndices.last {
                    let bonus = adjacentCharBonus(
                        index: lastIndex,
                        lastMatch: lastMatch,
                        currentBonus: currentAdjacentMatchBonus
                    )
                    score += bonus
                    currentAdjacentMatchBonus += bonus
                }
                if score > bestScore {
                    bestScore = score
                    matchedIndex = j
                }
            }

            lastIndex = j
            lastRune = candidateRune
        }

        if matchedIndex != -1 {
            match.matchedIndices.append(matchedIndex)
            let penalty = matchedIndex * Penalty.unmatchedLeadingChar
            let appliedPenalty = max(penalty, Penalty.maxUnmatchedLeadingChar)
            match.score += bestScore
            match.score += appliedPenalty
        }

        let unmatchedCharactersPenalty = candidateElement.searchRepresentation.count - pattern.count
        match.score += unmatchedCharactersPenalty

        if match.matchedIndices.count == pattern.count {
            matches.append(match)
        }
    }

    return matches
}

fileprivate func equalFold(_ lhs: Character, _ rhs: Character) -> Bool {
    return lhs.lowercased() == rhs.lowercased()
}

fileprivate func adjacentCharBonus(index: Int, lastMatch: Int, currentBonus: Int) -> Int {
    if lastMatch == index {
        return currentBonus * 2 + Bounus.adjacentMatch
    }
    return 0
}

fileprivate func isSeparator(_ character: Character) -> Bool {
    let separators: [Character] = ["/", "-", "_", " ", ".", "\\"]
    return separators.contains(character)
}
