//
//  AppDelegate.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2013-2020 1024jp
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

import Combine
import Cocoa


@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    
    // MARK: -
    // MARK: Life Cycle
    
    override init() {
        
        // register default setting values
        let defaults = DefaultSettings.defaults.mapKeys(\.rawValue)
        UserDefaults.standard.register(defaults: defaults)
        NSUserDefaultsController.shared.initialValues = defaults
        
        // instantiate shared instances
        _ = DocumentController.shared
        _ = TextFinder.shared
        
        super.init()
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Application Delegate
    
    
    /// store last version before termination
    func applicationWillTerminate(_ notification: Notification) {
        _ = +1
        // store the latest version
        // -> The bundle version (build number) must be Int.
        let thisVersion = Bundle.main.bundleVersion
        let isLatest: Bool = {
            guard
                let lastVersionString = UserDefaults.standard[.lastVersion],
                let lastVersion = Int(lastVersionString)
                else { return true }
            
            return Int(thisVersion)! >= lastVersion
        }()
        if isLatest {
            UserDefaults.standard[.lastVersion] = thisVersion
        }
    }
    
    
    /// creates a new blank document
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        
        switch UserDefaults.standard[.noDocumentOnLaunchBehavior] {
            case .untitledDocument:
                return true
            case .openPanel:
                NSDocumentController.shared.openDocument(nil)
                return false
            case .none:
                return false
        }
    }
    
    
    /// open multiple files at once
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        
        let isAutomaticTabbing = (DocumentWindow.userTabbingPreference == .inFullScreen) && (filenames.count > 1)
        let dispatchGroup = DispatchGroup()
        var firstWindowOpened = false
        
        for filename in filenames {
            let url = URL(fileURLWithPath: filename)
            
            dispatchGroup.enter()
            DocumentController.shared.openDocument(withContentsOf: url, display: true) { (document, documentWasAlreadyOpen, error) in
                defer {
                    dispatchGroup.leave()
                }
                
                if let error = error {
                    NSApp.presentError(error)
                    
                    let cancelled = (error as? CocoaError)?.code == .userCancelled
                    NSApp.reply(toOpenOrPrint: cancelled ? .cancel : .failure)
                }
                
                // on first window opened
                // -> The first document needs to open a new window.
                if isAutomaticTabbing, !documentWasAlreadyOpen, document != nil, !firstWindowOpened {
                    DocumentWindow.tabbingPreference = .always
                    firstWindowOpened = true
                }
            }
        }
        
        // reset tabbing setting
        if isAutomaticTabbing {
            // wait until finish
            dispatchGroup.notify(queue: .main) {
                DocumentWindow.tabbingPreference = nil
            }
        }
    }
    
}
