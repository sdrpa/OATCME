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

protocol LayersWindowControllerDelegate: class {
    func layersWindowController(_ layersWindowController: LayersWindowController, didAdd drawingLayer: DrawingLayer)
    func layersWindowController(_ layersWindowController: LayersWindowController, didRemove drawingLayer: DrawingLayer)
    func layersWindowControllerDidChangeSelection(_ layersWindowController: LayersWindowController)
    func layersWindowControllerDidToggleLayerVisibility(_ layersWindowController: LayersWindowController)
}

final class LayersWindowController: NSWindowController, NSWindowDelegate {

    @IBOutlet weak var tableView: NSTableView?

    weak var delegate: LayersWindowControllerDelegate?
    fileprivate (set)var layers: [DrawingLayer] = []
    fileprivate (set)var selectedLayer: DrawingLayer?
    
    var contentView: NSView {
        guard let contentView = self.window?.contentView else {
            fatalError(#function)
        }
        return contentView
    }

    override func windowDidLoad() {
        if let selectedLayer = self.selectedLayer,
            let selectedIndex = self.layers.index(of: selectedLayer) {
                self.tableView?.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
        }
        let options: NSTrackingAreaOptions = [.activeInActiveApp, .inVisibleRect, .mouseEnteredAndExited]
        let trackingArea = NSTrackingArea(rect: self.contentView.bounds, options: options, owner: self, userInfo: nil)
        self.contentView.addTrackingArea(trackingArea)
    }

    func windowWillClose(_ notification: Notification) {
        for trackingArea in self.contentView.trackingAreas {
            self.contentView.removeTrackingArea(trackingArea)
        }
    }

    deinit {

    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    // MARK: -

    override func mouseEntered(with event: NSEvent) {
        //self.window?.makeKeyAndOrderFront(self)
        super.mouseEntered(with: event)
    }

    // MARK: -

    @IBAction func addNewLayer(_ sender: Any) {
        let drawingLayer = DrawingLayer()
        self.addLayer(drawingLayer)
    }

    func addLayer(_ drawingLayer: DrawingLayer) {
        self.layers.append(drawingLayer)
        self.selectedLayer = drawingLayer
        self.delegate?.layersWindowController(self, didAdd: drawingLayer)

        self.tableView?.reloadData()
        self.selectLastRow()
    }

    @IBAction func removeSelectedLayers(_ sender: Any) {
        guard let rowIndexes = self.tableView?.selectedRowIndexes else {
            return
        }
        for row in rowIndexes {
            self.removeLayer(at: row)
        }
        self.tableView?.reloadData()
        self.selectLastRow()
    }

    fileprivate func selectLastRow() {
        let lastIndex = self.layers.count - 1
        self.tableView?.selectRowIndexes(IndexSet(integer: lastIndex), byExtendingSelection: false)
    }

    fileprivate func removeLayer(at index: Int) {
        precondition(index < self.layers.count)
        let drawingLayer = self.layers[index]
        self.layers.remove(at: index)
        self.selectedLayer = nil

        self.delegate?.layersWindowController(self, didRemove: drawingLayer)
    }

    func toggleVisibility(_ sender: NSButton) {
        let row = sender.tag
        let layer = self.layers[row]
        layer.isHidden = !layer.isHidden

        self.delegate?.layersWindowControllerDidToggleLayerVisibility(self)

        // Deselect the row if it is not visible
        /*
        guard let selectedRow = self.tableView?.selectedRow else { return }
        if selectedRow != -1 && selectedRow == row && layer.isHidden {
            self.tableView?.deselectRow(row)
        }
        */
    }

    func changeStrokeColor(_ sender: NSColorWell) {
        let layer = self.layers[sender.tag]
        layer.strokeColor = sender.color
    }

    func export(_ sender: NSButton) {
        let layer = self.layers[sender.tag]
        let coordinates = layer.coordinates
        CoordinateIO.export(coordinates: coordinates, filename: layer.name)
    }

    func layersNeedDisplay() {
        self.layers.forEach { $0.setNeedsDisplay() }
    }
}

// MARK: -

extension LayersWindowController: NSTableViewDelegate, NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.layers.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnIdentifier = tableColumn?.identifier else { return nil }
        if let cell = tableView.make(withIdentifier: columnIdentifier, owner: nil) as? LayersTableCellView {
            cell.objectValue = self.layers[row]

            cell.toggleVisibilityButton?.tag = row
            cell.toggleVisibilityButton?.action = #selector(toggleVisibility(_:))
            cell.toggleVisibilityButton?.state = self.layers[row].isHidden ? NSOffState : NSOnState

            cell.colorWell?.tag = row
            cell.colorWell?.action = #selector(changeStrokeColor(_:))

            cell.exportButton?.tag = row
            cell.exportButton?.action = #selector(export(_:))

            return cell
        }
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else {
            return
        }
        let selectedRow = tableView.selectedRow
        if selectedRow != -1 {
            self.selectedLayer = self.layers[selectedRow]
        } else {
            self.selectedLayer = nil
        }
        self.delegate?.layersWindowControllerDidChangeSelection(self)
    }

    /*
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        let layer = self.layers[row]
        let canSelectLayer = !layer.isHidden
        return canSelectLayer
    }
    */

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return LayersTableRowView()
    }
}

extension LayersWindowController {

    override var windowNibName: String? {
        return "\(LayersWindowController.self)"
    }
}
