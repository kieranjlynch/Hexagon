//
//  SubscriptionManager.swift
//  Hexagon
//
//  Created by Kieran Lynch on 19/09/2024.
//

import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    @Published private(set) var products: [Product] = []
    private var updatesTask: Task<Void, Never>?

    private init() {
        Task {
            await loadProducts()
        }
        updatesTask = observeTransactionUpdates()
    }

    deinit {
        updatesTask?.cancel()
    }

    private func loadProducts() async {
        let productIds = ["Annual01", "Monthly02"]
        do {
            products = try await Product.products(for: productIds)
        } catch {
            print("Error loading products: \(error)")
        }
    }

    func purchase(product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verificationResult):
            switch verificationResult {
            case .verified(let transaction):
                await transaction.finish()
            case .unverified(_, let error):
                print("Unverified transaction: \(error.localizedDescription)")
            }
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        return Task.detached {
            for await verificationResult in Transaction.updates {
                switch verificationResult {
                case .verified(let transaction):
                    await transaction.finish()
                case .unverified(_, let error):
                    print("Unverified transaction update: \(error.localizedDescription)")
                }
            }
        }
    }

    var availableProducts: [Product] {
        return products
    }
}
