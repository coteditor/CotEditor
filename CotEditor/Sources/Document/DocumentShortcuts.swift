//
//  DocumentShortcuts.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-17.
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

import AppIntents
import class AppKit.NSDocumentController

struct DocumentShortcuts: AppShortcutsProvider {
    
    static var appShortcuts: [AppShortcut] {
        
        AppShortcut(intent: CreateDocumentIntent(),
                    phrases: [
                        "Create a document in \(.applicationName)",
                    ],
                    shortTitle: LocalizedStringResource("CreateDocumentIntent.shortTitle",
                                                        defaultValue: "Create Document", table: "Intents"),
                    systemImageName: "text.document")
    }
    
    static let shortcutTileColor: ShortcutTileColor = .lime
}


struct CreateDocumentIntent: AppIntent {
    
    static let title = LocalizedStringResource("CreateDocumentIntent.title",
                                               defaultValue: "Create Document", table: "Intents")
    
    static let description = IntentDescription(
        LocalizedStringResource("CreateDocumentIntent.description",
                                defaultValue: "Create a new document with the specified text in CotEditor.",
                                table: "Intents")
    )
    
    static let openAppWhenRun: Bool = true
    
    @Parameter(title: LocalizedStringResource("CreateDocumentIntent.Parameter.contents",
                                              defaultValue: "Contents", table: "Intents"),
               inputOptions: .init(multiline: true))
    var contents: String?
    
    
    @MainActor func perform() async throws -> some IntentResult {
        
        try (DocumentController.shared as! DocumentController).openUntitledDocument(contents: self.contents ?? "", display: true)
        
        return .result()
    }
}
