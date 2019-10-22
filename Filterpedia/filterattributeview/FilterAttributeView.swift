//
//  FilterAttributeView.swift
//  Filterpedia
//
//  Created by İlkay Aktaş on 19.10.2019.
//  Copyright © 2019 Simon Gladman. All rights reserved.
//

import Foundation
import UIKit

class FilterAttributeView : UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var filterList = Array<UITableView>()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(UINib(nibName: "FilterAttributeCell", bundle: nil), forCellWithReuseIdentifier: "collectionCell")
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! FilterAttributeCell
        if(filterList.count > indexPath.row){
            let tableView = filterList[indexPath.row]
       //     tableView.backgroundColor = UIColor.green
            cell.addSubview(tableView)
            tableView.frame = cell.frame
        //    cell.backgroundColor = UIColor.blue
    //        tableView.translatesAutoresizingMaskIntoConstraints = true
            // Make my custom view center on filterDetail view
   //         cell.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view":collectionView]))
   //         cell.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view":collectionView]))
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width - 50, height: collectionView.frame.size.height)
    }
    
    func addFilterAttr(filterAttributesTableView: UITableView){
        filterList.append(filterAttributesTableView)
        collectionView.reloadData()
    }
}
