/**
 Created by Sinisa Drpa on 4/11/17.

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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var preferencesWindowController: PreferencesWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.preferencesWindowController = PreferencesWindowController()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    //func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    //    return true
    //}
}

extension AppDelegate {

    @IBAction func showPreferencesWindow(_ sender: Any) {
        self.preferencesWindowController?.showWindow(self)
    }
}

extension AppDelegate {

    func filePathWithinApplicationDirectory(fileName: String) -> String? {
        guard let applicationDirectory = self.applicationDirectory else {
            return nil
        }
        let filePath = applicationDirectory + "/" + fileName
        return filePath
    }

    fileprivate var applicationDirectory: String? {
        let supportDirectories = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        guard let bundleIdentifier = Bundle.main.bundleIdentifier, supportDirectories.count > 0 else {
            return nil
        }

        let applicationDirectory = supportDirectories[0] + "/" + bundleIdentifier
        let fileManger = FileManager.default
        if !fileManger.fileExists(atPath: applicationDirectory) {
            let directoryURL = URL(fileURLWithPath: applicationDirectory, isDirectory: true)
            do {
                try fileManger.createDirectory(at: directoryURL, withIntermediateDirectories: false, attributes: nil)
            } catch let error {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
        return applicationDirectory
    }
}
