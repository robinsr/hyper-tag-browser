// created on 12/20/24 by robinsr

import Foundation

extension String {

  init(_ staticString: StaticString) {
    self = staticString.withUTF8Buffer {
      String(decoding: $0, as: UTF8.self)
    }
  }

  /// Returns the logical negation of `self.isEmpty`
  var notEmpty: Bool { !isEmpty }

  /// Returns a string with double quotes around it.
  var quoted: String {
    return "\"\(self)\""
  }

  var trimmed: String {
    return trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var hashId: String {
    if let encoded = String(hashValue).base64Encoded {
      return encoded.replacingAll(matching: "=", with: "")
    } else {
      return String(format: "%032x", hashValue)
    }
  }

  func split(on separtor: String = " ") -> [String] {
    self.components(separatedBy: separtor)
      .filter { !$0.isEmpty }
      .filter { $0 != " " }
  }

  func contains<S>(any strings: S) -> Bool where S: Sequence<StringProtocol> {
    for string in strings {
      if contains(string) { return true }
    }
    return false
  }

  /// The set of characters including uppercase lettrs and numbers
  static let idCharacters: String.RandomizationType = .lettersUppercase.union(.numbers)

  /**
   * Returns a string of length `length` containing only uppercase letters and numbers prefixed by `prefix`
   */
  static func randomIdentifier(_ length: Int, prefix: String = "") -> String {
    return [prefix, String.random(using: idCharacters, length: length)].joined()
  }

  /**
   * Returns an base64-based identifier string prefixed with specified prefix value
   */
  static func nonrandomIdentifier(from seed: String, prefix: String = "") -> String {
    return [prefix, seed.base64Encoded ?? String(format: "%064x", seed)].joined()
  }

  /// The type of characters to be used when randomizing a string using ``random(using:length:)-9nshh``.
  struct RandomizationType: OptionSet, Codable {
    /// Numbers.
    public static let numbers = RandomizationType(rawValue: 1 << 0)
    /// Lowercase letters.
    public static let letters = RandomizationType(rawValue: 1 << 1)
    /// Uppercase letters.
    public static let lettersUppercase = RandomizationType(rawValue: 1 << 2)
    /// Symbols.
    public static let symbols = RandomizationType(rawValue: 1 << 3)
    /// Lower- and uppercase letters.
    public static var allLetters: RandomizationType = [.letters, .lettersUppercase]
    /// Lower- and uppercase letters, numbers and symbols.
    public static var all: RandomizationType = [.letters, .lettersUppercase, .numbers, .symbols]

    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    var characters: String {
      var string = ""
      if contains(.numbers) { string += "0123456789" }
      if contains(.letters) { string += "abcdefghijklmnopqrstuvwxyz" }
      if contains(.lettersUppercase) { string += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
      if contains(.symbols) { string += "+-.,/:;!$%&()=?´`^#'*><-_" }
      return string
    }
  }

  /**
   * Generates a random string.
   *
   * - Parameters:
   *    - type: The type of characters to be used.
   *    - length: The length of the generated random string.
   *
   * - Returns: A randomly generated string based on the specified randomization types and length.
   */
  static func random(using type: RandomizationType = .allLetters, length: Int = 8) -> String {
    guard !type.isEmpty else { return "" }
    let characters = type.characters
    return String((0..<length).map { _ in characters.randomElement()! })
  }

  var trimmedTrailing: Self {
    replacingOccurrences(of: #"\s+$"#, with: "", options: .regularExpression)
  }

  func trimmingTrailing(in chars: CharacterSet = .whitespacesAndNewlines) -> Self {
    let preserved = self.prefix(while: { $0.isWhitespace })
    let remaining = self.removingPrefix(String(preserved))

    return preserved + remaining.trimmingCharacters(in: chars)
  }

  var lastWord: String {
    split(separator: " ").last?.trimmingCharacters(in: .whitespaces) ?? ""
  }

  var droppingLastWord: String {
    split(separator: " ").dropLast().joined(separator: " ")
  }

  func replacingLastWord(with word: String) -> String {
    let components = [
      self.droppingLastWord,
      word.trimmingCharacters(in: .whitespaces),
    ]

    return components.joined(separator: " ")
  }

  func appendingWord(_ word: String) -> String {
    let components = [
      self.trimmingTrailing(in: .whitespaces),
      word.trimmingCharacters(in: .whitespaces),
    ]

    return components.joined(separator: " ")
  }

  @available(*, deprecated, message: "Use `truncated(to:)` instead")
  func truncating(to number: Int, truncationIndicator: Self = "…") -> Self {
    if number <= 0 {
      return ""
    }

    if count > number {
      return String(prefix(number - truncationIndicator.count)).trimmedTrailing
        + truncationIndicator
    }

    return self
  }

  func surrounding(_ character: Character) -> Self {
    return "\(character)\(self)\(character)"
  }

  func pad() -> String {
    return " \(self) "
  }

  enum AffixingOption {
    case always(String)
    case ifAbsent(String)
  }

  func wrap(_ option: AffixingOption) -> String {
    switch option {
      case .always(let affixes):
        return wrap(affixes)

      case .ifAbsent(let affixes):
        return isAffixed(with: affixes) ? self : wrap(affixes)
    }
  }

  func wrap(_ affixes: String = "()") -> String {
    guard affixes.count % 2 == 0 else {
      fatalError("Affixes must be an even number of characters")
    }

    let prefix = String(affixes.prefix(affixes.count / 2))
    let suffix = String(affixes.suffix(affixes.count / 2))

    return "\(prefix)\(self)\(suffix)"
  }

  func isAffixed(with affixes: String) -> Bool {
    guard affixes.count % 2 == 0 else {
      fatalError("Affixes must be an even number of characters")
    }

    let prefix = String(affixes.prefix(affixes.count / 2))
    let suffix = String(affixes.suffix(affixes.count / 2))

    return hasPrefix(prefix) && hasSuffix(suffix)
  }
}
