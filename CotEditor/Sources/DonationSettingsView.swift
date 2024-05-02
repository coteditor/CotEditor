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
//  © 2023-2024 1024jp
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

@MainActor struct DonationSettingsView: View {
    
#if SPARKLE
    var isInAppPurchaseAvailable = false
#else
    var isInAppPurchaseAvailable = true
#endif
    
    @AppStorage(.donationBadgeType) private var badgeType: BadgeType
    
    @State private var error: (any Error)?
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
                        
                        ProductView(id: Donation.ProductID.continuous, prefersPromotionalIcon: true) {
                            Image(.bagCoffee)
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                                .productIconBorder()
                        }
                        
                        Link(String(localized: "Manage subscriptions", table: "DonationSettings"),
                             destination: URL(string: "itms-apps://apps.apple.com/account/subscriptions")!)
                        .textScale(.secondary)
                        .foregroundStyle(.tint)
                        .frame(maxWidth: .infinity)
                        .opacity(self.hasDonated ? 1 : 0)
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
                            
                            Text("As a proof of your kind support, a coffee badge appears on the status bar during continuous support.", tableName: "DonationSettings")
                                .foregroundStyle(.secondary)
                                .controlSize(.small)
                        }.disabled(!self.hasDonated)
                    }
                    .subscriptionStatusTask(for: Donation.groupID) { taskState in
                        self.hasDonated = taskState.value?.map(\.state).contains(.subscribed) == true
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading) {
                        Text("One-time donation", tableName: "DonationSettings")
                            .font(.system(size: 14))
                        
                        ProductView(id: Donation.ProductID.onetime, prefersPromotionalIcon: true) {
                            Image(.espresso)
                        }.productViewStyle(OnetimeProductViewStyle())
                    }
                }
                .overlay(alignment: .top) {
                    if let error = self.error {
                        VStack {
                            let description = switch error {
                            case StoreKitError.networkError:
                                String(localized: "An internet connection is required to donate.", table: "DonationSettings")
                            default:
                                error.localizedDescription
                            }
                            Text("Donation is currently not available.", tableName: "DonationSettings")
                            Text(description)
                                .foregroundStyle(.tertiary)
                                .textScale(.secondary)
                        }
                        .textSelection(.enabled)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.background.shadow(.drop(radius: 3, y: 1.5)),
                                    in: RoundedRectangle(cornerRadius: 8))
                        .offset(y: 40)
                    }
                }
                .storeProductsTask(for: Donation.ProductID.allCases) { taskState in
                    self.error = switch taskState {
                        case .failure(let error): error
                        default: nil
                    }
                }
                
            } else {
                VStack(alignment: .center) {
                    Image(.bagCoffee)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 6)
                    Text("The donation feature is available only in CotEditor distributed in the App Store.", tableName: "DonationSettings")
                        .foregroundStyle(.secondary)
                    
                    if let url = URL(string: "itms-apps://itunes.apple.com/app/id1024640650") {
                        Link(String(localized: "Open in App Store", table: "DonationSettings"), destination: url)
                    }
                    if let url = URL(string: "https://github.com/sponsors/1024jp/") {
                        Link(String(localized: "Open GitHub Sponsors", table: "DonationSettings", comment: "\"GitHub Sponsors\" is the name of a service by GitHub. Check the official localization if exists."), destination: url)
                    }
                }
                .buttonStyle(CapsuleButtonStyle())
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            HStack {
                Spacer()
                HelpButton(anchor: "settings_appearance")
            }
        }
        .scenePadding()
        .frame(minWidth: 600, idealWidth: 600)
    }
}


private struct CapsuleButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        
        configuration.label
            .padding(.vertical, 2)
            .padding(.horizontal, 10)
            .foregroundStyle(.tint)
            .background(.fill.tertiary, in: Capsule())
    }
}


private struct OnetimeProductViewStyle: ProductViewStyle {
    
    @Environment(\.purchase) private var purchase: PurchaseAction
    
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
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
                .productIconBorder()
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(product.displayName)
                        .fixedSize()
                    Text("× \(self.quantity)", tableName: "DonationSettings", comment: "multiple sign for the quantity of items to purchase")
                        .monospacedDigit()
                        .frame(minWidth: 28, alignment: .trailing)
                    
                    Stepper(value: $quantity, in: 1...99, label: EmptyView.init)
                    
                    Spacer()
                    Button((product.price * Decimal(self.quantity)).formatted(product.priceFormatStyle)) {
                        Task {
                            do {
                                _ = try await self.purchase(product, options: [.quantity(self.quantity)])
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    .monospacedDigit()
                    .fixedSize()
                    .contentTransition(.numericText())
                    .animation(.default, value: self.quantity)
                }
                
                Text(product.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }.alert(error: $error)
        }
    }
}


private extension BadgeType {
    
    var label: String {
        
        switch self {
            case .mug:
                String(localized: "BadgeType.mug.label",
                       defaultValue: "Coffee Mug",
                       table: "DonationSettings")
            case .invisible:
                String(localized: "BadgeType.invisible.label",
                       defaultValue: "Invisible Coffee",
                       table: "DonationSettings")
        }
    }
}



// MARK: - Preview

#Preview {
    DonationSettingsView(isInAppPurchaseAvailable: true)
}

#Preview("Non-AppStore version") {
    DonationSettingsView(isInAppPurchaseAvailable: false)
}
