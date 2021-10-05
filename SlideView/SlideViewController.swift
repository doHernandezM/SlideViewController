//
//  ViewController.swift
//  SlideViewController v0.9
//
//  Created by Dennis Hernandez on 7/26/21.
//

import UIKit


///Use this enum to define the SlideViews gridStyle as well as view position.
public enum Positions:Int {
    case Primary = 0, Secondary, Tertiary, Quaternary, Buffer
    
    static func ordered() -> [Positions]{
        return[Positions.Primary,Positions.Secondary,Positions.Tertiary,Positions.Quaternary]
    }
}

public struct SlideViewConfiguarationStruct {
    public var backgroundColor:UIColor = .systemBackground
    public var crosshairColor:UIColor = .systemGray
    public var crosshairActiveColor:UIColor = .systemBlue
    
    public var gridStyle:Positions = .Primary
    ///Display horizontal layouts in Portrait and vertical in Landscape.
    public var automaticallyAdjustedLayout:Bool = true
    public var rotateClockwise:Bool = true
    public var rotateViews:Bool = false
    ///If a rotation event is fleeting, get out of it after one rotation.
    public var stopEditAfterRotate:Bool = false
    ///Edit mode can be set here, must update views after this is set.
    public var editModeActive:Bool = false
    ///Make it so the slider will only move in one direction.
    public var autoXYLock: Bool = true
    public var xyLock: (x:Bool,y:Bool) = (false,false)
    
    ///Unless you have another mechanism for moving the slider, anything less than 9 is hard to tap.
    public let defaultSlideViewBorderThickness = CGFloat(9)
    public var currentSlideViewBorderThickness = CGFloat(0)
    
    public init() {
        currentSlideViewBorderThickness = defaultSlideViewBorderThickness
    }
}

open class SlideViewController: UIViewController {
    ///This is where are the views live.
    ///
    ///To make life we make one master view that conforms to safe area, then we build everything off of that.
    var safeView: UIView = UIView(frame: CGRect.zero)
    public var controllers: [Positions:UIViewController?] = [:]
    
