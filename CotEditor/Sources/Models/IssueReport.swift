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
    
    // MARK: Public Methods
    
    /// The generic report title.
    var title: String {
        
        String(localized: "IssueReport.title", defaultValue: "Issue Report", table: "IssueReport", comment: "document title")
    }
    
    
    /// The plain-text report template with user environment.
    var template: String {
        
        [[self.description,
          String(repeating: "-", count: 25),
          Heading.environment.display(),
          self.environment,
         ].joined(separator: String(repeating: "\n", count: 2)),
         
         Heading.allCases[1...]
            .map { $0.display() }
            .joined(separator: String(repeating: "\n", count: 3)),
        ].joined(separator: String(repeating: "\n", count: 3)) + "\n"
    }
    
    
    // MARK: Private Methods
    
    private static let issueLink = "[GitHub Issues](https://github.com/coteditor/CotEditor/issues)"
    private static let mail = "<coteditor.github@gmail.com>"
    
    
    private var description: String {
        
        String(localized: "IssueReport.description",
               defaultValue: "Fill the following template, and post it on \(Self.issueLink) or send to \(Self.mail). Please note that the contents of the sent email can be shared on the Issue page. Please write the contents either in English or in Japanese.",
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
        
        Locale(languageCode: .english).localizedString(forLanguageCode: Locale.current.language.maximalIdentifier)
    }
}


private extension IssueReport {
    
    enum Heading: CaseIterable {
        
        case environment
        case shortDescription
        case stepsToReproduce
        case expectedResult
        
        
        /// Returns the markdown heading string.
        func display() -> String {
            
            (Locale.current.language.languageCode == .english)
                ? "## \(self.label())"
                : "## \(self.label(language: .english)) (\(self.label()))"
        }
        
        
        /// The label string for the given language.
        ///
        /// - Parameter language: The language.
        /// - Returns: A label string.
        private func label(language: Locale.LanguageCode? = nil) -> String {
            
            var resource = self.labelResource
            if let language {
                resource.locale = Locale(languageCode: language)
            }
            
            return String(localized: resource)
        }
        
        
        /// The localized string resource for the label.
        private var labelResource: LocalizedStringResource {
            
            switch self {
                case .environment:
                    LocalizedStringResource("IssueReport.Heading.environment",
                                            defaultValue: "Environment",
                                            table: "IssueReport")
                case .shortDescription:
                    LocalizedStringResource("IssueReport.Heading.shortDescription",
                                            defaultValue: "Short Description",
                                            table: "IssueReport")
                case .stepsToReproduce:
                    LocalizedStringResource("IssueReport.Heading.stepsToReproduce",
                                            defaultValue: "Steps to Reproduce the Issue",
                                            table: "IssueReport")
                case .expectedResult:
                    LocalizedStringResource("IssueReport.Heading.expectedResult",
                                            defaultValue: "Expected Result",
                                            table: "IssueReport")
            }
        }
    }
}
