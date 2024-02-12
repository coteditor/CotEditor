//
//  IssueReport.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-02-13.
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

struct IssueReport {
    
    var locale: Locale = .current
    
    
    /// The generic report title.
    var title: String {
        
        String(localized: "IssueReport.title", defaultValue: "Issue Report", table: "IssueReport", locale: self.locale, comment: "document title")
    }
    
    
    /// Report template with user environment info.
    var template: String {
        
        [[self.description,
          String(repeating: "-", count: 25),
          Heading.environment.display(for: self.locale),
          self.environment,
         ].joined(separator: String(repeating: "\n", count: 2)),
         
         Heading.allCases[1...]
            .map { $0.display(for: self.locale) }
            .joined(separator: String(repeating: "\n", count: 3))
        ].joined(separator: String(repeating: "\n", count: 3))
    }
    
    
    // MARK: Private Methods
    
    private static var issueLink = "[GitHub Issues](https://github.com/coteditor/CotEditor/issues)"
    private static var mail = "<coteditor.github@gmail.com>"
    
    
    private var description: String {
        
        String(localized: "IssueReport.description",
               defaultValue: "Fill the following template, and post it on \(Self.issueLink) or send to \(Self.mail) Please note that the contents of the sent email can be shared on the Issue page. Please write the contents either in English or in Japanese.",
               table: "IssueReport",
               comment: "%1$@ is a link to a web page and %2$@ is an e-mail")
    }
    
    
    private var environment: String {
        
        """
        - CotEditor: \(Bundle.main.shortVersion) (\(Bundle.main.bundleVersion))
        - System: macOS \(ProcessInfo.processInfo.operatingSystemVersionString)
        - Language: \(self.appLanguage ?? "–")
        """
    }
    
    
    /// The current app localization in English.
    private var appLanguage: String? {
        
        self.locale.language.languageCode.flatMap { Locale.en.localizedString(forLanguageCode: $0.identifier) }
    }
}


private extension IssueReport {
    
    enum Heading: CaseIterable {
        
        case environment
        case shortDescription
        case stepsToReproduce
        case expectedResult
        
        
        func display(for locale: Locale) -> String {
            
            (locale == .en) ? "## \(self.label(locale: locale))" : "## \(self.label(locale: .en)) (\(self.label(locale: locale)))"
        }
        
        
        private func label(locale: Locale) -> String {
            
            switch self {
                case .environment:
                    String(localized: "IssueReport.Heading.environment",
                           defaultValue: "Environment",
                           table: "IssueReport", locale: locale)
                case .shortDescription:
                    String(localized: "IssueReport.Heading.shortDescription",
                           defaultValue: "Short Description",
                           table: "IssueReport", locale: locale)
                case .stepsToReproduce:
                    String(localized: "IssueReport.Heading.stepsToReproduce",
                           defaultValue: "Steps to Reproduce the Issue",
                           table: "IssueReport", locale: locale)
                case .expectedResult:
                    String(localized: "IssueReport.Heading.expectedResult",
                           defaultValue: "Expected Result",
                           table: "IssueReport", locale: locale)
            }
        }
    }
}


private extension Locale {
    
    static let en = Locale(identifier: "en")
}