    //MARK: Inits
    ///They are all the same.
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    ///We are creating generic view controllers for demo. Otherwise insert your own view controllers here with setViewControllers
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setViewControllers(newViewControllers: [])
//        setViewControllers(newViewControllers: createDevControllers(slideViewController: self, number: 2))//DEV:::DELETE for release
    }
    ///Use this to init with custom view controllers
    public init(newViewControllers: [UIViewController?]) {
        super.init(nibName: nil, bundle: nil)
        self.setViewControllers(newViewControllers: newViewControllers)
    }
    
    
    open override func viewDidLoad() {
        ///Setup View
        super.viewDidLoad()
        view.backgroundColor = self.configuration.backgroundColor
        self.view.clipsToBounds = true
        ///Add base safe view. This conforms to the Safe Area, so the rest of  my views don't ha have to.
        self.safeView.frame = self.view.frame
        self.view.addSubview(safeView)
        ///Set up our slider
        configureSlider()
        ///Add the controllers and set edit mode off.
        addControllersToView(newControllers: nil)
        
        updateViewLayouts()
        
        //Accessibility
        self.configureAccessibility()
    }
    
    //MARK: Funtionality options
    public var configuration: SlideViewConfiguarationStruct = SlideViewConfiguarationStruct() {
        didSet{
            self.sliderView.configure(slideView: self)
            self.updateViewLayouts()
        }
    }
    //Sets the configuration during runtime, then tells the view to update itself and it's children.
    public func setConfiguration(newConfiguration: SlideViewConfiguarationStruct?) {
        if newConfiguration == nil {
            self.configuration = SlideViewConfiguarationStruct()
        } else {
            self.configuration = newConfiguration!
        }
        self.updateViewLayouts()
    }
    
    //MARK: Slider
    private var sliderView = CrosshairView(frame: CGRect())
    //Use preciseSliderPosition or sliderPostitionRelative for better consistency.
    private var sliderPostitionPrecise = CGPoint() {
        willSet(newPoint) {
            sliderPostitionRelative = CGPoint(x: newPoint.x / self.safeView.bounds.width, y: newPoint.y / self.safeView.bounds.height)
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
        self.safeView.addGestureRecognizer(tapGesture)
        
        sliderView.configure(slideView:self)
        sliderView.center = self.safeView.center
        sliderPostitionPrecise = self.safeView.center
    }
    
    ///Move slider here.
    open func moveSliderTo(newLocation:CGPoint) {
        sliderPostitionPrecise = flitersSliderXY(newLocation: newLocation)
        
        sliderView.center = sliderPostitionPrecise
        updateViewLayouts()
    }
    
    ///Returns slider XY after chking to see if one axis is locked first.
    func flitersSliderXY(newLocation:CGPoint) -> CGPoint {
        var newLocationFiltered = newLocation
        
        if controllerCount() == 2 {
            switch configuration.gridStyle {
            case .Secondary,.Quaternary:
                newLocationFiltered.x = newLocation.x
            default:
                newLocationFiltered.y = newLocation.y
            }
        }
        
        switch configuration.xyLock {
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
    
    //MARK: Adding/Removing
    open func addViewControllers(newViewControllers: [UIViewController?]) {
        self.setViewControllers(newViewControllers: newViewControllers)
        self.addControllersToView(newControllers: self.controllers)
        setEditMode(configuration.editModeActive)
    }
    
    fileprivate func setViewControllers(newViewControllers:[UIViewController?]) {
        controllers[.Primary] = newViewControllers.count > 0 ? newViewControllers[Positions.Primary.rawValue] : nil
        controllers[.Secondary] = newViewControllers.count > 1 ? newViewControllers[Positions.Secondary.rawValue] : nil
        controllers[.Tertiary] = newViewControllers.count > 2 ? newViewControllers[Positions.Tertiary.rawValue] : nil
        controllers[.Quaternary] = newViewControllers.count > 3 ? newViewControllers[Positions.Quaternary.rawValue] : nil
    }
    
    //This is what actually adds views to the slideView.
    //FIXME: Simple remove and replace. In the Future this should be a merge.
    fileprivate func addControllersToView(newControllers: [Positions:UIViewController?]?) {
        if newControllers != nil {controllers = newControllers!}
        for (_,viewController) in controllers.enumerated() {
            if viewController.value != nil {
                self.addChild(viewController.value!)
                viewController.value!.view.clipsToBounds = true
                viewController.value!.view.frame = frameForPosition(position: viewController.key)
                safeView.addSubview(viewController.value!.view)
                viewController.value!.didMove(toParent: self)
            }
        }
        
    }
    
    //
    public func removeAllViews() {
        for (_,controllerObject) in controllers.enumerated() {
            if controllerObject.value != nil {
                let oldController = controllerObject.value!
                oldController.willMove(toParent: nil)
                oldController.view.removeFromSuperview()
                oldController.removeFromParent()
            }
        }
        controllers.removeAll()
    }
    
    //MARK: Edit Mode
    //Long press let's up control which view is where.
    open func setEditMode(_ editModeOn:Bool?) {
        
        if editModeOn != nil {
            configuration.editModeActive = editModeOn!
            _ = sliderView.editState(active:editModeOn!)
        } else {
            configuration.editModeActive = !configuration.editModeActive
            _ = sliderView.editState(active: configuration.editModeActive)
        }
        
        var subviewCornerRadius = CGFloat(0)
        if configuration.editModeActive {
            configuration.currentSlideViewBorderThickness = configuration.defaultSlideViewBorderThickness * 3.5
            subviewCornerRadius = CGFloat(5)
        } else {
            configuration.currentSlideViewBorderThickness = configuration.defaultSlideViewBorderThickness
            subviewCornerRadius = CGFloat(0)
        }
        
        for (_,viewController) in controllers {
            viewController?.view.layer.cornerRadius = subviewCornerRadius
        }
        
        UIView.animate(withDuration: 0.1) { [self] in
            updateViewLayouts()
        }
    }
    
    //MARK: Moving Views
    //Rotate Controller:
    //Make an array of all the keys (1,2,etc) sort one way or another
    open func rotateViewControllers(clockwise:Bool?) {
        let rotationDirection = clockwise ?? false
        var positionKeys: [Positions] = Array(controllers.keys)
        
        if rotationDirection {
            positionKeys = positionKeys.sorted(by: { $0.rawValue > $1.rawValue })
        } else {
            positionKeys = positionKeys.sorted(by: { $0.rawValue < $1.rawValue })
        }
        
        reorderViewControllers(newOrder: positionKeys)
        if configuration.stopEditAfterRotate {setEditMode(nil)}
    }
    
    //Reorder Controller:
    public func reorderViewControllers(newOrder:[Positions]) {
        var positionKeys: [Positions] = newOrder
        
        swapControllerPositions(&positionKeys)// Remove the buffer from the position keys
        //Find nonNil and nil views and puts them into the correct order.
        //Move nil views to the end of view controllers to make drawing code simpler.
        //We don't need to do any of this if there is only 1 view.
        if controllerCount() > 1 {
            
            var controllersBuffer: [Positions:UIViewController?] = controllers//We need a place to shuffle our views and nils into
            var nextNilView = controllers.count //count down from the end of the dict
            var nextView = 0 //count up from the beginning of the dict
            if controllers.count > 1 {
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
            }
        }
        //Once all the dict items are swapped, tell the views to redraw themselves
        UIView.animate(withDuration: 0.25) { [self] in
            updateViewLayouts()
        }
    }
    
    //Get an array of position keys, add a buffer key and swap position keys. Then update all of the frames.
    fileprivate func swapControllerPositions(_ positionKeys: inout [Positions]) {
        positionKeys.insert(Positions.Buffer, at: 0)
        //Swap keys on each dictionary item
        controllers[positionKeys[0]] = controllers[positionKeys[1]]
        controllers[positionKeys[1]] = controllers[positionKeys[2]]
        controllers[positionKeys[2]] = controllers[positionKeys[3]]
        controllers[positionKeys[3]] = controllers[positionKeys[4]]
        controllers[positionKeys[4]] = controllers[.Buffer]
        controllers.removeValue(forKey: .Buffer)
        positionKeys.removeFirst()
    }
    
    //Call this to change the views configuration(horizontal=Primary/vertical/top/bottom)
    public func changeGridStyle(style:Positions?) {
        if style != nil {
            configuration.gridStyle = style!
        } else {
            if configuration.gridStyle.rawValue < Positions.Quaternary.rawValue {//Almost often gets primary frames size
                configuration.gridStyle = Positions(rawValue: configuration.gridStyle.rawValue + 1)!
            } else {
                configuration.gridStyle = .Primary
            }
        }
        //Once all the dict items are swapped, tell the views to redraw themselves
        UIView.animate(withDuration: 0.25) { [self] in
            updateViewLayouts()
        }
    }
    
    //MARK: User interaction
    //PAN will move the slider around.
    @objc public func pan(_ gesture: UIPanGestureRecognizer? = nil)  {
        if gesture != nil {
            moveSliderTo(newLocation:gesture!.location(in: self.safeView))
        }
        
        //Accessibility Announcement
        if gesture?.state == .began {//Slider is sliding
            sliderView.accessibilityValue = "Slider is sliding"
            UIAccessibility.post(notification: .pageScrolled, argument: sliderView.accessibilityValue)
        }
        if gesture?.state == .ended {//Slider location
            sliderView.accessibilityValue = sliderLocationString()
            UIAccessibility.post(notification: .pageScrolled, argument: sliderView.accessibilityValue)
        }
        
    }
    //LONGPRESS will toggle edit mode on and off.
    @objc public func longPress(_ gesture: UIPanGestureRecognizer? = nil)  {
        if gesture != nil {
            switch gesture?.state {
            case .began:
                setEditMode(nil)
            case .cancelled:
                setEditMode(nil)
            default:
                break
            }
        }
    }
    //TAP during edit mode will rotate the views.
    @objc public func tap(_ gesture: UITapGestureRecognizer? = nil){
        if gesture != nil {
            if configuration.editModeActive {
                if configuration.rotateViews {
                    rotateViewControllers(clockwise: configuration.rotateClockwise)
                } else {
                    nextConfig(config: nil)
                }
                //TODO:Accessibility
                //                if gesture?.state == .ended {//MapView locations
                //                    sliderView.accessibilityValue = sliderLocationString()
                //                    UIAccessibility.post(notification: .pageScrolled, argument: sliderView.accessibilityValue)
                //                }
            }
            
        }
    }
    
    //MARK: Accessibility
    //Accessibility
    public func configureAccessibility() {
        self.view.isAccessibilityElement = false
        self.safeView.isAccessibilityElement = false
        sliderView.isAccessibilityElement = true
        sliderView.accessibilityLabel = "Slider"
    }
    public func sliderLocationString() -> String {
        var locationString = "Slider is: "
        let locationLeft = "\(Int(sliderPostitionRelative.x * 100))% from the left,"
        let locationTop = "\(Int(sliderPostitionRelative.y * 100))%, from the top, "
        switch configuration.xyLock { //XY Loc lets us know which axis to announce
        case (true,false):
            locationString = locationString + locationLeft
        case (false,true):
            locationString = locationString + locationTop
        case (false,false):
            locationString = locationString + locationLeft + locationTop
        default:
            locationString = "" //returns  fully locks
        }
        return locationString
    }
    
    //FIXME: Announce of views, voiceover
    //    var subViewPositionStringArray: [String?] = [nil,nil,nil,nil] {
    //        didSet {
    //            subViewPositionString = ""
    //            for (_,theViewLabel) in subViewPositionStringArray.enumerated() {
    //                if let viewLabel = theViewLabel {
    ////                        subViewPositionString = theViewLabel + "is in the "
    //                }
    //            }
    //        }
    //    }
    //
    //    var subViewPositionString = ""
    //
    
    
    //MARK:Draw code
    open override func viewWillLayoutSubviews() {
        let guide = view.safeAreaLayoutGuide
        self.safeView.frame = guide.layoutFrame
        //
        updateViewLayouts()
    }
    public override func viewDidLayoutSubviews() {
        moveSliderTo(newLocation: preciseSliderPosition)
        sliderView.update()
    }
    
    //Call this after you've made a change to the views or the super.(Called automatically with viewWillLayoutSubviews)
    open func updateViewLayouts() {
        if (controllerCount()) == 2 && configuration.automaticallyAdjustedLayout {
            if isWide && configIsWide {
                configuration.gridStyle = .Secondary
                if configuration.autoXYLock {
                    configuration.xyLock = (true,false)
                }
            }
            if !isWide && !configIsWide {
                configuration.gridStyle = .Primary
                if configuration.autoXYLock {
                    configuration.xyLock = (false,true)
                }
            }
        }
        
        
        for (_,viewController) in controllers.enumerated() {
            if let theController = viewController.value {
                let theControllerKey: Positions = viewController.key
                //Set the frame
                theController.view.frame = frameForPosition(position: theControllerKey)
                
                //                subViewPositionStringArray[i] = theController.accessibilityLabel
            }
        }
        
    }
    
    //MARK: View Positions
    public func nextConfig(config: Positions?) {
        if config != nil {
            configuration.gridStyle = config!
        } else if (controllerCount() == 2) && (configuration.automaticallyAdjustedLayout) {
            switch configuration.gridStyle {
            case .Primary:
                configuration.gridStyle = .Tertiary
            case .Secondary:
                configuration.gridStyle = .Quaternary
            case .Tertiary:
                configuration.gridStyle = .Primary
            case .Quaternary:
                configuration.gridStyle = .Secondary
            default:
                break
            }
        } else {
            configuration.gridStyle = (configuration.gridStyle == .Quaternary) ? .Primary : Positions(rawValue: configuration.gridStyle.rawValue + 1) ?? .Primary
        }
        UIView.animate(withDuration: 0.25) { [self] in
            updateViewLayouts()
        }
    }
    //Return a view frame based on location, primary frame location and number of views
    open func frameForPosition(position:Positions) -> CGRect {
        var newFrame = self.safeView.bounds
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
            //Four potential positions for a three view layout. 1,2,3,4. Quaternary always returns Primary JIC of rotation.
        case 3:
            switch configuration.gridStyle {
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
            case .Tertiary:
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
            switch configuration.gridStyle {
            case .Primary:
                newFrame = (position == .Primary) || (position == .Quaternary) ? topFrame : bottomFrame
            case .Secondary:
                newFrame = (position == .Primary) || (position == .Quaternary) ? leftFrame : rightFrame
            case .Tertiary:
                newFrame = (position == .Primary) || (position == .Quaternary) ? bottomFrame : topFrame
            case .Quaternary:
                newFrame = (position == .Primary) || (position == .Quaternary) ? rightFrame : leftFrame
            default:
                newFrame = CGRect.zero //Always return zero in weird cases
            }
            //Better single view options needed in future.
        default:
//            switch position {
//            case .Primary:
//                newFrame = primaryFrame
//            case .Secondary:
//                newFrame = secondaryFrame
//            case .Tertiary:
//                newFrame = tertiaryFrame
//            case .Quaternary:
//                newFrame = quaternaryFrame
//            default:
//                newFrame = fullFrame //Always return full in weird cases
//            }
            newFrame = fullFrame
            
        }
        
        return newFrame
    }
    
    //MARK: Utilities
    public func controllerCount() -> Int {
        var count = 0
        
        if (controllers[.Primary] == nil) {count += 0
        } else {
            count = count + ((controllers[.Primary]! != nil) ? 1 : 0)
        }
        if (controllers[.Secondary] == nil) {count += 0
        } else {
            count = count + ((controllers[.Secondary]! != nil) ? 1 : 0)
        }
        if (controllers[.Tertiary] == nil) {count += 0
        } else {
            count = count + ((controllers[.Tertiary]! != nil) ? 1 : 0)
        }
        if (controllers[.Quaternary] == nil) {count += 0
        } else {
            count = count + ((controllers[.Quaternary]! != nil) ? 1 : 0)
        }
        
        return count
    }
    
    //Frame calc utilities
    var left:CGFloat {
        return self.safeView.bounds.origin.x
    }
    var right:CGFloat {
        return self.safeView.bounds.size.width
    }
    var top:CGFloat {
        return self.safeView.bounds.origin.y
    }
    var bottom:CGFloat {
        return self.safeView.bounds.size.height
    }
    var halfSlideViewBorderThickness: CGFloat {
        return (configuration.currentSlideViewBorderThickness * 0.5)
    }
    
    var fullFrame:CGRect {
        return CGRect(x: left, y: top, width: right, height: bottom)
    }
    var topFrame:CGRect {
        return CGRect(x: left, y: top, width: self.safeView.bounds.size.width, height: preciseSliderPosition.y - halfSlideViewBorderThickness)
    }
    var bottomFrame:CGRect {
        return CGRect(x: left, y: middleY, width: self.safeView.bounds.size.width, height: self.safeView.bounds.size.height - (primarySize.height + configuration.currentSlideViewBorderThickness))
    }
    var leftFrame:CGRect {
        return CGRect(x: left, y: top, width: preciseSliderPosition.x - halfSlideViewBorderThickness, height: self.safeView.bounds.size.height)
    }
    var rightFrame:CGRect {
        return CGRect(x: middleX, y: top, width: self.safeView.bounds.size.width - (primarySize.width + configuration.currentSlideViewBorderThickness), height: self.safeView.bounds.size.height)
    }
    
    var primarySize:CGSize {
        return CGSize(width: preciseSliderPosition.x - halfSlideViewBorderThickness, height: preciseSliderPosition.y - halfSlideViewBorderThickness)
    }
    var primaryFrame:CGRect {
        return CGRect(x: left, y: top, width: preciseSliderPosition.x - halfSlideViewBorderThickness, height: preciseSliderPosition.y - halfSlideViewBorderThickness)
    }
    var secondaryFrame:CGRect {
        return CGRect(x: middleX, y: top, width: self.safeView.bounds.size.width - (primarySize.width + configuration.currentSlideViewBorderThickness), height: preciseSliderPosition.y - halfSlideViewBorderThickness)
    }
    var tertiaryFrame:CGRect {
        return CGRect(x: middleX, y: middleY, width:self.safeView.bounds.size.width - (primarySize.width + configuration.currentSlideViewBorderThickness), height: self.safeView.bounds.size.height - (primarySize.height + configuration.currentSlideViewBorderThickness))
    }
    var quaternaryFrame:CGRect {
        return CGRect(x: left, y: middleY, width: preciseSliderPosition.x - halfSlideViewBorderThickness, height: self.safeView.bounds.size.height - (primarySize.height + configuration.currentSlideViewBorderThickness))
    }
    
    var middleX:CGFloat {
        return preciseSliderPosition.x + halfSlideViewBorderThickness
    }
    var middleY:CGFloat {
        return (self.safeView.bounds.size.height * centerSliderY) + halfSlideViewBorderThickness
    }
    var centerSliderX:CGFloat {
        return (preciseSliderPosition.x / self.safeView.bounds.size.width)
    }
    var centerSliderY:CGFloat {
        return (preciseSliderPosition.y / self.safeView.bounds.size.height)
    }
    var viewSizeWidth:CGFloat {
        return (self.safeView.bounds.size.width - configuration.currentSlideViewBorderThickness) * 0.5
    }
    var viewSizeHeight:CGFloat {
        return (self.safeView.bounds.size.height - configuration.currentSlideViewBorderThickness) * 0.5
    }
    var isWide:Bool {
        if viewSizeWidth > viewSizeHeight {
            return true
        }
        return false
    }
    var configIsWide:Bool {
        switch configuration.gridStyle {
        case .Primary, .Tertiary:
            return true
        case .Secondary, .Quaternary:
            return false
        default:
            return false
        }
        
    }
    var preciseSliderPosition:CGPoint {
        sliderPostitionPrecise = CGPoint(x: sliderPostitionRelative.x * self.safeView.bounds.width, y: sliderPostitionRelative.y * self.safeView.bounds.height)
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
