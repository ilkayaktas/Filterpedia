//
//  FilterDataContainer.swift
//  Filterpedia
//
//  Created by İlkay Aktaş on 29.10.2019.
//  Copyright © 2019 Simon Gladman. All rights reserved.
//

import Foundation
import CoreImage

class FilterDataContainer {
    var filterName : String?
    var filter : CIFilter?
    var filterParameterValues: [String: AnyObject] = [kCIInputImageKey: assets.first!.ciImage]

    init(_ filterName : String, _ filter : CIFilter) {
        self.filterName = filterName
        self.filter = filter
    }
}
