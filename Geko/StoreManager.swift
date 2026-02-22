//
//  StoreManager.swift
//  Geko
//
//  StoreKit 2: products, purchase, restore. Updates EntitlementManager on success.
//

import Foundation
import StoreKit
import Combine
import GekoShared

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let entitlementManager = EntitlementManager.shared

    private init() {
        Task {
            await observeTransactions()
            await updateEntitlements()
        }
    }

    func loadProducts() async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        defer { Task { @MainActor in isLoading = false } }

        do {
            let loaded = try await Product.products(for: Products.allIDs)
            await MainActor.run { products = loaded }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    func purchase(_ product: Product) async -> Bool {
        await MainActor.run { isLoading = true; errorMessage = nil }
        defer { Task { @MainActor in isLoading = false } }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateEntitlements()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
            return false
        }
    }

    func restorePurchases() async -> Bool {
        await MainActor.run { isLoading = true; errorMessage = nil }
        defer { Task { @MainActor in isLoading = false } }

        do {
            try await AppStore.sync()
            await updateEntitlements()
            return entitlementManager.isPlus
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
            return false
        }
    }

    private func observeTransactions() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate == nil, Products.allIDs.contains(transaction.productID) {
                entitlementManager.setPlus(true)
                return
            }
        }
        entitlementManager.setPlus(false)
    }

    private func updateEntitlements() async {
        var hasEntitlement = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate == nil, Products.allIDs.contains(transaction.productID) {
                hasEntitlement = true
                break
            }
        }

        entitlementManager.setPlus(hasEntitlement)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }
}

private enum StoreError: Error {
    case failedVerification
}
