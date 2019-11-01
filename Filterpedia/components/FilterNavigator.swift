//
//  FilterNavigator.swift
//  Filterpedia
//
//  Created by Simon Gladman on 29/12/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>

import Foundation
import UIKit
import RealmSwift

class FilterNavigator: UIView
{
    // Get the default Realm
    let realm = try! Realm()

    let filterCategories =
    [
        CategoryCustomFilters,
        kCICategoryBlur,
        kCICategoryColorAdjustment,
        kCICategoryColorEffect,
        kCICategoryCompositeOperation,
        kCICategoryDistortionEffect,
        kCICategoryGenerator,
        kCICategoryGeometryAdjustment,
        kCICategoryGradient,
        kCICategoryHalftoneEffect,
        kCICategoryReduction,
        kCICategorySharpen,
        kCICategoryStylize,
        kCICategoryTileEffect,
        kCICategoryTransition,
    ].sorted{ CIFilter.localizedName(forCategory: $0) < CIFilter.localizedName(forCategory: $1)}
    
    /// Filterpedia doesn't support code generators, color cube filters, filters that require NSValue
    let exclusions = ["CIQRCodeGenerator",
        "CIPDF417BarcodeGenerator",
        "CICode128BarcodeGenerator",
        "CIAztecCodeGenerator",
        "CIColorCubeWithColorSpace",
        "CIColorCube",
        "CIAffineTransform",
        "CIAffineClamp",
        "CIAffineTile",
        "CICrop"] // to do: fix CICrop!
    
    let segmentedControl = UISegmentedControl(items: [FilterNavigatorMode.Grouped.rawValue, FilterNavigatorMode.Flat.rawValue])
    
    let tableView: UITableView =
    {
        let tableView = UITableView(frame: CGRect.zero,
            style: UITableView.Style.plain)
        
        tableView.register(UITableViewHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: "HeaderRenderer")
        
        tableView.register(TableCell.self,
            forCellReuseIdentifier: "ItemRenderer")
   
        return tableView
    }()
    
    var mode: FilterNavigatorMode = .Grouped
    {
        didSet
        {
            tableView.reloadData()
        }
    }
    
    weak var delegate: FilterNavigatorDelegate?
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        CustomFiltersVendor.registerFilters()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self,
            action: #selector(FilterNavigator.segmentedControlChange),
            for: UIControl.Event.valueChanged)
        
        addSubview(tableView)
        addSubview(segmentedControl)
        
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func segmentedControlChange()
    {
        mode = segmentedControl.selectedSegmentIndex == 0 ? .Grouped : .Flat
    }
    
    override func layoutSubviews()
    {
        let segmentedControlHeight = segmentedControl.intrinsicContentSize.height
        
        tableView.frame = CGRect(x: 0,
            y: 0,
            width: frame.width,
            height: frame.height - segmentedControlHeight)
        
        segmentedControl.frame = CGRect(x: 0,
            y: frame.height - segmentedControlHeight,
            width: frame.width,
            height: segmentedControlHeight)
    }
    
}


// MARK: UITableViewDelegate extension

extension FilterNavigator: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let filterName: String
        
        switch mode
        {
        case .Grouped:
            filterName = supportedFilterNamesInCategory(filterCategories[(indexPath as NSIndexPath).section]).sorted()[(indexPath as NSIndexPath).row]
        case .Flat:
            filterName = supportedFilterNamesInCategories(nil).sorted
            {
                CIFilter.localizedName(forFilterName: $0) ?? $0 < CIFilter.localizedName(forFilterName: $1) ?? $1
            }[(indexPath as NSIndexPath).row]
        }
        delegate?.filterNavigator(self, didSelectFilterName: filterName)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        switch mode
        {
        case .Grouped:
            return 40
        case .Flat:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderRenderer")! as UITableViewHeaderFooterView

        switch mode
        {
        case .Grouped:
            cell.textLabel?.text = CIFilter.localizedName(forCategory: filterCategories[section])
        case .Flat:
            cell.textLabel?.text = nil
        }
        
        return cell
    }
    
    func supportedFilterNamesInCategory(_ category: String?) -> [String]
    {
        return CIFilter.filterNames(inCategory: category).filter
        {
            !exclusions.contains($0)
        }
    }
    
    func supportedFilterNamesInCategories(_ categories: [String]?) -> [String]
    {
        return CIFilter.filterNames(inCategories: categories).filter
        {
            !exclusions.contains($0)
        }
    }
}

