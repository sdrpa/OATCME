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
import MapKit

final class MapWindowController: NSWindowController {

    enum Mode {
        case drawing
        case map
        case unknown
    }

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var coordTextField: NSTextField!
    @IBOutlet weak var zoomLevelTextField: NSTextField!

    lazy var layersWindowController: LayersWindowController? = {
        let layersWindowController = LayersWindowController()
        layersWindowController.delegate = self
        return layersWindowController
    }()
    var drawingLayer: DrawingLayer? {
        if self.mode != .drawing {
            return nil
        }
        guard let selectedLayer = self.layersWindowController?.selectedLayer else {
            return nil
        }
        return selectedLayer.isHidden ? nil : selectedLayer
    }
    var mode: Mode = .unknown {
        didSet {
            self.updateDrawIndicator()
        }
    }
    var contentView: NSView {
        guard let contentView = self.window?.contentView else {
            fatalError(#function)
        }
        return contentView
    }
    var visibleMapRect: CGRect {
        set {
            let origin = MKMapPoint(x: Double(newValue.origin.x), y: Double(newValue.origin.y))
            let size = MKMapSize(width: Double(newValue.size.width), height: Double(newValue.size.height))
            let mkMapRect = MKMapRect(origin: origin, size: size)
            self.mapView.visibleMapRect = mkMapRect
        }
        get {
            let mkMapRect = self.mapView.visibleMapRect
            return CGRect(x: mkMapRect.origin.x, y: mkMapRect.origin.y, width: mkMapRect.size.width, height: mkMapRect.size.height)
        }
    }

    override func windowDidLoad() {
        self.mapView.delegate = self
        self.mode = .drawing
        self.updateZoomFactorLabel()
        self.layersWindowController?.showWindow(self)

        let options: NSTrackingAreaOptions = [.activeInActiveApp, .inVisibleRect, .mouseEnteredAndExited, .mouseMoved]
        let trackingArea = NSTrackingArea(rect: self.contentView.bounds, options: options, owner: self, userInfo: nil)
        self.contentView.addTrackingArea(trackingArea)
    }

    deinit {
        for trackingArea in self.contentView.trackingAreas {
            self.contentView.removeTrackingArea(trackingArea)
        }
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    // MARK: -

    override func mouseDown(with event: NSEvent) {
        self.isMapInteractionEnabled = (self.mode == .map)

        let locationInView = contentView.convert(event.locationInWindow, from: nil)
        if !self.mapView.frame.contains(locationInView) { // Don't draw on title bar mouseDown
            return
        }
        let coordinate = self.mapView.convert(locationInView, toCoordinateFrom: self.mapView)
        self.addCoordinate(coordinate)
        displayCoordinate(coordinate)
    }

    override func mouseEntered(with event: NSEvent) {
        //self.window?.makeKeyAndOrderFront(self)
        super.mouseEntered(with: event)
    }

    override func mouseMoved(with event: NSEvent) {
        let locationInView = contentView.convert(event.locationInWindow, from: nil)
        let coordinate = self.mapView.convert(locationInView, toCoordinateFrom: self.mapView)
        displayCoordinate(coordinate)
    }

    //override func mouseDragged(with event: NSEvent) {
    //}

    override func mouseUp(with event: NSEvent) {
        self.isMapInteractionEnabled = true
    }

    var isMapInteractionEnabled: Bool = true {
        didSet {
            self.mapView.isScrollEnabled = self.isMapInteractionEnabled
            self.mapView.isZoomEnabled = self.isMapInteractionEnabled
            //self.mapView.isRotateEnabled = self.isMapInteractionEnabled
        }
    }

    fileprivate func addCoordinate(_ coordinate: CLLocationCoordinate2D) {
        self.drawingLayer?.addCoordinate(coordinate)
    }

    fileprivate func updateDrawIndicator() {
        let show = (self.drawingLayer == nil)
        self.mapView.layer?.borderWidth = 2
        self.mapView.layer?.borderColor = show ? NSColor.red.cgColor : NSColor.clear.cgColor
    }

    fileprivate func updateZoomFactorLabel() {
        let zoomWidth = mapView.visibleMapRect.size.width
        let zoomFactor = Int(log2(zoomWidth)) - 9
        self.zoomLevelTextField.stringValue = String(zoomFactor)
    }

    fileprivate func displayCoordinate(_ coordinate: CLLocationCoordinate2D) {
        self.coordTextField.stringValue = String(format: "%.3f %.3f", coordinate.latitude, coordinate.longitude)
    }
}

// MARK: - Events

extension MapWindowController {

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
            case Keycode.space:
            self.toggleMode()

        default:
            super.keyDown(with: event)
        }
    }

    fileprivate func toggleMode() {
        switch self.mode {
        case .drawing:
            self.mode = .map
        case .map:
            self.mode = .drawing
        case .unknown:
            fatalError(#function)
        }
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let selector = menuItem.action else { return true }
        switch selector {
        case #selector(toggleLayersWindow(_:)):
            guard let window = self.layersWindowController?.window else { break }
            menuItem.title = window.isVisible ? "Hide Layers" : "Show Layers"
        default:
            break
        }
        return self.document?.validateMenuItem(menuItem) ?? false
    }
}

extension MapWindowController: LocationProvider {

    func location(forCoodinate coordinate: CLLocationCoordinate2D, layer: DrawingLayer) -> CGPoint {
        return self.mapView.convert(coordinate, toPointTo: self.window?.contentView)
    }

    func undoManager(forDrawingLayer: DrawingLayer) -> UndoManager? {
        return self.window?.undoManager
    }
}

extension MapWindowController: LayersWindowControllerDelegate {

    func layersWindowController(_ layersWindowController: LayersWindowController, didAdd drawingLayer: DrawingLayer) {
        drawingLayer.locationProvider = self
        drawingLayer.frame = self.contentView.frame
        contentView.layer?.addSublayer(drawingLayer)
        drawingLayer.setNeedsDisplay()
        self.updateDrawIndicator()
    }

    func layersWindowController(_ layersWindowController: LayersWindowController, didRemove drawingLayer: DrawingLayer) {
        drawingLayer.locationProvider = nil
        drawingLayer.removeFromSuperlayer()
        self.updateDrawIndicator()
    }

    func layersWindowControllerDidChangeSelection(_ layersWindowController: LayersWindowController) {
        self.updateDrawIndicator()
    }

    func layersWindowControllerDidToggleLayerVisibility(_ layersWindowController: LayersWindowController) {
        self.updateDrawIndicator()
    }
}

extension MapWindowController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.updateZoomFactorLabel()
        self.layersWindowController?.layersNeedDisplay()
    }
}

extension MapWindowController {

    @IBAction func toggleLayersWindow(_ sender: Any) {
        guard let window = self.layersWindowController?.window else {
            self.layersWindowController?.showWindow(self)
            return
        }

        if window.isVisible {
            self.layersWindowController?.close()
        } else {
            self.layersWindowController?.showWindow(self)
        }
    }

    @IBAction func importCoordinates(_ sender: Any) {
        CoordinateIO.import { [weak self] result in
            let filename = result.0
            let coordinates = result.1
            let drawingLayer = DrawingLayer(name: filename, coordinates: coordinates)
            self?.layersWindowController?.addLayer(drawingLayer)
        }
    }
}

extension MapWindowController {

    override var windowNibName: String? {
        return "\(MapWindowController.self)"
    }
}
