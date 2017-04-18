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

class LayersTableRowView: NSTableRowView {

    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none {
            let selectionRect = NSInsetRect(self.bounds, 0, 0)
            NSColor(calibratedWhite: 0.75, alpha: 1).setFill()
            let selectionPath = NSBezierPath(rect: selectionRect)
            selectionPath.fill()
        }
    }
}

