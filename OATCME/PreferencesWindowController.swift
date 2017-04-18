/**
 Created by Sinisa Drpa on 4/13/17.

 OATCME is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or any later version.

 OATCME is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with OATCME.  If not, see <http://www.gnu.org/licenses/>
 */

import Cocoa

final class PreferencesWindowController: NSWindowController, NSWindowDelegate {

    fileprivate static let fileName = "preferences"

    var lineWidth: CGFloat = 1

    override init(window: NSWindow?) {
        super.init(window: window)

        self.load()
        self.addObserver(self, forKeyPath: #keyPath(PreferencesWindowController.lineWidth), options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
    }
    
    required init?(coder decoder: NSCoder) {
        let lineWidth = decoder.decodeObject(forKey: #keyPath(PreferencesWindowController.lineWidth)) as? CGFloat
        self.lineWidth = lineWidth ?? 1
        super.init(coder: decoder)

        self.addObserver(self, forKeyPath: #keyPath(PreferencesWindowController.lineWidth), options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
    }

    override func encode(with encoder: NSCoder) {
        encoder.encode(self.lineWidth, forKey: #keyPath(PreferencesWindowController.lineWidth))
    }

    deinit {
        self.removeObserver(self, forKeyPath: #keyPath(PreferencesWindowController.lineWidth), context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(PreferencesWindowController.lineWidth) {
            let documents = NSDocumentController.shared().documents
            for document in documents {
                guard let mapWindowController = document.windowControllers.first as? MapWindowController else {
                    return
                }
                _ = mapWindowController.layersWindowController?.layers.map { [weak self] in
                    $0.lineWidth = self?.lineWidth ?? 1
                }
            }
        }
    }

    func windowWillClose(_ notification: Notification) {
        _ = self.save()
    }

    func load() {
        let appDelegate = NSApplication.shared().delegate as? AppDelegate
        guard let filePath = appDelegate?.filePathWithinApplicationDirectory(fileName: PreferencesWindowController.fileName) else {
            return
        }
        let other = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? PreferencesWindowController
        if let lineWidth = other?.lineWidth {
            self.lineWidth = lineWidth
        }
    }

    func save() -> Bool {
        let appDelegate = NSApplication.shared().delegate as? AppDelegate
        guard let filePath = appDelegate?.filePathWithinApplicationDirectory(fileName: PreferencesWindowController.fileName) else {
            return false
        }
        return NSKeyedArchiver.archiveRootObject(self, toFile: filePath)
    }
}

extension PreferencesWindowController {

    override var windowNibName: String? {
        return "\(PreferencesWindowController.self)"
    }
}
