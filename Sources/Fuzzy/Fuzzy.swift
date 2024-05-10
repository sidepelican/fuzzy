public protocol SearchElement {
    var searchRepresentation: [Character] { get }
}

public struct Match<Collection>: CustomDebugStringConvertible where Collection: RandomAccessCollection, Collection.Element: SearchElement {
    public typealias Element = Collection.Element
    public typealias Index = Collection.Index
    public init(value: Element, index: Index, matchedIndices: [Int], score: Int) {
        self.value = value
        self.index = index
        self.matchedIndices = matchedIndices
        self.score = score
    }
    public var value: Element
    public var index: Index
    public var matchedIndices: [Int]
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

extension String: SearchElement {
    @inlinable
    public var searchRepresentation: [Character] {
        Array(self)
    }
}

extension Substring: SearchElement {
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
      Collection.Element: SearchElement
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
      Collection.Element: SearchElement
{
    guard !pattern.isEmpty else { return [] }

    let patternRunes: [Character] = Array(pattern)
    
    var matches = [Match<Collection>]()
    for i in data.indices {
        if let match = matchTest(
            patternRunes: patternRunes,
            candidateRunes: data[i].searchRepresentation
        ) {
            matches.append(.init(
                value: data[i],
                index: i,
                matchedIndices: match.matchedIndices,
                score: match.score
            ))
        }
    }

    return matches
}

fileprivate func matchTest(
    patternRunes: [Character],
    candidateRunes: [Character]
) -> (matchedIndices: [Int], score: Int)? {
    var matchedIndices: [Int] = []
    var totalScore = 0
    var patternIndex = patternRunes.startIndex
    var bestScore = -1
    var matchedIndex: Int?
    var currentAdjacentMatchBonus = 0

    var lastIndex = candidateRunes.startIndex
    var lastRune = Character("\0")

    for candidateIndex in candidateRunes.indices {
        let candidateRune = candidateRunes[candidateIndex]
        if equalFold(candidateRune, patternRunes[patternIndex]) {
            var score = 0
            if candidateIndex == candidateRunes.startIndex {
                score += Bounus.firstCharMatch
            }
            if lastRune.isLowercase && candidateRune.isUppercase {
                score += Bounus.camelCaseMatch
            }
            if candidateIndex != candidateRunes.startIndex && isSeparator(lastRune) {
                score += Bounus.matchFollowingSeparator
            }
            if let lastMatch = matchedIndices.last {
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
                matchedIndex = candidateIndex
            }
        }

        if let matchedIndex {
            let nextPattern = patternRunes[safe: patternIndex + 1]
            let nextCandidate = candidateRunes[safe: candidateIndex + 1]
            if equalFold(nextPattern, nextCandidate) || nextCandidate == nil {
                if matchedIndices.isEmpty {
                    let penalty = matchedIndex * Penalty.unmatchedLeadingChar
                    bestScore += max(penalty, Penalty.maxUnmatchedLeadingChar)
                }
                totalScore += bestScore
                matchedIndices.append(matchedIndex)
                bestScore = -1
                patternIndex += 1
            }
        }

        lastIndex = candidateIndex
        lastRune = candidateRune
    }

    let unmatchedCharactersPenalty = matchedIndices.count - candidateRunes.count
    totalScore += unmatchedCharactersPenalty

    if matchedIndices.count == patternRunes.count {
        return (matchedIndices: matchedIndices, score: totalScore)
    }
    return nil
}

fileprivate func equalFold(_ lhs: Character, _ rhs: Character) -> Bool {
    return lhs.lowercased() == rhs.lowercased()
}

fileprivate func equalFold(_ lhs: Character?, _ rhs: Character?) -> Bool {
    guard let lhs, let rhs else { return false }
    return equalFold(lhs, rhs)
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

extension Array {
    fileprivate subscript(safe index: Index) -> Element? {
        guard self.indices.contains(index) else {
            return nil
        }
        return self[index]
    }
}
