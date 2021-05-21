//
//  DocumentWindowController.swift
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

final class DocumentWindowController: NSWindowController, NSWindowDelegate {
    
    // MARK: Public Properties
    
    var isWhitepaper = false {
        
        didSet {
            guard isWhitepaper || oldValue else { return }
            
            self.setDocumentEdited(!isWhitepaper)
        }
    }
    
    
    // MARK: Private Properties
    
    private var appearanceModeObserver: AnyCancellable?
    
    private var documentStyleObserver: AnyCancellable?
    private var styleListObserver: AnyCancellable?
    private weak var syntaxPopUpButton: NSPopUpButton?
    
    
    
    // MARK: -
    // MARK: Window Controller Methods
    
    /// prepare window
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        // -> It's set as false by default if the window controller was invoked from a storyboard.
        self.shouldCascadeWindows = true
        // -> Do not use "document" for autosave name because somehow windows forget the size with that name. (2018-09)
        self.windowFrameAutosaveName = "Document Window"
        
        // set window size
        let contentSize = NSSize(width: UserDefaults.standard[.windowWidth],
                                 height: UserDefaults.standard[.windowHeight])
        self.window!.setContentSize(contentSize)
        (self.contentViewController as! WindowContentViewController).restoreAutosavingState()
        
        // observe appearance setting change
        self.appearanceModeObserver = UserDefaults.standard.publisher(for: .documentAppearance, initial: true)
            .map { (value) in
                switch value {
                    case .default: return nil
                    case .light:   return NSAppearance(named: .aqua)
                    case .dark:    return NSAppearance(named: .darkAqua)
                }
            }
            .assign(to: \.appearance, on: self.window!)
        
        //  observe for syntax style line-up change
        self.styleListObserver = Publishers.Merge(SyntaxManager.shared.$settingNames.eraseToVoid(),
                                                  UserDefaults.standard.publisher(for: .recentStyleNames).eraseToVoid())
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.buildSyntaxPopUpButton() }
        
        if ProcessInfo().operatingSystemVersion.majorVersion < 11 {
            self.window?.styleMask.subtract(.fullSizeContentView)
        }
    }
    
    
    /// apply passed-in document instance to window
    override unowned(unsafe) var document: AnyObject? {
        
        didSet {
            guard let document = document as? Document else { return }
            
            self.contentViewController!.representedObject = document
            
            // -> In case when the window was created as a restored window (the right side ones in the browsing mode).
            if document.isInViewingMode {
                self.window?.isOpaque = true
            }
            
            self.selectSyntaxPopUpItem(with: document.syntaxParser.style.name)
            
            // observe document's style change
            self.documentStyleObserver = document.didChangeSyntaxStyle
                .receive(on: RunLoop.main)
                .sink { [weak self] in self?.selectSyntaxPopUpItem(with: $0) }
        }
    }
    
    
    override func setDocumentEdited(_ dirtyFlag: Bool) {
        
        super.setDocumentEdited(self.isWhitepaper ? false : dirtyFlag)
    }
    
    
    
    // MARK: Window Delegate
    
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        
        self.window?.isOpaque = true
    }
    
    
    func windowWillEnterVersionBrowser(_ notification: Notification) {
        
        self.window?.isOpaque = true
    }
    
    
    func windowWillExitFullScreen(_ notification: Notification) {
        
        self.restoreWindowOpacity()
    }
    
    
    func windowWillExitVersionBrowser(_ notification: Notification) {
        
        self.restoreWindowOpacity()
    }
    
    
    
    // MARK: Private Methods
    
    private func restoreWindowOpacity() {
        
        self.window?.isOpaque = (self.window as? DocumentWindow)?.backgroundAlpha == 1
    }
    
    
    /// Build syntax style popup menu in toolbar.
    private func buildSyntaxPopUpButton() {
        
        guard let menu = self.syntaxPopUpButton?.menu else { return }
        
        let styleNames = SyntaxManager.shared.settingNames
        let recentStyleNames = UserDefaults.standard[.recentStyleNames]
        let action = #selector(Document.changeSyntaxStyle)
        
        menu.removeAllItems()
        
        menu.addItem(withTitle: BundledStyleName.none, action: action, keyEquivalent: "")
        menu.addItem(.separator())
        
        if !recentStyleNames.isEmpty {
            let labelItem = NSMenuItem()
            labelItem.title = "Recently Used".localized(comment: "menu heading in syntax style list on toolbar popup")
            labelItem.isEnabled = false
            menu.addItem(labelItem)
            
            menu.items += recentStyleNames.map { NSMenuItem(title: $0, action: action, keyEquivalent: "") }
            menu.addItem(.separator())
        }
        
        menu.items += styleNames.map { NSMenuItem(title: $0, action: action, keyEquivalent: "") }
        
        if let styleName = (self.document as? Document)?.syntaxParser.style.name {
            self.selectSyntaxPopUpItem(with: styleName)
        }
    }
    
    
    private func selectSyntaxPopUpItem(with styleName: String) {
        
        guard let popUpButton = self.syntaxPopUpButton else { return }
        
        let deletedTag = -1
        
        // remove deleted items
        popUpButton.menu?.items.removeAll { $0.tag == deletedTag }
        
        if let item = popUpButton.item(withTitle: styleName) {
            popUpButton.select(item)
        
        } else {
            // insert item by adding deleted item section
            popUpButton.insertItem(withTitle: styleName, at: 1)
            popUpButton.item(at: 1)?.tag = deletedTag
            popUpButton.selectItem(at: 1)
            
            popUpButton.insertItem(withTitle: "Deleted".localized, at: 1)
            popUpButton.item(at: 1)?.tag = deletedTag
            popUpButton.item(at: 1)?.isEnabled = false
            
            popUpButton.menu?.insertItem(.separator(), at: 1)
            popUpButton.item(at: 1)?.tag = deletedTag
        }
    }
    
}
