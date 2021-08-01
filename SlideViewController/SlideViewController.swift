//
//  ViewController.swift
//  SlideViewController
//
//  Created by Dennis Hernandez on 7/26/21.
//

import UIKit

class SlideViewController: UIViewController {
    //This is wehere are the view live. It's best that they are sorted with any nill at the end of the dict(ie 1,2,nil,nil)
    private var controllers: [SlideViewPositions:UIViewController?] = [:]
    
    //MARK: Inits
    //They are all the same. We are creating generic view controllers for demo. Otherwise insert your own view controllers here with setViewControllers
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setViewControllers(newViewControllers: createDevControllers(number: 4))//DEV:::DELETE for release
    }
    init(newViewControllers: [UIViewController?]) {//Use this to init with custom view controllers
        super.init(nibName: nil, bundle: nil)
        self.setViewControllers(newViewControllers: newViewControllers)
    }
    
    //Use this enum to define the SlideViews gridStyle as well as view position.
    public enum SlideViewPositions:Int {
        case Primary = 0, Secondary, Tertiary, Quaternary, Buffer
        
        static func ordered() -> [SlideViewPositions]{
            return[SlideViewPositions.Primary,SlideViewPositions.Secondary,SlideViewPositions.Tertiary,SlideViewPositions.Quaternary]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        self.view.clipsToBounds = true
        
        configureSlider()
        
        addControllersToView(newControllers: nil)
        
        updateViewLayouts()
    }
    
    //MARK:DEV
    //FIXME:Remove, dev only
    //This creates generic view controllers to test with.
    func createDevControllers(number:Int) -> [UIViewController] {
        var viewControllers:[UIViewController] = []// = [nil,nil,nil,nil]
        
        for i in 0..<(number - 1) {
            viewControllers.append(UIViewController())
            viewControllers[i].view.backgroundColor = UIColor.randomColor()
            if number == 1 {return viewControllers}
        }
        //SlideCeption
        var subsSlideViewControllers: [UIViewController] = []

        for i in 0..<3 {
            subsSlideViewControllers.append(UIViewController())
            subsSlideViewControllers[i].view.backgroundColor = UIColor.randomColor()
        }

        viewControllers.append(SlideViewController(newViewControllers: subsSlideViewControllers))
        return viewControllers
    }
    
    //MARK:Funtionality options
    //Many of these options as well as the options for the slider will be broken out to a struc that can be passed at any time.
    public var gridStyle:SlideViewPositions = .Primary
    public var rotateViewClockwise = false
    private var stopEditAfterRotate = false//If a rotation event if fleeting, get out of it after one rotation.
    public var editModeActive = false//Edit mode can be set here, must update views after this is set.
    private var xyLock: (x:Bool,y:Bool) = (false,false)//Make it so the slider will only move in one direction.
    
    
    //MARK:Slider
    private var sliderView = CrosshairView(frame: CGRect())
    private var slideViewBorderThickness = CGFloat(9)//Unless you have another mechanism for moving the slider, anything less than 9 is hard to tap.\
    private var sliderPostitionPrecise = CGPoint() {//Use preciseSliderPosition or sliderPostitionRelative for better experience.
        willSet(newPoint) {
            sliderPostitionRelative = CGPoint(x: newPoint.x / self.view.bounds.width, y: newPoint.y / self.view.bounds.height)
        }
    }
    public var sliderPostitionRelative = CGPoint()
    
    fileprivate func configureSlider() {
        sliderView.isUserInteractionEnabled = true
        //Add slider first, or change order to bottom later.
        //Pan gesture/drag move slider center point
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.pan(_:)))
        sliderView.addGestureRecognizer(panGesture)
        //Long press will activate edit mode
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(_:)))
        sliderView.addGestureRecognizer(longPressGesture)
        //Long press will activate edit mode
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tap(_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        sliderView.configure(slideView:self)
        sliderView.center = self.view.center
        sliderPostitionPrecise = self.view.center
    }
    
    func moveSliderTo(newLocation:CGPoint) {
        sliderPostitionPrecise = flitersSliderXY(newLocation: newLocation)
        
        sliderView.center = sliderPostitionPrecise
        updateViewLayouts()
    }
    
    //Returns slider XY after chking to see if one axis is locked first.
    func flitersSliderXY(newLocation:CGPoint) -> CGPoint {
        var newLocationFiltered = newLocation
        
        if controllerCount() == 2 {
            switch gridStyle {
            case .Secondary,.Quaternary:
                newLocationFiltered.x = newLocation.x
            default:
                newLocationFiltered.y = newLocation.y
            }
            return newLocationFiltered
        }
        
        switch xyLock {
        case (true,false):
            newLocationFiltered.x = newLocation.x
            newLocationFiltered.y = sliderPostitionPrecise.y
        case (false,true):
            newLocationFiltered.x = sliderPostitionPrecise.x
            newLocationFiltered.y = newLocation.y
        case (false,false):
            newLocationFiltered = newLocation
        default:
            newLocationFiltered = sliderPostitionPrecise //returns  fully locks
        }
        
        return newLocationFiltered
    }
    
    //MARK:Adding/Removing/Moving Views
    func setViewControllers(newViewControllers:[UIViewController?]) {
        controllers[.Primary] = newViewControllers.count > 0 ? newViewControllers[SlideViewPositions.Primary.rawValue] : nil
        controllers[.Secondary] = newViewControllers.count > 1 ? newViewControllers[SlideViewPositions.Secondary.rawValue] : nil
        controllers[.Tertiary] = newViewControllers.count > 2 ? newViewControllers[SlideViewPositions.Tertiary.rawValue] : nil
        controllers[.Quaternary] = newViewControllers.count > 3 ? newViewControllers[SlideViewPositions.Quaternary.rawValue] : nil
        
    }
    
    //This is what actually adds views to the slideView.
    //FIXME: You must remove old views first or they may still be children of the slideView.
    func addControllersToView(newControllers: [SlideViewPositions:UIViewController?]?) {
        if newControllers != nil {controllers = newControllers!}//Simple replace. In the Future this should be a merge.
        for (_,viewController) in controllers.enumerated() {
            if viewController.value != nil {
                self.addChild(viewController.value!)
                viewController.value!.view.frame = frameForPosition(position: viewController.key)
                view.addSubview(viewController.value!.view)
                viewController.value!.didMove(toParent: self)
            }
        }
    }
    
    func removeControllerFromView(oldControllers:[UIViewController]) {
        for (_,oldController) in oldControllers.enumerated() {
            for (_,viewController) in controllers.enumerated() {
                if viewController.value == oldController {
                    oldController.willMove(toParent: nil)
                    oldController.view.removeFromSuperview()
                    oldController.removeFromParent()
                }
            }
        }
    }
    
    //Long press let's up control which view is where.
    func toggleEditMode() {
        var subviewCornerRadius = CGFloat(0)
        
        editModeActive = !editModeActive
        _ = sliderView.editState(active: editModeActive)
        
        if editModeActive {
            slideViewBorderThickness = slideViewBorderThickness * 3.5
            subviewCornerRadius = CGFloat(5)
        } else {
            slideViewBorderThickness = CGFloat(9)
            subviewCornerRadius = CGFloat(0)
        }
        
        for (_,viewController) in controllers {
            viewController?.view.layer.cornerRadius = subviewCornerRadius
        }
        
        UIView.animate(withDuration: 0.025) { [self] in
            updateViewLayouts()
        }
    }
    
    //Rotate Controller:
    //Make an array of all the keys (1,2,etc) sort one way or another
    func rotateViewControllers(clockwise:Bool?) {
        let rotationDirection = clockwise ?? false
        var positionKeys: [SlideViewPositions] = Array(controllers.keys)
        
        if rotationDirection {
            positionKeys = positionKeys.sorted(by: { $0.rawValue > $1.rawValue })
        } else {
            positionKeys = positionKeys.sorted(by: { $0.rawValue < $1.rawValue })
        }
        
        reorderViewControllers(newOrder: positionKeys)
        if stopEditAfterRotate {toggleEditMode()}
    }
    
    //Reorder Controller:
    func reorderViewControllers(newOrder:[SlideViewPositions]) {
        var positionKeys: [SlideViewPositions] = newOrder
        
        swapControllerPositions(&positionKeys)// Remove the buffer from the position keys
        //FIXME:Counterclockwise doens't work well yet.
        //Find nonNil and nil views and puts them into the correct order.
        //Move nil views to the end of view controllers to make drawing code simpler.
        var controllersBuffer: [SlideViewPositions:UIViewController?] = controllers//We need a place to shuffle our views and nils into
        var nextNilView = controllers.count //count down from the end of the dict
        var nextView = 0 //count up from the beginning of the dict
        for (_,position) in (positionKeys.enumerated()) {
            if controllers[position]! == nil {
                nextNilView -= 1
                controllersBuffer[positionKeys[nextNilView]] = controllers[position]
            } else {
                controllersBuffer[positionKeys[nextView]] = controllers[position]
                nextView += 1
            }
        }
        controllers = controllersBuffer
        
        //Once all the dict items are swapped, tell the views to redraw themselves
        UIView.animate(withDuration: 0.1) { [self] in
            updateViewLayouts()
        }
    }
    
    //Get an array of position keys, add a buffer key and swap position keys. Then update all of the frames.
    fileprivate func swapControllerPositions(_ positionKeys: inout [SlideViewController.SlideViewPositions]) {
        positionKeys.insert(.Buffer, at: 0)
        //Swap keys on each dictionary item
        controllers[positionKeys[0]] = controllers[positionKeys[1]]
        controllers[positionKeys[1]] = controllers[positionKeys[2]]
        controllers[positionKeys[2]] = controllers[positionKeys[3]]
        controllers[positionKeys[3]] = controllers[positionKeys[4]]
        controllers[positionKeys[4]] = controllers[.Buffer]
        controllers.removeValue(forKey: .Buffer)
        positionKeys.removeFirst()
    }
    
    //Call this to change the views congifuration(horizontal=Primary/vertical/top/bottom)
    func changeGridStyle(style:SlideViewPositions?) {
        if style != nil {
            gridStyle = style!
        } else {
            if gridStyle.rawValue < SlideViewPositions.Quaternary.rawValue {//Almost often gets primary frames size
                gridStyle = SlideViewPositions(rawValue: gridStyle.rawValue + 1)!
            } else {
                gridStyle = .Primary
            }
        }
        //Once all the dict items are swapped, tell the views to redraw themselves
        UIView.animate(withDuration: 0.1) { [self] in
            updateViewLayouts()
        }
    }
    
    //MARK:User interaction
    //PAN will move the slider around.
    @objc func pan(_ gesture: UIPanGestureRecognizer? = nil)  {
        if gesture != nil {
            moveSliderTo(newLocation:gesture!.location(in: self.view))
        }
        
    }
    //LONGPRESS will toggle edit mode on and off.
    @objc func longPress(_ gesture: UIPanGestureRecognizer? = nil)  {
        if gesture != nil {
            switch gesture?.state {
            case .began:
                toggleEditMode()
            case .cancelled:
                toggleEditMode()
            default:
                break
            }
        }
    }
    //TAP during edit mode will rotate the views.
    @objc func tap(_ gesture: UITapGestureRecognizer? = nil){
        if gesture != nil {
            if editModeActive {
                rotateViewControllers(clockwise: rotateViewClockwise)
            }
            
        }
    }
    
    //MARK:Draw code
    override func viewWillLayoutSubviews() {
        updateViewLayouts()
    }
    override func viewDidLayoutSubviews() {
        moveSliderTo(newLocation: preciseSliderPosition)
        sliderView.update()
    }
    
    //Call this after you've made a change to the views or the super.(Called automatically with viewWillLayoutSubviews)
    func updateViewLayouts() {
        for (_,viewController) in controllers.enumerated() {
            if viewController.value != nil {
                viewController.value!.view.frame = frameForPosition(position: viewController.key)
            }
        }
        
    }
    //MARK:View Positions
    //Return a view frame based on location, primary frame location and number of views
    func frameForPosition(position:SlideViewPositions) -> CGRect {
        var newFrame = self.view.bounds
        let numberOfViews = controllerCount()
        
        //Four views, easy
        switch numberOfViews {
        case 4:
            switch position {
            case .Primary:
                newFrame = primaryFrame
            case .Secondary:
                newFrame = secondaryFrame
            case .Tertiary:
                newFrame = tertiaryFrame
            case .Quaternary:
                newFrame = quaternaryFrame
            default:
                newFrame = CGRect.zero //Always return zero in weird cases
            }
        //Four potential positions for a three view layout. 1,2,3,4. QUaternary always returns Primary JIC of rotation.
        case 3:
            switch gridStyle {
            case .Primary:
                switch position {
                case .Primary:
                    newFrame = leftFrame
                case .Secondary:
                    newFrame = secondaryFrame
                case .Tertiary:
                    newFrame = tertiaryFrame
                case .Quaternary:
                    newFrame = leftFrame
                default:
                    newFrame = CGRect.zero //Always return zero in weird cases
                }
            case .Secondary:
                switch position {
                case .Primary:
                    newFrame = rightFrame
                case .Secondary:
                    newFrame = quaternaryFrame
                case .Tertiary:
                    newFrame = primaryFrame
                case .Quaternary:
                    newFrame = rightFrame
                default:
                    newFrame = CGRect.zero //Always return zero in weird cases
                }
            case .Tertiary:
                switch position {
                case .Primary:
                    newFrame = topFrame
                case .Secondary:
                    newFrame = tertiaryFrame
                case .Tertiary:
                    newFrame = quaternaryFrame
                case .Quaternary:
                    newFrame = topFrame
                default:
                    newFrame = CGRect.zero //Always return zero in weird cases
                }
            case .Quaternary:
                switch position {
                case .Primary:
                    newFrame = bottomFrame
                case .Secondary:
                    newFrame = primaryFrame
                case .Tertiary:
                    newFrame = secondaryFrame
                case .Quaternary:
                    newFrame = bottomFrame
                default:
                    newFrame = CGRect.zero //Always return zero in weird cases
                }
            default:
                newFrame = CGRect.zero //Always return zero in weird cases
            }
        //Two potention configs, horizonal(1,3) or vertical(2,4)
        case 2:
            switch gridStyle {
            case .Primary, .Tertiary:
                newFrame = (position == .Primary) || (position == .Quaternary) ? topFrame : bottomFrame
            case .Secondary, .Quaternary:
                newFrame = (position == .Primary) || (position == .Quaternary) ? leftFrame : rightFrame
            default:
                newFrame = CGRect.zero //Always return zero in weird cases
            }
        //Better single view options needed in future.
        default:
            switch position {
            case .Primary:
                newFrame = primaryFrame
            case .Secondary:
                newFrame = secondaryFrame
            case .Tertiary:
                newFrame = tertiaryFrame
            case .Quaternary:
                newFrame = primaryFrame
            default:
                newFrame = CGRect.zero //Always return zero in weird cases
            }
            
        }
        
        return newFrame
    }
    
    //MARK: Utilities
    func controllerCount() -> Int {
        var count = 0
        
        count = count + ((controllers[.Primary]! != nil) ? 1 : 0)
        count = count + ((controllers[.Secondary]! != nil) ? 1 : 0)
        count = count + ((controllers[.Tertiary]! != nil) ? 1 : 0)
        count = count + ((controllers[.Quaternary]! != nil) ? 1 : 0)
        
        return count
    }
    
    //Frame calc utilities
    var left:CGFloat {
        return self.view.bounds.origin.x
    }
    var right:CGFloat {
        return self.view.bounds.size.width
    }
    var top:CGFloat {
        return self.view.bounds.origin.y
    }
    var bottom:CGFloat {
        return self.view.bounds.size.height
    }
    var halfSlideViewBorderThickness: CGFloat {
        return (slideViewBorderThickness * 0.5)
    }
    
    var topFrame:CGRect {
        return CGRect(x: left, y: top, width: self.view.bounds.size.width, height: preciseSliderPosition.y - halfSlideViewBorderThickness)
    }
    var bottomFrame:CGRect {
        return CGRect(x: left, y: middleY, width: self.view.bounds.size.width, height: self.view.bounds.size.height - (primarySize.height + slideViewBorderThickness))
    }
    var leftFrame:CGRect {
        return CGRect(x: left, y: top, width: preciseSliderPosition.x - halfSlideViewBorderThickness, height: self.view.bounds.size.height)
    }
    var rightFrame:CGRect {
        return CGRect(x: middleX, y: top, width: self.view.bounds.size.width - (primarySize.width + slideViewBorderThickness), height: self.view.bounds.size.height)
    }
    
    var primarySize:CGSize {
        return CGSize(width: preciseSliderPosition.x - halfSlideViewBorderThickness, height: preciseSliderPosition.y - halfSlideViewBorderThickness)
    }
    var primaryFrame:CGRect {
        return CGRect(x: left, y: top, width: preciseSliderPosition.x - halfSlideViewBorderThickness, height: preciseSliderPosition.y - halfSlideViewBorderThickness)
    }
    var secondaryFrame:CGRect {
        return CGRect(x: middleX, y: top, width: self.view.bounds.size.width - (primarySize.width + slideViewBorderThickness), height: preciseSliderPosition.y - halfSlideViewBorderThickness)
    }
    var tertiaryFrame:CGRect {
        return CGRect(x: middleX, y: middleY, width:self.view.bounds.size.width - (primarySize.width + slideViewBorderThickness), height: self.view.bounds.size.height - (primarySize.height + slideViewBorderThickness))
    }
    var quaternaryFrame:CGRect {
        return CGRect(x: left, y: middleY, width: preciseSliderPosition.x - halfSlideViewBorderThickness, height: self.view.bounds.size.height - (primarySize.height + slideViewBorderThickness))
    }
    
    var middleX:CGFloat {
        return preciseSliderPosition.x + halfSlideViewBorderThickness
    }
    var middleY:CGFloat {
        return (self.view.bounds.size.height * centerSliderY) + halfSlideViewBorderThickness
    }
    var centerSliderX:CGFloat {
        return (preciseSliderPosition.x / self.view.bounds.size.width)
    }
    var centerSliderY:CGFloat {
        return (preciseSliderPosition.y / self.view.bounds.size.height)
    }
    var viewSizeWidth:CGFloat {
        return (self.view.bounds.size.width - slideViewBorderThickness) * 0.5
    }
    var viewSizeHeight:CGFloat {
        return (self.view.bounds.size.height - slideViewBorderThickness) * 0.5
    }
    var preciseSliderPosition:CGPoint {
        sliderPostitionPrecise = CGPoint(x: sliderPostitionRelative.x * self.view.bounds.width, y: sliderPostitionRelative.y * self.view.bounds.height)
        return sliderPostitionPrecise
    }
    
}

extension UIColor {
    static func randomColor() -> UIColor {
        let randomNumber = Int.random(in: 1...11)
        
        switch randomNumber {
        case 1:
            return .systemRed
        case 2:
            return .systemOrange
        case 3:
            return .systemYellow
        case 4:
            return .systemGreen
        case 5:
            return .blue
        case 6:
            return .systemPurple
        case 7:
            return .black
        case 8:
            return .brown
        case 9:
            return .cyan
        case 10:
            return .systemPink
        case 11:
            return .white
        default:
            return .magenta
        }
    }
}
