//
//  DonationView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2026 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI
import StoreKit
import Defaults

private enum SubscriptionInformationURL: String, CaseIterable {
    
    case termsOfService = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"  // Apple’s Standard License Agreement
    case privacyPolicy = "https://coteditor.com/privacy"
    
    
    private var label: LocalizedStringResource {
        
        switch self {
            case .termsOfService: .init("Terms of Service", table: "Donation")
            case .privacyPolicy: .init("Privacy Policy", table: "Donation")
        }
    }
}


struct DonationView: View {
    
#if SPARKLE
    var isInAppPurchaseAvailable = false
#else
    var isInAppPurchaseAvailable = true
#endif
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("CotEditor provides all features for free to everyone. You can support this project by offering coffee.", tableName: "Donation")
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)
            
            if self.isInAppPurchaseAvailable {
                AppPurchaseView()
            } else {
                NoAppPurchaseView()
            }
            
            HStack {
                Spacer()
                HelpLink(anchor: "about_donation")
            }
        }
        .frame(width: 560)
    }
}


private struct NoAppPurchaseView: View {
    
    var body: some View {
        
        ContentUnavailableView {
            Image(.bagCoffee)
                .font(.system(size: 64, weight: .light))
                .accessibilityHidden(true)
            
        } description: {
            Text("The In-App donation feature is available only in CotEditor distributed in the App Store.", tableName: "Donation")
                .font(.body)
            
        } actions: {
            Link(.init("Open in App Store", table: "Donation", comment: "verb; button"),
                 destination: URL(string: "itms-apps://apps.apple.com/app/id1024640650")!)
            Link(.init("Open GitHub Sponsors", table: "Donation",
                       comment: "verb; button; \"GitHub Sponsors\" is the name of a service by GitHub. Check the official localization."),
                 destination: URL(string: "https://github.com/sponsors/1024jp/")!)
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }
}


private struct AppPurchaseView: View {
    
    @AppStorage(.donationBadgeType) private var badgeType: BadgeType
    
    @State private var error: any Error?
    @State private var storeKitError: StoreKitError?
    @State private var hasDonated = false
    
    
    var body: some View {
        
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading) {
                Text(.InAppPurchase.donationSubscriptionLabel)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                
                ProductView(id: Donation.Product.continuous.id, prefersPromotionalIcon: true) {
                    Label(.InAppPurchase.donationSubscriptionYearlyDisplayName, image: .bagCoffee)
                        .labelStyle(.iconOnly)
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                        .productIconBorder()
                }
                .fixedSize()
                
                Group {
                    if self.hasDonated {
                        Link(.init("Manage Subscriptions", table: "Donation", comment: "verb; button"),
                             destination: URL(string: "itms-apps://apps.apple.com/account/subscriptions")!)
                    } else {
                        Button(.init("Restore Subscription", table: "Donation", comment: "verb; button")) {
                            Task {
                                do {
                                    try await AppStore.sync()
                                } catch {
                                    self.presentError(error)
                                }
                            }
                        }.buttonStyle(.link)
                    }
                }
                .textScale(.secondary)
                .foregroundStyle(.tint)
                
                Text(SubscriptionInformationURL.markdown)
                    .tint(.primary)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .padding(.bottom, 8)
                
                Form {
                    Picker(.init("Badge type:", table: "Donation"), selection: $badgeType) {
                        ForEach(BadgeType.allCases, id: \.self) { item in
                            Label(item.label, systemImage: item.symbolName)
                        }
                    }
                    
                    Text("As proof of your kind support, a coffee badge appears on the status bar during continuous support.", tableName: "Donation")
                        .foregroundStyle(.secondary)
                        .controlSize(.small)
                        .fixedSize(horizontal: false, vertical: true)
                }.disabled(!self.hasDonated)
            }
            .accessibilityElement(children: .contain)
            .subscriptionStatusTask(for: Donation.groupID) { taskState in
                self.hasDonated = taskState.value?.map(\.state)
                    .contains { [.subscribed, .inGracePeriod].contains($0) } == true
            }
            
            Divider()
            
            VStack(alignment: .leading) {
                Text(.InAppPurchase.donationOnetimeLabel)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                
                ProductView(id: Donation.Product.onetime.id, prefersPromotionalIcon: true) {
                    Label(.InAppPurchase.donationOnetimeDisplayName, image: .espresso)
                        .labelStyle(.iconOnly)
                }
                .productViewStyle(OnetimeProductViewStyle())
            }
            .accessibilityElement(children: .contain)
        }
        .disabled(self.storeKitError != nil)
        .opacity((self.storeKitError == nil) ? 1 : 0.5)
        .overlay(alignment: .top) {
            if let error = self.storeKitError {
                StoreKitErrorView(error: error)
                    .offset(y: 40)
            }
        }
        .storeProductsTask(for: Donation.Product.allCases.map(\.id)) { taskState in
            switch taskState {
                case .loading, .success:
                    break
                case .failure(let error):
                    self.presentError(error, disablesDonation: true)
                @unknown default:
                    assertionFailure()
            }
        }
        .alert(error: $error)
    }
    
    
    /// Presents the given error.
    ///
    /// - Parameters:
    ///   - error: The error to present.
    ///   - disablesDonation: Whether the error means the donation products are unavailable.
    private func presentError(_ error: any Error, disablesDonation: Bool = false) {
        
        switch error {
            case StoreKitError.userCancelled:
                break
            case let error as StoreKitError where disablesDonation:
                self.storeKitError = error
            default:
                self.error = error
        }
    }
}


