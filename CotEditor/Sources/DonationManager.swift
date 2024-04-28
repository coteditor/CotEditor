//
//  DonationManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-04-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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

import Foundation
import Observation
import StoreKit

enum Donation {
    
    static let groupID = "21481959"
    
    enum ProductID {
        
        static let onetime = "com.coteditor.CotEditor.donation.onetime"
        static let continuous = "com.coteditor.CotEditor.donation.continuous.yearly"
    }
}


enum BadgeType: Int, CaseIterable, Equatable {
    
    case mug
    case invisible
    
    
    var symbolName: String {
        
        switch self {
            case .mug: "mug"
            case .invisible: "circle.dotted"
        }
    }
}


@MainActor @Observable final class DonationManager {
    
    // MARK: Public Properties
    
    static let shared = DonationManager()
    
    
    // MARK: Private Properties
    
    private var purchasedTransactions: Set<Transaction> = []
    private var transactionObservationTask: Task<Void, Never>?
    
    
    // MARK: Lifecycle
    
   init() {
       
       self.transactionObservationTask = Task(priority: .background) { [unowned self] in
           for await result in Transaction.updates {
               self.updatePurchase(result)
           }
       }
   }
    
    
    // MARK: Public Methods
    
    /// Whether the user has a valid continuous donation.
    var hasDonated: Bool {
        
        self.purchasedTransactions.contains { $0.subscriptionGroupID == Donation.groupID }
    }
    
    
    /// Update purchased donations.
    func updatePurchasedProducts() async {
        
        for await result in Transaction.currentEntitlements {
            self.updatePurchase(result)
        }
    }
    
    
    // MARK: Private Methods
    
    /// Update the purchased items.
    ///
    /// - Parameter result: The transaction verification result to update.
    private func updatePurchase(_ result: VerificationResult<Transaction>) {
        
        guard case .verified(let transaction) = result else { return }
        
        if transaction.revocationDate == nil {
            self.purchasedTransactions.insert(transaction)
        } else {
            self.purchasedTransactions.remove(transaction)
        }
    }
}
