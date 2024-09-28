//
//  QueryParser.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

// tokenizes a search query string into various components (words, phrases, operators, filters) then converts these tokens into an NSPredicate

import Foundation
public enum QueryToken {
    case word(String)
    case phrase(String)
    case and
    case or
    case not
    case wildcard
    case filter(String, String)
}

public class QueryParser {
    
    // MARK: - Tokenization
    
    public static func tokenize(_ query: String) -> [QueryToken] {
        var tokens: [QueryToken] = []
        var currentWord = ""
        var inPhrase = false
        
        for char in query {
            switch char {
            case " " where !inPhrase:
                appendCurrentWord(&tokens, &currentWord)
            case "\"":
                if inPhrase {
                    tokens.append(.phrase(currentWord))
                    currentWord = ""
                }
                inPhrase.toggle()
            case "&" where !inPhrase:
                tokens.append(.and)
            case "|" where !inPhrase:
                tokens.append(.or)
            case "!" where !inPhrase:
                tokens.append(.not)
            case "*" where !inPhrase:
                tokens.append(.wildcard)
            default:
                currentWord.append(char)
            }
        }
        
        appendCurrentWord(&tokens, &currentWord)
        
        return tokens
    }
    
    private static func appendCurrentWord(_ tokens: inout [QueryToken], _ currentWord: inout String) {
        guard !currentWord.isEmpty else { return }
        if currentWord.contains(":") {
            let parts = currentWord.split(separator: ":")
            if parts.count == 2 {
                tokens.append(.filter(String(parts[0]), String(parts[1])))
            } else {
                tokens.append(.word(currentWord))
            }
        } else {
            tokens.append(.word(currentWord))
        }
        currentWord = ""
    }
    
    // MARK: - Parsing
    
    public static func parse(_ query: String) -> NSPredicate {
        let tokens = tokenize(query)
        return buildPredicate(from: tokens)
    }
    
    private static func buildPredicate(from tokens: [QueryToken]) -> NSPredicate {
        var predicates: [NSPredicate] = []
        var currentOperator: QueryToken? = nil
        
        for token in tokens {
            switch token {
            case .word(let word), .phrase(let word):
                let predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", word, word)
                predicates.append(predicate)
            case .and:
                currentOperator = .and
            case .or:
                currentOperator = .or
            case .not:
                applyNotOperator(to: &predicates)
            case .wildcard:
                applyWildcard(to: &predicates, tokens: tokens)
            case .filter(let key, let value):
                applyFilter(key: key, value: value, to: &predicates)
            }
            
            if predicates.count > 1, let op = currentOperator {
                predicates = [combinePredicates(predicates, using: op)]
                currentOperator = nil
            }
        }
        
        return predicates.first ?? NSPredicate(value: true)
    }
    
    // MARK: - Helper Methods
    
    private static func applyNotOperator(to predicates: inout [NSPredicate]) {
        guard let lastPredicate = predicates.popLast() else { return }
        predicates.append(NSCompoundPredicate(notPredicateWithSubpredicate: lastPredicate))
    }
    
    private static func applyWildcard(to predicates: inout [NSPredicate], tokens: [QueryToken]) {
        guard let lastToken = tokens.last else { return }
        if case .word(let word) = lastToken {
            let regexPattern = wildcardToRegex(word)
            let wildcardPredicate = NSPredicate(format: "title MATCHES[cd] %@ OR notes MATCHES[cd] %@", regexPattern, regexPattern)
            predicates.append(wildcardPredicate)
        }
    }
    
    private static func applyFilter(key: String, value: String, to predicates: inout [NSPredicate]) {
        switch key {
        case "priority":
            if let priorityValue = Int16(value) {
                predicates.append(NSPredicate(format: "priority == %d", priorityValue))
            }
        case "date":
            if let datePredicate = buildDatePredicate(from: value) {
                predicates.append(datePredicate)
            }
        case "photo":
            predicates.append(NSPredicate(format: "photos.@count > 0"))
        case "link":
            predicates.append(NSPredicate(format: "url != nil AND url != ''"))
        case "tag":
            predicates.append(NSPredicate(format: "ANY tags.name ==[cd] %@", value))
        case "list":
            predicates.append(NSPredicate(format: "list.name ==[cd] %@", value))
        default:
            return
        }
    }
    
    private static func combinePredicates(_ predicates: [NSPredicate], using operatorToken: QueryToken) -> NSCompoundPredicate {
        switch operatorToken {
        case .and:
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        case .or:
            return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        default:
            fatalError("Invalid operator for combining predicates")
        }
    }
    
    private static func buildDatePredicate(from value: String) -> NSPredicate? {
        let dateRange = value.split(separator: "..")
        guard dateRange.count == 2 else { return nil }
        
        let dateFormatter = ISO8601DateFormatter()
        
        if let startDate = dateFormatter.date(from: String(dateRange[0])),
           let endDate = dateFormatter.date(from: String(dateRange[1])) {
            return NSPredicate(format: "startDate >= %@ AND endDate <= %@", startDate as NSDate, endDate as NSDate)
        } else {
            return nil
        }
    }
    
    private static func wildcardToRegex(_ pattern: String) -> String {
        "^" + pattern.replacingOccurrences(of: "*", with: ".*").replacingOccurrences(of: "?", with: ".") + "$"
    }
}
