//
//  CustomOperators.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

// defines a custom operator that works with SwiftUI Binding types. The operator allows you to provide a default value for an optional Binding

import Foundation
import SwiftUI

public func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
