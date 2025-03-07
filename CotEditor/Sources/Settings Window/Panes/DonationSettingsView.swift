//
//  DonationSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2025 1024jp
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
    
    
    private var label: String {
        
        switch self {
            case .termsOfService: String(localized: "Terms of Service", table: "DonationSettings")
            case .privacyPolicy: String(localized: "Privacy Policy", table: "DonationSettings")
        }
    }
}


struct DonationSettingsView: View {
    
#if SPARKLE
    var isInAppPurchaseAvailable = false
#else
    var isInAppPurchaseAvailable = true
#endif
    
    @AppStorage(.donationBadgeType) private var badgeType: BadgeType
    
    @State private var error: (any Error)?
    @State private var storeKitError: StoreKitError?
    @State private var hasDonated = false
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("CotEditor provides all features for free to everyone. You can support this project by offering coffee.", tableName: "DonationSettings")
                .padding(.bottom, 10)
            
            if self.isInAppPurchaseAvailable {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading) {
                        Text("Continuous support", tableName: "DonationSettings")
                            .font(.system(size: 14))
                            .accessibilityAddTraits(.isHeader)
                        
                        ProductView(id: Donation.Product.continuous.id, prefersPromotionalIcon: true) {
                            Label(String(localized: "donation.subscription.yearly.displayName", table: "InAppPurchase"), image: .bagCoffee)
                                .labelStyle(.iconOnly)
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                                .productIconBorder()
                        }
                        
                        Group {
                            if self.hasDonated {
                                Link(String(localized: "Manage Subscriptions", table: "DonationSettings"),
                                     destination: URL(string: "itms-apps://apps.apple.com/account/subscriptions")!)
                            } else {
                                Button(String(localized: "Restore Subscription", table: "DonationSettings")) {
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
                            .tint(.accentColor)
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                            .padding(.bottom, 10)
                        
                        Form {
                            Picker(String(localized: "Badge type:", table: "DonationSettings"), selection: $badgeType) {
                                ForEach(BadgeType.allCases, id: \.self) { item in
                                    HStack {
                                        Image(systemName: item.symbolName)
                                        Text(item.label)
                                    }
                                }
                            }.fixedSize()
                            
                            Text("As proof of your kind support, a coffee badge appears on the status bar during continuous support.", tableName: "DonationSettings")
                                .foregroundStyle(.secondary)
                                .controlSize(.small)
                        }.disabled(!self.hasDonated)
                    }
                    .accessibilityElement(children: .contain)
                    .subscriptionStatusTask(for: Donation.groupID) { taskState in
                        self.hasDonated = taskState.value?.map(\.state).contains(.subscribed) == true
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading) {
                        Text("One-time donation", tableName: "DonationSettings")
                            .font(.system(size: 14))
                            .accessibilityAddTraits(.isHeader)
                        
                        ProductView(id: Donation.Product.onetime.id, prefersPromotionalIcon: true) {
                            Label(String(localized: "donation.onetime.displayName", table: "InAppPurchase"), image: .espresso)
                                .labelStyle(.iconOnly)
                        }.productViewStyle(OnetimeProductViewStyle())
                    }
                    .accessibilityElement(children: .contain)
                }
                .disabled(self.storeKitError != nil)
                .opacity((self.storeKitError == nil) ? 1 : 0.5)
                .overlay(alignment: .top) {
                    if let error = self.storeKitError {
                        VStack {
                            let description = switch error {
                                case .networkError:
                                    String(localized: "An internet connection is required to donate.", table: "DonationSettings",
                                           comment: "error message")
                                default:
                                    error.localizedDescription
                            }
                            Text("Donation is currently not available.", tableName: "DonationSettings")
                            Text(description)
                                .foregroundStyle(.secondary)
                                .textScale(.secondary)
                        }
                        .textSelection(.enabled)
                        .accessibilityElement(children: .contain)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.background.shadow(.drop(radius: 3, y: 1.5)),
                                    in: .rect(cornerRadius: 8))
                        .offset(y: 40)
                    }
                }
                .storeProductsTask(for: Donation.Product.allCases.map(\.id)) { taskState in
                    switch taskState {
                        case .loading, .success:
                            break
                        case .failure(let error):
                            self.presentError(error)
                        @unknown default:
                            assertionFailure()
                    }
                }
                .alert(error: $error)
                
            } else {
                VStack(alignment: .center) {
                    Image(.bagCoffee)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 6)
                    Text("The In-App donation feature is available only in CotEditor distributed in the App Store.", tableName: "DonationSettings")
                        .foregroundStyle(.secondary)
                    
                    if let url = URL(string: "itms-apps://itunes.apple.com/app/id1024640650") {
                        Link(String(localized: "Open in App Store", table: "DonationSettings"), destination: url)
                    }
                    if let url = URL(string: "https://github.com/sponsors/1024jp/") {
                        Link(String(localized: "Open GitHub Sponsors", table: "DonationSettings", comment: "\"GitHub Sponsors\" is the name of a service by GitHub. Check the official localization."), destination: url)
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            HStack {
                Spacer()
                HelpLink(anchor: "settings_donation")
            }
        }
        .padding(.top, 14)
        .scenePadding([.horizontal, .bottom])
        .frame(minWidth: 600, idealWidth: 600)
    }
    
    
    // MARK: Private Methods
    