private struct StoreKitErrorView: View {
    
    var error: StoreKitError
    
    
    var body: some View {
        
        VStack {
            Text("Donation is currently not available.", tableName: "Donation")
            Text(self.description)
                .foregroundStyle(.secondary)
                .textScale(.secondary)
        }
        .accessibilityElement(children: .contain)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.background.shadow(.drop(radius: 4, y: 2)),
                    in: .rect(cornerRadius: 8))
    }
    
    
    /// The error description to display.
    private var description: String {
        
        switch self.error {
            case .networkError:
                String(localized: "An internet connection is required to donate.", table: "Donation",
                       comment: "error message")
            default:
                self.error.localizedDescription
        }
    }
}


private struct OnetimeProductViewStyle: ProductViewStyle {
    
    @State private var quantity = 1
    @State private var error: any Error?
    
    
    func makeBody(configuration: Configuration) -> some View {
        
        switch configuration.state {
            case .success(let product):
                self.productView(product, icon: configuration.icon)
            default:
                ProductView(configuration)
        }
    }
    
    
    /// Returns the view to display when the state is success.
    ///
    /// - Parameters:
    ///   - product: The product.
    ///   - icon: The product icon.
    /// - Returns: The view to display when the state is success.
    @ContentBuilder private func productView(_ product: Product, icon: ProductViewStyleConfiguration.Icon) -> some View {
        
        HStack(alignment: .top, spacing: 10) {
            icon
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
                .productIconBorder()
                .frame(width: 72, height: 72)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .fixedSize()
                        Text("× \(self.quantity)", tableName: "Donation", comment: "multiple sign for the quantity of items to purchase")
                            .monospacedDigit()
                            .accessibilityLabel(.init("\(self.quantity) cups", table: "Donation", comment: "accessibility label for item quantity"))
                            .frame(minWidth: 28, alignment: .trailing)
                    }.accessibilityElement(children: .combine)
                    Stepper(value: $quantity, in: 1...99, label: EmptyView.init)
                        .accessibilityValue(.init("\(self.quantity) cups", table: "Donation"))
                        .accessibilityLabel(.init("Quantity", table: "Donation", comment: "accessibility label for item quantity stepper"))
                }
                
                Text(product.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button {
                    Task {
                        do {
                            try await self.purchase(product, quantity: self.quantity)
                        } catch {
                            self.error = error
                        }
                    }
                } label: {
                    Text(product.price * Decimal(self.quantity), format: product.priceFormatStyle)
                        .font(.system(size: 11))
                }
                .monospacedDigit()
                .padding(.top, 6)
                .contentTransition(.numericText())
                .animation(.default, value: self.quantity)
            }
            .accessibilityElement(children: .contain)
        }
        .alert(error: $error)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    /// Purchases the given product with the selected quantity.
    ///
    /// - Parameters:
    ///   - product: The StoreKit product to purchase.
    ///   - quantity: The number of items to purchase.
    /// - Throws: An error if the purchase fails or the transaction cannot be verified.
    private func purchase(_ product: Product, quantity: Int) async throws {
        
        let result = try await product.purchase(options: [.quantity(quantity)])
        
        switch result {
            case .success(let verificationResult):
                switch verificationResult {
                    case .verified(let transaction):
                        await transaction.finish()
                    case .unverified(let transaction, let verificationError):
                        await transaction.finish()
                        throw verificationError
                }
            case .pending, .userCancelled:
                break
            @unknown default:
                break
        }
    }
}


private extension SubscriptionInformationURL {
    
    static var markdown: AttributedString {
        
        try! AttributedString(markdown: self.allCases.map(\.markdown).formatted(.list(type: .and)))
    }
    
    
    private var markdown: String {
        
        "[\(String(localized: self.label))](\(self.rawValue))"
    }
}


// MARK: - Preview

#Preview {
    DonationView(isInAppPurchaseAvailable: true)
        .scenePadding()
}

#Preview("Non-AppStore version") {
    DonationView(isInAppPurchaseAvailable: false)
        .scenePadding()
}

#Preview("StoreKitErrorView") {
    StoreKitErrorView(error: .notAvailableInStorefront)
        .scenePadding()
}
