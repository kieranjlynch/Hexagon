//
//  Untitled.swift
//  Hexagon
//
//  Created by Kieran Lynch on 23/09/2024.
//

import SwiftUI

public struct IdentifiableError: Identifiable, Equatable, Error {
    public var id = UUID()
    let error: Error
    let message: String
    
    init(error: Error) {
        self.error = error
        self.message = error.localizedDescription
    }
    
    init(message: String) {
        self.error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
        self.message = message
    }
    
    public static func == (lhs: IdentifiableError, rhs: IdentifiableError) -> Bool {
        lhs.id == rhs.id && lhs.message == rhs.message
    }
}
