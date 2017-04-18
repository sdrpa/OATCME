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
import MapKit // #keyPath(MKMapView.xxx)

class Document: NSDocument {

    fileprivate var layers: [DrawingLayer]?
    fileprivate var visibleMapRect: CGRect?

    override init() {
        super.init()

        self.addObserver(self, forKeyPath: #keyPath(Document.displayName), options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
    }

    deinit {
        self.removeObserver(self, forKeyPath: #keyPath(Document.displayName), context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(Document.displayName) {
            guard let mapWindowController = self.windowControllers.first as? MapWindowController else {
                return
            }
            mapWindowController.layersWindowController?.window?.title = self.displayName + " Layers"
        }
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override func makeWindowControllers() {
        let mapWindowController = MapWindowController()
        mapWindowController.layersWindowController?.window?.title = self.displayName + " Layers"
        if let layers = self.layers {
            layers.forEach { mapWindowController.layersWindowController?.addLayer($0) }
        } else {
            mapWindowController.layersWindowController?.addNewLayer(self)
        }
        if let visibleMapRect = self.visibleMapRect {
            mapWindowController.visibleMapRect = visibleMapRect
        }

        self.addWindowController(mapWindowController)
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        //throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        guard let mapWindowController = self.windowControllers.first as? MapWindowController else {
            fatalError(#function)
        }
        if let layers = mapWindowController.layersWindowController?.layers {
            let visibleMapRectValue = NSValue(rect: mapWindowController.visibleMapRect)
            let dictionary: [String : Any] = [
                #keyPath(LayersWindowController.layers): layers,
                #keyPath(MKMapView.visibleMapRect): visibleMapRectValue
            ]
            return NSKeyedArchiver.archivedData(withRootObject: dictionary)
        } else {
            return Data()
        }
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        //throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        guard let dictionary = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String : Any] else {
            return
        }
        let layersKeyPath = #keyPath(LayersWindowController.layers)
        if let layers = dictionary[layersKeyPath] as? [DrawingLayer] {
            self.layers = layers
        }
        let visibleMapRectKeyPath = #keyPath(MKMapView.visibleMapRect)
        if let visibleMapRect = dictionary[visibleMapRectKeyPath] as? NSValue {
            self.visibleMapRect = visibleMapRect.rectValue
        }
    }
}
