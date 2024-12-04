//
//  ViewState.swift
//  Hexagon
//
//  Created by Kieran Lynch on 13/11/2024.
//

import SwiftUI
import Combine

public enum ViewState<State: Equatable>: Equatable {
    case idle
    case loading
    case searching
    case loaded(State)
    case noResults
    case results(State)
    case error(String)

    public static func == (lhs: ViewState<State>, rhs: ViewState<State>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
            (.loading, .loading),
            (.searching, .searching),
            (.noResults, .noResults):
            return true
        case (.loaded(let lhs), .loaded(let rhs)),
            (.results(let lhs), .results(let rhs)):
            return lhs == rhs
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }

    public func get() throws -> State {
        switch self {
        case .loaded(let state):
            return state
        case .results(let state):
            return state
        case .loading:
            throw ViewStateError.loading
        case .error(let message):
            throw ViewStateError.error(message)
        case .idle:
            throw ViewStateError.invalidState("Idle state")
        case .searching:
            throw ViewStateError.invalidState("Searching state")
        case .noResults:
            throw ViewStateError.invalidState("No results state")
        }
    }
}

enum ViewStateError: LocalizedError {
    case loading
    case error(String)
    case invalidState(String)

    var errorDescription: String? {
        switch self {
        case .loading:
            return "State is loading"
        case .error(let message):
            return message
        case .invalidState(let state):
            return "Invalid state: \(state)"
        }
    }
}