// MARK: UITableViewDataSource extension

extension FilterNavigator: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        switch mode
        {
        case .Grouped:
            return filterCategories.count
        case .Flat:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch mode
        {
        case .Grouped:
            return supportedFilterNamesInCategory(filterCategories[section]).count
        case .Flat:
            return supportedFilterNamesInCategories(nil).count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemRenderer",
        for: indexPath)

        let filterName: String
        
        switch mode
        {
        case .Grouped:
            filterName = supportedFilterNamesInCategory(filterCategories[(indexPath as NSIndexPath).section]).sorted()[(indexPath as NSIndexPath).row]
        case .Flat:
            filterName = supportedFilterNamesInCategories(nil).sorted
            {
                CIFilter.localizedName(forFilterName: $0) ?? $0 < CIFilter.localizedName(forFilterName: $1) ?? $1
            }[(indexPath as NSIndexPath).row]
        }
        
        let fltrName = CIFilter.localizedName(forFilterName: filterName) ?? (CIFilter(name: filterName)?.attributes[kCIAttributeFilterDisplayName] as? String) ?? filterName
        cell.textLabel?.text = fltrName
        
        
        
        if(isFavorite(name: fltrName)){
            cell.imageView?.image = UIImage(named: "fav")
        } else{
            cell.imageView?.image = UIImage(named: "notfav")
        }
        cell.imageView?.isUserInteractionEnabled = true
        cell.imageView?.tag = indexPath.row
        
        let tapGestureRecognizer = CustomTouch(target:self, action: #selector(onTapImage))
        tapGestureRecognizer.filterName = fltrName
        tapGestureRecognizer.numberOfTapsRequired = 1
        cell.imageView?.addGestureRecognizer(tapGestureRecognizer)
        
        return cell
    }
  
    
    @objc func onTapImage(_ sender: UITapGestureRecognizer) {
        
        let customTouch  = sender as! CustomTouch
        let favorite = FavoriteFilter()
        favorite.name = customTouch.filterName!
        
        print(customTouch.filterName!)
        
        if(isFavorite(name: customTouch.filterName!)){
            let favoriteFilter = realm.objects(FavoriteFilter.self).filter("name = '\(customTouch.filterName!)'")
            try! realm.write {
                realm.delete(favoriteFilter)
            }
        } else{
            // Persist your data easily
            try! realm.write {
                realm.add(favorite, update: .all)
            }
        }
        
        self.tableView.reloadData()
    }
    
    func isFavorite(name : String) -> Bool{
        let favoriteFilter = realm.objects(FavoriteFilter.self).filter("name = '\(name)'")
        
        if(favoriteFilter.count > 0){
            return true
        } else{
            return false
        }
    }
    
    class CustomTouch : UITapGestureRecognizer{
        var filterName : String?
    }

}

// MARK: Filter Navigator Modes

enum FilterNavigatorMode: String
{
    case Grouped
    case Flat
}

// MARK: FilterNavigatorDelegate

protocol FilterNavigatorDelegate: class
{
    func filterNavigator(_ filterNavigator: FilterNavigator, didSelectFilterName: String)
}

class TableCell : UITableViewCell{
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.textLabel?.frame = CGRect(x: 50, y: 0, width: self.frame.width - 50, height: self.frame.height)
        self.imageView?.frame = CGRect(x: 10, y: (self.frame.height - 25)/2, width: 25, height: 25)
    }
}

class FavoriteFilter: Object {
    @objc dynamic var name = ""
    
    override static func primaryKey() -> String? {
        return "name"
    }
}
