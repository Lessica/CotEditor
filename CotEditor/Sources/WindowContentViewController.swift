//
//  WindowContentViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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

final class WindowContentViewController: NSSplitViewController {
    
    // MARK: Private Properties
    
    private var sidebarSelectionObserver: AnyCancellable?
    
    @IBOutlet private weak var documentViewItem: NSSplitViewItem?
    
    
    
    // MARK: -
    // MARK: Split View Controller Methods
    
    
    /// deliver represented object to child view controllers
    override var representedObject: Any? {
        
        didSet {
            for viewController in self.children {
                viewController.representedObject = representedObject
            }
        }
    }
    
    
    // MARK: Public Methods
    
    /// deliver editor to outer view controllers
    var documentViewController: DocumentViewController? {
        
        return self.documentViewItem?.viewController as? DocumentViewController
    }
    
    
    /// rsestore visibility of inspector but keeping the window width
    func restoreAutosavingState() {
        
        assert(self.isViewLoaded)
        assert(!self.view.window!.isVisible)
        
        guard self.splitView.autosavingSubviewStates?[safe: 1]?.isCollapsed == false else { return }
        
        let originalSize = self.view.frame.size
        
        // adjust contentView shape
        self.splitView.setPosition(originalSize.width, ofDividerAt: 0)
    }
    
    
    // MARK: Private Methods
    
    /// window content view controllers in all tabs in the same window
    private var siblings: [WindowContentViewController] {
        
        guard self.isViewLoaded else { return [] }
        
        return self.view.window?.tabbedWindows?.compactMap { ($0.windowController?.contentViewController as? WindowContentViewController) } ?? [self]
    }
    
}
