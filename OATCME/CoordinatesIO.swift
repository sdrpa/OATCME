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
import CoreLocation

struct CoordinateIO {

    let coordinates: [CLLocationCoordinate2D]

    init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
    }

    static func `import`(completion: @escaping (_ filename: String, _ coordinates: [CLLocationCoordinate2D]) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canCreateDirectories = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = true
        openPanel.prompt = "Import"
        openPanel.begin { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                guard let url = openPanel.url,
                    let coordinates = self.import(from: url) else {
                        return
                }
                completion((url.deletingPathExtension().lastPathComponent, coordinates))
            }
        }
    }

    fileprivate static func `import`(from fileURL: URL) -> [CLLocationCoordinate2D]? {
        do {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            let rows = CSVParser(with: contents).rows
            let coordinates = rows.reduce([CLLocationCoordinate2D]()) { acc, row in
                guard let latitude = Double(row[0]),
                    let longitude = Double(row[1]) else {
                        return acc
                }
                return acc + [CLLocationCoordinate2D(latitude: latitude, longitude: longitude)]
            }
            return coordinates
        } catch {
            return nil
        }
    }

    static func export(coordinates: [CLLocationCoordinate2D], filename: String?) {
        let savePanel = NSSavePanel()
        savePanel.prompt = "Save"
        savePanel.allowedFileTypes = ["txt"]
        if let filename = filename {
            savePanel.nameFieldStringValue = filename
        }
        savePanel.begin { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                guard let url = savePanel.url else { return }
                self.save(coordinates: coordinates, to: url)
            }
        }
    }

    fileprivate static func save(coordinates: [CLLocationCoordinate2D], to fileURL: URL) {
        do {
            let contents = coordinates.map({
                String(format: "%.3f", $0.latitude) + "," + String(format: "%.3f", $0.longitude)
            }).joined(separator: "\n")
            try ("latitude,longitude\n" + contents)
                .write(to: fileURL, atomically: true, encoding: .utf8)
        }
        catch {
            fatalError()
        }
    }
}
