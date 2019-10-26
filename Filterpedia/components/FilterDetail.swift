//
//  FilterDetail.swift
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

import UIKit

class FilterDetail: UIView
{
    let rect640x640 = CGRect(x: 0, y: 0, width: 640, height: 640)
    let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    
    let compositeOverBlackFilter = CompositeOverBlackFilter()
    
    let shapeLayer: CAShapeLayer =
    {
        let layer = CAShapeLayer()
        
        layer.strokeColor = UIColor.lightGray.cgColor
        layer.fillColor = nil
        layer.lineWidth = 0.5
        
        return layer
    }()

    let collectionView : FilterAttributeView = {
        let collectionView = Bundle.main.loadNibNamed("FilterAttributeView", owner: self, options: nil)?.first as? FilterAttributeView
        return collectionView!
        
    }()
    
    let scrollView = UIScrollView()
    
    lazy var resetButton: UIButton =
    {
        let reset = UIButton()
        reset.setTitle("Reset", for: .normal)
        reset.setTitleColor(UIColor.systemBlue, for: .normal)
        reset.addTarget(self, action: #selector(FilterDetail.resetPicture), for: .touchDown)
        return reset
    }()
    
    lazy var histogramToggleSwitch: UISwitch =
    {
        let toggle = UISwitch()
        
        toggle.isOn = !self.histogramDisplayHidden
        toggle.addTarget(
            self,
            action: #selector(FilterDetail.toggleHistogramView),
            for: .valueChanged)
        
        return toggle
    }()
    
    let histogramDisplay = HistogramDisplay()
    
    var histogramDisplayHidden = true
    {
        didSet
        {
            if !histogramDisplayHidden
            {
                self.histogramDisplay.imageRef = imageView.image?.cgImage
            }
            
            UIView.animate(withDuration: 0.25, animations: {
                self.histogramDisplay.alpha = self.histogramDisplayHidden ? 0 : 1
            })
            
        }
    }
    
    let imageView: UIImageView =
    {
        let imageView = UIImageView()
        
        imageView.backgroundColor = UIColor.black
        
        imageView.layer.cornerRadius = 30
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    #if !arch(i386) && !arch(x86_64)
        let ciMetalContext = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
    #else
        let ciMetalContext = CIContext()
    #endif
    
    let ciOpenGLESContext = CIContext()
  
    /// Whether the user has changed the filter whilst it's
    /// running in the background.
    var pending = false
    
    /// Whether a filter is currently running in the background
    var busy = false
    {
        didSet
        {
            if busy
            {
                activityIndicator.startAnimating()
            }
            else
            {
                activityIndicator.stopAnimating()
            }
        }
    }
    
    var filterName: String?
    {
        didSet
        {
            updateFromFilterName()
            
            let filterAttributesTableView: FilterAttributeTable =
            {
                let tableView = FilterAttributeTable(frame: CGRect.zero,
                    style: UITableView.Style.plain)
                
                tableView.filterName = self.filterName
                tableView.currentFilter = paramsDict[self.filterName!]
                    
                tableView.register(FilterInputItemRenderer.self,
                    forCellReuseIdentifier: "FilterInputItemRenderer")
                
                tableView.delegate = self
                tableView.dataSource = self
                
                return tableView
            }()

            collectionView.addFilterAttr(filterAttributesTableView: filterAttributesTableView)
            
        }
    }
    
    // Define a list of parameters for multi filter view
    // fileprivate var currentFilter: CIFilter?
    
    var paramsDict = [String: CIFilter]()
    
    /// User defined filter parameter values
    fileprivate var filterParameterValues: [String: AnyObject] = [kCIInputImageKey: assets.first!.ciImage]
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        addSubview(collectionView)
        
        addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        scrollView.delegate = self
        
        histogramDisplay.alpha = histogramDisplayHidden ? 0 : 1
        histogramDisplay.layer.shadowOffset = CGSize(width: 0, height: 0)
        histogramDisplay.layer.shadowOpacity = 0.75
        histogramDisplay.layer.shadowRadius = 5
        addSubview(histogramDisplay)
        
        addSubview(histogramToggleSwitch)
        addSubview(resetButton)
        
        imageView.addSubview(activityIndicator)
        
        layer.addSublayer(shapeLayer)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func toggleHistogramView()
    {
        histogramDisplayHidden = !histogramToggleSwitch.isOn
    }
    
    @objc func resetPicture()
    {
        print("XXXXX Resetlendi!")
        filterParameterValues[kCIInputImageKey] = assets.first!.ciImage
        imageView.image = UIImage(ciImage: assets.first!.ciImage)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func updateFromFilterName()
    {
        guard let filterName = filterName, let filter = CIFilter(name: filterName) else
        {
            return
        }
        
        // If previously any subview is added (RGBChannelToneCurve, CIToneCurve or CMYKToneCurves), remove them.
        imageView.subviews
            .filter({ $0 is FilterAttributesDisplayable})
            .forEach({ $0.removeFromSuperview() })
        
        if let widget = OverlayWidgets.getOverlayWidgetForFilter(filterName: filterName) as? UIView
        {
            // Add RGBChannelToneCurve, CIToneCurve or CMYKToneCurves as subview
            imageView.addSubview(widget)
            
            widget.frame = imageView.bounds
        }
        
        paramsDict[filterName] = filter
        
        fixFilterParameterValues()
        
        applyFilter()
    }
    
    // MARK: fixFilterParameterValues
    /// Assign a default image if required and ensure existing
    /// filterParameterValues won't break the new filter.
    func fixFilterParameterValues()
    {
        guard let currentFilter = paramsDict[filterName!] else
        {
            return
        }
        
        let attributes = currentFilter.attributes
        for inputKey in currentFilter.inputKeys
        {
            if let attribute = attributes[inputKey] as? [String : AnyObject]
            {
                // default image
                if let className = attribute[kCIAttributeClass] as? String, className == "CIImage" && filterParameterValues[inputKey] == nil
                {
                    print("XXXXX Fotoğraf değişti")
                    filterParameterValues[inputKey] = assets.first!.ciImage
                }
                
                // ensure previous values don't exceed kCIAttributeSliderMax for this filter
                if let maxValue = attribute[kCIAttributeSliderMax] as? Float,
                    let filterParameterValue = filterParameterValues[inputKey] as? Float, filterParameterValue > maxValue
                {
                    filterParameterValues[inputKey] = maxValue as AnyObject
                }
                
                // ensure vector is correct length
                if let defaultVector = attribute[kCIAttributeDefault] as? CIVector,
                    let filterParameterValue = filterParameterValues[inputKey] as? CIVector, defaultVector.count != filterParameterValue.count
                {
                    filterParameterValues[inputKey] = defaultVector
                }
            }
        }
    }

    // MARK: applyFilter
    func applyFilter(){
        guard !busy else
        {
            pending = true
            return
        }
        
        guard let currentFilter = paramsDict[filterName!] else
        {
            return
        }
        
        busy = true
        
        imageView.subviews
            .filter({ $0 is FilterAttributesDisplayable})
            .forEach({ ($0 as? FilterAttributesDisplayable)?.setFilter(filter: currentFilter) })
        
        let queue = currentFilter is VImageFilter ? DispatchQueue.main : DispatchQueue.global()
 
        queue.async
        {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            for (key, value) in self.filterParameterValues where currentFilter.inputKeys.contains(key)
            {
                print("\(key) \(value)")
                currentFilter.setValue(value, forKey: key)
            }
                        
            let outputImage = currentFilter.outputImage!
            let finalImage: CGImage
  
            let context = (currentFilter is MetalRenderable) ? self.ciMetalContext : self.ciOpenGLESContext
            
            if outputImage.extent.width == 1 || outputImage.extent.height == 1
            {
                // if a filter's output image height or width is 1,
                // (e.g. a reduction filter) stretch to 640x640
                
                let stretch = CIFilter(name: "CIStretchCrop",
                    parameters: ["inputSize": CIVector(x: 640, y: 640),
                        "inputCropAmount": 0,
                        "inputCenterStretchAmount": 1,
                        kCIInputImageKey: outputImage])!
                
                finalImage = context.createCGImage(stretch.outputImage!,
                    from: self.rect640x640)!
            }
            else if outputImage.extent.width < 640 || outputImage.extent.height < 640
            {
                // if a filter's output image is smaller than 640x640 (e.g. circular wrap or lenticular
                // halo), composite the output over a black background)
                
                self.compositeOverBlackFilter.setValue(outputImage,
                    forKey: kCIInputImageKey)
                
                finalImage = context.createCGImage(self.compositeOverBlackFilter.outputImage!,
                    from: self.rect640x640)!
            }
            else
            {
                finalImage = context.createCGImage(outputImage,
                    from: self.rect640x640)!
            }
            
            let endTime = (CFAbsoluteTimeGetCurrent() - startTime)
            print(self.filterName!, "execution time", endTime)
            
            DispatchQueue.main.async
            {
                if !self.histogramDisplayHidden
                {
                    self.histogramDisplay.imageRef = finalImage
                }
                
                self.imageView.image = UIImage(cgImage: finalImage)
                self.busy = false
                self.filterParameterValues[kCIInputImageKey] = CIImage(cgImage: finalImage)
                
                if self.pending
                {
                    self.pending = false
                    self.applyFilter()
                }
            }
        }
    }
    
    // MARK: layoutSubviews
    override func layoutSubviews()
    {
        let halfWidth = frame.width * 0.5
        let thirdHeight = frame.height * 0.333
        let twoThirdHeight = frame.height * 0.666
        
        scrollView.frame = CGRect(x: halfWidth - thirdHeight,
            y: 0,
            width: twoThirdHeight,
            height: twoThirdHeight)
        
        imageView.frame = CGRect(x: 0,
            y: 0,
            width: scrollView.frame.width,
            height: scrollView.frame.height)
        
        collectionView.frame = CGRect(x: 0,
            y: twoThirdHeight,
            width: frame.width,
            height: thirdHeight)
            
        histogramDisplay.frame = CGRect(
            x: 0,
            y: thirdHeight,
            width: frame.width,
            height: thirdHeight).insetBy(dx: 5, dy: 5)
        
        histogramToggleSwitch.frame = CGRect(
            x: frame.width - histogramToggleSwitch.intrinsicContentSize.width,
            y: 0,
            width: intrinsicContentSize.width,
            height: intrinsicContentSize.height)
        
        resetButton.frame = CGRect(
            x: 0,
            y: 0,
            width: 100,
            height: 30
        )
        
        activityIndicator.frame = imageView.bounds
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: frame.height))
        
        shapeLayer.path = path.cgPath
    }
}

extension FilterDetail: UIScrollViewDelegate{
    
}

// MARK: UITableViewDelegate extension

extension FilterDetail: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 60 // height for cell
    }
}

// MARK: UITableViewDataSource extension

extension FilterDetail: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let tb = tableView as! FilterAttributeTable
        return tb.currentFilter!.inputKeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilterInputItemRenderer",
            for: indexPath) as! FilterInputItemRenderer
 
        let tb = tableView as! FilterAttributeTable
        let inputKey = tb.currentFilter!.inputKeys[indexPath.row]
        if let attribute = tb.currentFilter!.attributes[inputKey] as? [String : AnyObject]
        {
            print("XXXXX Table row \(indexPath.row) \(inputKey)")
            cell.detail = (inputKey: inputKey,
                attribute: attribute,
                filterParameterValues: filterParameterValues)
        }
        
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool
    {
        return false
    }
}

// MARK: FilterInputItemRendererDelegate extension

extension FilterDetail: FilterInputItemRendererDelegate
{
    func filterInputItemRenderer(_ filterInputItemRenderer: FilterInputItemRenderer, didChangeValue: AnyObject?, forKey: String?)
    {
        if let key = forKey, let value = didChangeValue
        {
            filterParameterValues[key] = value
            applyFilter()
        }
    }

}


