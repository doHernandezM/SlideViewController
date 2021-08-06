//
//  DemoViewController.swift
//  SlideViewController
//
//  Created by Dennis Hernandez on 7/31/21.
//

import UIKit

//MARK:DEV
//FIXME:Remove, dev only
let demoView = DemoViewController()

//This creates generic view controllers to test with.
func createDevControllers(slideViewController:SlideViewController?,number:Int) -> [UIViewController] {
    var viewControllers:[UIViewController] = []// = [nil,nil,nil,nil]
    
    demoView.slideViewController = slideViewController
    demoView.view.backgroundColor = UIColor.randomColor()
    viewControllers.append(demoView)
    
    if number == 1 {return viewControllers}

//    SlideCeption - Cause it's cute
    var subsSlideViewControllers: [UIViewController] = []
    for i in 0..<2 {
        subsSlideViewControllers.append(UIViewController())
        subsSlideViewControllers[i].view.backgroundColor = UIColor.randomColor()
    }
    viewControllers.append(SlideViewController(newViewControllers: subsSlideViewControllers))

    if number == 2 {return viewControllers}
   
    for i in 2..<(number) {
        viewControllers.append(UIViewController())
        viewControllers[i].view.backgroundColor = UIColor.randomColor()
    }
    
    return viewControllers
}


class DemoViewController: UIViewController, SlideViewControllerDelegate {
    
    var slideViewController: SlideViewController? = nil
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if slideViewController == nil {return}
        clockwiseSwitch!.isOn = slideViewController!.configuration.rotateClockwise
        configurationStepper!.value = Double(slideViewController!.configuration.gridStyle.rawValue)
        viewCountStepper!.value = Double(slideViewController!.controllerCount())
        
        self.view!.accessibilityLabel = "DemoView"
        self.view!.accessibilityHint = "Change settings"
//        self.view!.isAccessibilityElement = false
        clockwiseSwitch!.isAccessibilityElement = true
        clockwiseSwitch!.accessibilityLabel = "Slider"

    }
    
    @IBOutlet weak var viewCountStepper: UIStepper?
    @IBOutlet weak var configurationStepper: UIStepper?
    @IBOutlet weak var clockwiseSwitch: UISwitch?
    
    @IBAction func updateOptions(sender: Any) {
        if slideViewController == nil {return}
        
        if sender as? UIStepper == viewCountStepper {
            let numberOfViews = Int(viewCountStepper!.value)
            slideViewController!.removeAllViews()
            slideViewController!.addViewControllers(newViewControllers: createDevControllers(slideViewController: slideViewController, number: numberOfViews))
            return
        }
        
        if sender as? UIStepper == configurationStepper {
            let style: SlideViewPositions? = SlideViewPositions(rawValue: Int((sender as! UIStepper).value))
            slideViewController!.changeGridStyle(style:style)
            return
        }
        
        if sender as? UISwitch == clockwiseSwitch {
            slideViewController?.configuration.rotateClockwise = clockwiseSwitch!.isOn
            return
        }
    }
}
