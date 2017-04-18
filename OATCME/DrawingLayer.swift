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

import CoreLocation
import Cocoa
import Quartz

protocol LocationProvider: class {
    func location(forCoodinate: CLLocationCoordinate2D, layer: DrawingLayer) -> CGPoint
    func undoManager(forDrawingLayer: DrawingLayer) -> UndoManager?
}

final class DrawingLayer: CALayer {

    weak var locationProvider: LocationProvider?

    fileprivate (set)var coordinates: [CLLocationCoordinate2D] {
        didSet {
            self.setNeedsDisplay()
        }
    }
    var lineWidth: CGFloat {
        didSet {
            self.setNeedsDisplay()
        }
    }
    static var defaultLineWidth: CGFloat {
        let appDelegate = NSApplication.shared().delegate as? AppDelegate
        return appDelegate?.preferencesWindowController?.lineWidth ?? 1
    }
    var strokeColor: NSColor {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override func action(forKey event: String) -> CAAction? {
        return nil
    }

    init(name: String = DrawingLayer.randomName(), coordinates: [CLLocationCoordinate2D] = [], strokeColor: NSColor = .green) {
        self.coordinates = coordinates
        self.lineWidth = DrawingLayer.defaultLineWidth
        self.strokeColor = strokeColor
        super.init()

        self.name = name
    }
    
    required init?(coder decoder: NSCoder) {
        if let coordObjects = decoder.decodeObject(forKey: #keyPath(DrawingLayer.coordinates)) as? [Coordinate] {
            self.coordinates = coordObjects.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        } else {
            self.coordinates = []
        }
        self.lineWidth = DrawingLayer.defaultLineWidth
        let strokeColor = decoder.decodeObject(forKey: #keyPath(DrawingLayer.strokeColor)) as? NSColor
        self.strokeColor = strokeColor ?? .green
        super.init()

        self.name = decoder.decodeObject(forKey: #keyPath(DrawingLayer.name)) as? String

    }

    override func encode(with encoder: NSCoder) {
        let coordinates = self.coordinates.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
        encoder.encode(coordinates, forKey: #keyPath(DrawingLayer.coordinates))
        encoder.encode(self.name, forKey: #keyPath(DrawingLayer.name))
        encoder.encode(self.strokeColor, forKey: #keyPath(DrawingLayer.strokeColor))
    }

    func addCoordinate(_ coordinate: CLLocationCoordinate2D) {
        self.coordinates.append(coordinate)
        self.prepareUndoWithRemoveCoordinate(coordinate)
    }

    func removeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        self.coordinates = Array(self.coordinates.dropLast(1))
        self.prepareUndoWithAddCoordinate(coordinate)
    }
    
    override func draw(in ctx: CGContext) {
        let points: [CGPoint] = self.coordinates.flatMap { [weak self] coordinate in
            guard let strongSelf = self else { return nil }
            return self?.locationProvider?.location(forCoodinate: coordinate, layer: strongSelf)
        }
        guard let first = points.first, points.count > 1 else {
            return
        }
        ctx.setLineWidth(lineWidth)
        ctx.setStrokeColor(self.strokeColor.cgColor)

        ctx.move(to: first)
        for point in points.dropFirst() {
            ctx.addLine(to: point)
        }
        ctx.strokePath()
    }
}

extension DrawingLayer {

    fileprivate func prepareUndoWithRemoveCoordinate(_ coordinate: CLLocationCoordinate2D) {
        guard let undoManager = self.locationProvider?.undoManager(forDrawingLayer: self) else {
            return
        }
        let target = undoManager.prepare(withInvocationTarget: self) as AnyObject
        target.removeCoordinate(coordinate)
        undoManager.setActionName(undoManager.isUndoing ? "Remove Coordinate" : "Add Coordinate")
    }

    fileprivate func prepareUndoWithAddCoordinate(_ coordinate: CLLocationCoordinate2D) {
        guard let undoManager = self.locationProvider?.undoManager(forDrawingLayer: self) else {
            return
        }
        let target = undoManager.prepare(withInvocationTarget: self) as AnyObject
        target.addCoordinate(coordinate)
        undoManager.setActionName(undoManager.isUndoing ? "Add Coordinate" : "Remove Coordinate")
    }
}

/// Custom class for coding since
/// let coordinates = self.coordinates.map { NSValue(mkCoordinate: $0 ) } didn't work
fileprivate final class Coordinate: NSObject, NSCoding {

    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init?(coder decoder: NSCoder) {
        self.latitude = decoder.decodeDouble(forKey: #keyPath(Coordinate.latitude))
        self.longitude = decoder.decodeDouble(forKey: #keyPath(Coordinate.longitude))
        super.init()
    }

    func encode(with encoder: NSCoder) {
        encoder.encode(self.latitude, forKey: #keyPath(Coordinate.latitude))
        encoder.encode(self.longitude, forKey: #keyPath(Coordinate.longitude))
    }

    override var description: String {
        return "{\(latitude), \(longitude)}"
    }
}
