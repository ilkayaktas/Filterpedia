//
//  FilterView.swift
//  Filterpedia
//
//  Created by İlkay Aktaş on 21.10.2019.
//  Copyright © 2019 Simon Gladman. All rights reserved.
//

import UIKit

class FilterView: UIView {
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
        if let collectionView = Bundle.main.loadNibNamed("FilterAttributeView", owner: self, options: nil)?.first as? FilterAttributeView {

            self.addSubview(collectionView)

            
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            // Make my custom view center on filterDetail view
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view":collectionView]))
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view":collectionView]))

        }
        
    }
}
