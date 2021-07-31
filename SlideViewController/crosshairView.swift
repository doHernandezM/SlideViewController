//
//  SliderView.swift
//  SlideViewController
//
//  Created by Dennis Hernandez on 7/26/21.
//

import UIKit

class SliderView: UIView {
    fileprivate var editStateActive = false
    
    //Toggles edit mode on and off. Send nil to return state without changing state.
    //Override this to receive updates to state. Make sure to call let editModeIsOn = super.editState(active: active)
    func editState(active: Bool? = nil) -> Bool? {
        if active == nil {
            return editStateActive
        } else {
            if active! == editStateActive {return nil} //Don't do anything if not needed
        }
        editStateActive = active!
        
        return editStateActive
    }
}

class crosshairView: SliderView {
    //Crosshair is CALayers
    private var verticalLayer = CALayer()
    private var horizontalLayer = CALayer()
    private var circleLayer = CAShapeLayer()
    private let circleRadius: CGFloat = 30
    var thickness = CGFloat(3.0)
    var length = CGFloat(75.0)
    private var crosshairColor: UIColor = UIColor.lightGray
    
    //MARK:Configuration
    func configure(slideView:SlideViewController) {
        //Visuals
        self.backgroundColor = .systemBackground
        circleLayer.fillColor = self.backgroundColor?.cgColor
                
        //Frame
        self.frame = CGRect(x: 0.0, y: 0.0, width: slideView.view.bounds.width * 0.4, height: slideView.view.bounds.height * 0.4)
        
        let radius: CGFloat = 50.0
        circleLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2.0 * radius, height: 2.0 * radius), cornerRadius: radius).cgPath
                
        self.layer.addSublayer(verticalLayer)
        self.layer.addSublayer(horizontalLayer)
        self.layer.addSublayer(circleLayer)
        circleLayer.position = CGPoint(x: self.frame.midX - circleRadius, y: self.frame.midY - circleRadius)
        
        updateCrosshairLayers()
        
        //Add to parent view
        slideView.view.addSubview(self)
        
    }
    
    override func editState(active: Bool? = nil) -> Bool? {
        let editModeIsOn = super.editState(active: active)
        updateCrosshairLayers()
        return editModeIsOn
    }
    
    func updateCrosshairLayers() {
        
        if editStateActive {
            crosshairColor = UIColor.systemBlue
            //            thickness = thickness
            
        } else {
            crosshairColor = UIColor.lightGray
            thickness = CGFloat(3.0)
        }
        
        verticalLayer.backgroundColor = crosshairColor.cgColor
        horizontalLayer.backgroundColor = crosshairColor.cgColor
        
        verticalLayer.cornerRadius = thickness / 2.0
        horizontalLayer.cornerRadius = thickness / 2.0
        
        verticalLayer.frame = self.bounds
        verticalLayer.frame.size.width = thickness
        
        horizontalLayer.frame = self.bounds
        horizontalLayer.frame.size.height = thickness
        horizontalLayer.frame.size.width = self.frame.size.height
        
        verticalLayer.frame.origin.x = (self.bounds.size.width / 2) - (thickness / 2)
        horizontalLayer.frame.origin.x =  (self.bounds.size.width / 2) - (horizontalLayer.frame.size.width / 2)
        horizontalLayer.frame.origin.y = (self.bounds.size.height / 2) - (thickness / 2)
    
        }
    
}
