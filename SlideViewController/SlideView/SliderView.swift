//
//  SliderView.swift
//  SlideViewController
//
//  Created by Dennis Hernandez on 7/26/21.
//

import UIKit

fileprivate var crosshairColor: UIColor = UIColor.systemGray
fileprivate var crosshairActiveColor: UIColor = UIColor.systemBlue

class SliderView: UIView {
    fileprivate var editStateActive = false
    
    func configure(slideView:SlideViewController) {
        slideView.view.addSubview(self)
        
        crosshairColor = slideView.configuration.crosshairColor
        crosshairActiveColor = slideView.configuration.crosshairActiveColor

        update()
    }
    func update() {
    }
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

class dotView: SliderView {
    private var circleLayer = CAShapeLayer()
    private let circleRadius: CGFloat = 75
    var thickness = CGFloat(3.0)
    
    
    override func configure(slideView:SlideViewController) {
        //Visuals
        self.backgroundColor = slideView.configuration.backgroundColor
        crosshairColor = slideView.configuration.crosshairColor
        crosshairActiveColor = slideView.configuration.crosshairActiveColor
        circleLayer.fillColor = slideView.configuration.backgroundColor.cgColor
        
        //Frame
        self.frame = CGRect(x: 0.0, y: 0.0, width: slideView.view.bounds.width * 0.4, height: slideView.view.bounds.height * 0.4)
        
        circleLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2.0 * circleRadius, height: 2.0 * circleRadius), cornerRadius: circleRadius).cgPath
        circleLayer.position = CGPoint(x: self.frame.midX - circleRadius, y: self.frame.midY - circleRadius)
        
        self.layer.addSublayer(circleLayer)
        
        
        //Add to parent view
        slideView.view.addSubview(self)
    }
    
    override func editState(active: Bool? = nil) -> Bool? {
        let editModeIsOn = super.editState(active: active)
        update()
        return editModeIsOn
    }
    
    override func update() {
        
        if editStateActive {
            circleLayer.fillColor = crosshairActiveColor.cgColor
            circleLayer.fillColor = crosshairActiveColor.cgColor
            
        } else {
            circleLayer.fillColor = crosshairColor.cgColor
            circleLayer.fillColor = crosshairColor.cgColor
        }
    }
}


class CrosshairView: SliderView {
    //Crosshair is CALayers
    private var verticalLayer = CALayer()
    private var horizontalLayer = CALayer()
    private var circleLayer = CAShapeLayer()
    private let circleRadius: CGFloat = 75
    var thickness = CGFloat(3.0)
    
    
    //MARK:Configuration
    override func configure(slideView:SlideViewController) {
        //Visuals
        self.backgroundColor = slideView.configuration.backgroundColor
        crosshairColor = slideView.configuration.crosshairColor
        crosshairActiveColor = slideView.configuration.crosshairActiveColor
        circleLayer.fillColor = slideView.configuration.backgroundColor.cgColor
        
        //Frame
        self.frame = CGRect(x: 0.0, y: 0.0, width: slideView.safeView.bounds.width * 0.4, height: slideView.view.bounds.height * 0.4)
        
        circleLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2.0 * circleRadius, height: 2.0 * circleRadius), cornerRadius: circleRadius).cgPath
        circleLayer.position = CGPoint(x: self.frame.midX - circleRadius, y: self.frame.midY - circleRadius)
        
        self.layer.addSublayer(verticalLayer)
        self.layer.addSublayer(horizontalLayer)
        self.layer.addSublayer(circleLayer)
        
        update()
        
        //Add to parent view
        slideView.safeView.addSubview(self)
        
    }
    
    override func editState(active: Bool? = nil) -> Bool? {
        let editModeIsOn = super.editState(active: active)
        update()
        return editModeIsOn
    }
    
    override func update() {
        
        if editStateActive {
            verticalLayer.backgroundColor = crosshairActiveColor.cgColor
            horizontalLayer.backgroundColor = crosshairActiveColor.cgColor
            
        } else {
            verticalLayer.backgroundColor = crosshairColor.cgColor
            horizontalLayer.backgroundColor = crosshairColor.cgColor
        }
        
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
