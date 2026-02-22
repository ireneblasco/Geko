//
//  PaywallView.swift
//  Geko
//
//  HabitKit Pro-style paywall: subscription options, features list, Continue button.
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
            ScrollView {
                VStack(spacing: 24) {
                    subscriptionOptionsSection
                    restorePurchaseLink
                    featuresSection
                    continueButton
                }
                .padding()
            }
            .navigationTitle("Unlock Geko Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
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

    private var subscriptionOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(storeManager.products, id: \.id) { product in
                subscriptionOptionRow(product: product)
            }

            if storeManager.products.isEmpty, !storeManager.isLoading {
                Text("Loading products...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let subProduct = storeManager.products.first(where: { $0.id == Products.monthlyID || $0.id == Products.annualID }) {
                Text("Recurring billing. Cancel anytime.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func subscriptionOptionRow(product: Product) -> some View {
        let isSelected = selectedProductID == product.id
        let isAnnual = product.id == Products.annualID
        let isLifetime = product.id == Products.lifetimeID

        return Button {
            selectedProductID = product.id
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .purple : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(productTitle(for: product))
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if isAnnual {
                            Text("-50%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange, in: RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    if isLifetime {
                        Text("Pay once. Unlimited access forever.")
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
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func annualFullPriceDisplay(monthly: Product) -> String {
        // 12 * monthly for strikethrough (e.g. $2.99 * 12 = $35.88)
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

    private var restorePurchaseLink: some View {
        Button {
            Task {
                _ = await storeManager.restorePurchases()
            }
        } label: {
            Text("Already subscribed? Restore purchase")
                .font(.subheadline)
                .foregroundStyle(.purple)
        }
        .disabled(storeManager.isLoading)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By subscribing you'll also unlock:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            FeatureRow(
                icon: "number",
                iconColor: .green,
                title: "Unlimited habits",
                description: "Unlimited possibilities by creating as many habits as you like"
            )
            FeatureRow(
                icon: "square.grid.2x2",
                iconColor: .blue,
                title: "Home Screen Widgets",
                description: "Show your favorite habits on your home screen"
            )
            FeatureRow(
                icon: "star",
                iconColor: .purple,
                title: "Support an Indie Developer",
                description: "Your purchase supports an independent app developer"
            )
        }
    }

    private var continueButton: some View {
        Button {
            performPurchase()
        } label: {
            if isPurchasing || storeManager.isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.purple)
        .disabled(selectedProductID == nil || isPurchasing || storeManager.isLoading)
        .accessibilityIdentifier("paywall_continue_button")
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

private struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(iconColor, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(iconColor)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PaywallView()
}
