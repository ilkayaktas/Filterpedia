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
    
    var filterList = Array<FilterAttributeTable>()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(UINib(nibName: "FilterAttributeCell", bundle: nil), forCellWithReuseIdentifier: "collectionCell")
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Filter count \(filterList.count)")
        return filterList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! FilterAttributeCell
        
        
        if(filterList.count > indexPath.row){
            let tableView = filterList[indexPath.row]

            let label = UILabel(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: 30))
            label.text = tableView.filterName
            label.textAlignment = .center
            label.font = UIFont(name: "Futura", size: 18)
            label.backgroundColor = UIColor(hex: "C6C6C6")
            
            let delete = UIButton()
            delete.frame = CGRect(x: cell.frame.width - 30, y: 5, width: 20, height: 20)
            delete.setImage(UIImage(named: "delete"), for: .normal)
            delete.tag = indexPath.row
            delete.addTarget(self, action: #selector(deleteFilter), for: .touchDown)

            tableView.frame = CGRect(x: 0, y: 30, width: cell.frame.width, height: cell.frame.height)
            
            tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
            tableView.reloadData()
            
            cell.borderWidth = 2
            cell.borderColor = UIColor(hex: "C6C6C6")
            cell.layer.cornerRadius = 15

            cell.addSubview(label)
            cell.addSubview(delete)
            cell.addSubview(tableView)

        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width - 50, height: collectionView.frame.size.height)
    }
    
    func addFilterAttr(filterAttributesTableView: FilterAttributeTable){
        filterList.append(filterAttributesTableView)
        collectionView.reloadData()
    }
    
    @objc func deleteFilter(_ sender: UIButton) {
        filterList.remove(at: sender.tag)
        collectionView.reloadData()
    }
}