    /// Presents an alert in the proper way.
    ///
    /// - Parameter error: The error to present.
    private func presentError(_ error: any Error) {
        
        switch error {
            case StoreKitError.userCancelled:
                break
            case let error as StoreKitError:
                self.storeKitError = error
            default:
                self.error = error
        }
    }
}


private struct OnetimeProductViewStyle: ProductViewStyle {
    
    @State private var quantity = 1
    @State private var error: (any Error)?
    
    
    func makeBody(configuration: Configuration) -> some View {
        
        switch configuration.state {
            case .success(let product):
                self.productView(product, icon: configuration.icon)
            default:
                ProductView(configuration)
        }
    }
    
    
    /// Returns the view to display when the state is success.
    @ViewBuilder private func productView(_ product: Product, icon: ProductViewStyleConfiguration.Icon) -> some View {
        
        HStack(alignment: .top, spacing: 10) {
            icon
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
                .productIconBorder()
                .frame(width: 64, height: 64)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .fixedSize()
                        Text("× \(self.quantity)", tableName: "DonationSettings", comment: "multiple sign for the quantity of items to purchase")
                            .monospacedDigit()
                            .accessibilityLabel(String(localized: "\(self.quantity) cups", table: "DonationSettings", comment: "accessibility label for item quantity"))
                            .frame(minWidth: 28, alignment: .trailing)
                    }.accessibilityElement(children: .combine)
                    Stepper(value: $quantity, in: 1...99, label: EmptyView.init)
                        .accessibilityValue(String(localized: "\(self.quantity) cups", table: "DonationSettings"))
                        .accessibilityLabel(String(localized: "Quantity", table: "DonationSettings", comment: "accessibility label for item quantity stepper"))
                }
                
                Text(product.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button {
                    Task {
                        do {
                            _ = try await product.purchase(options: [.quantity(self.quantity)])
                        } catch {
                            self.error = error
                        }
                    }
                } label: {
                    Text((product.price * Decimal(self.quantity)).formatted(product.priceFormatStyle))
                        .font(.system(size: 11))
                }
                .monospacedDigit()
                .fixedSize()
                .padding(.top, 6)
                .contentTransition(.numericText())
                .animation(.default, value: self.quantity)
            }
            .accessibilityElement(children: .contain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .alert(error: $error)
    }
}


private extension SubscriptionInformationURL {
    
    static var markdown: AttributedString {
        
        try! AttributedString(markdown: self.allCases.map(\.markdown).formatted(.list(type: .and)))
    }
    
    
    private var markdown: String {
        
        "[\(self.label)](\(self.rawValue))"
    }
}


// MARK: - Preview

#Preview {
    DonationSettingsView(isInAppPurchaseAvailable: true)
}

#Preview("Non-AppStore version") {
    DonationSettingsView(isInAppPurchaseAvailable: false)
}
