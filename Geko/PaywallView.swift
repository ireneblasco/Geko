//
//  PaywallView.swift
//  Geko
//
//  Subscription paywall using standard iOS patterns.
//

import SwiftUI
import StoreKit
import GekoShared

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager.shared
    @ObservedObject private var entitlementManager = EntitlementManager.shared

    @State private var selectedProductID: String?
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(storeManager.products, id: \.id) { product in
                        subscriptionOptionRow(product: product)
                    }

                    if storeManager.products.isEmpty, !storeManager.isLoading {
                        HStack {
                            Spacer()
                            Text("Loading products...")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                } header: {
                    Text("Choose a plan")
                } footer: {
                    if storeManager.products.contains(where: { $0.id == Products.monthlyID || $0.id == Products.annualID }) {
                        Text("Recurring billing. Cancel anytime.")
                    }
                }

                Section {
                    Label("Unlimited habits", systemImage: "infinity")
                    Label("Home Screen Widgets", systemImage: "square.grid.2x2")
                } header: {
                    Text("Included")
                }

                Section {
                    Button {
                        Task { _ = await storeManager.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                    }
                    .disabled(storeManager.isLoading)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Geko Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        performPurchase()
                    } label: {
                        if isPurchasing || storeManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Subscribe")
                        }
                    }
                    .disabled(selectedProductID == nil || isPurchasing || storeManager.isLoading)
                    .accessibilityIdentifier("paywall_continue_button")
                }
            }
            .onAppear {
                if selectedProductID == nil {
                    selectDefaultProduct()
                }
                Task { await storeManager.loadProducts() }
            }
            .onChange(of: entitlementManager.isPlus) { _, isPlus in
                if isPlus { dismiss() }
            }
        }
        .accessibilityIdentifier("paywall_view")
    }

    private func subscriptionOptionRow(product: Product) -> some View {
        let isSelected = selectedProductID == product.id
        let isAnnual = product.id == Products.annualID
        let isLifetime = product.id == Products.lifetimeID

        return Button {
            selectedProductID = product.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(productTitle(for: product))
                        if isAnnual {
                            Text("Best Value")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if isLifetime {
                        Text("Pay once, unlimited access")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    if isAnnual, let monthly = storeManager.products.first(where: { $0.id == Products.monthlyID }) {
                        Text(annualFullPriceDisplay(monthly: monthly))
                            .strikethrough()
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(product.displayPrice)
                        .fontWeight(.medium)
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func annualFullPriceDisplay(monthly: Product) -> String {
        let annualValue = monthly.price * 12
        return annualValue.formatted(monthly.priceFormatStyle)
    }

    private func productTitle(for product: Product) -> String {
        switch product.id {
        case Products.monthlyID: return "Monthly"
        case Products.annualID: return "Annual"
        case Products.lifetimeID: return "Lifetime"
        default: return product.displayName
        }
    }

    private func selectDefaultProduct() {
        let annual = storeManager.products.first { $0.id == Products.annualID }
        let monthly = storeManager.products.first { $0.id == Products.monthlyID }
        let lifetime = storeManager.products.first { $0.id == Products.lifetimeID }
        selectedProductID = (annual ?? monthly ?? lifetime)?.id
    }

    private func performPurchase() {
        guard let id = selectedProductID,
              let product = storeManager.products.first(where: { $0.id == id }) else { return }

        isPurchasing = true
        Task {
            let success = await storeManager.purchase(product)
            await MainActor.run { isPurchasing = false }
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    PaywallView()
}
