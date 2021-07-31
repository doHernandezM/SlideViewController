#  SlideViewController

SlideViewController.

As easy as creating the view then giving it some viewControllers

For example:
### let subViewControllers =[zxyMapController, xyzfavesTableController, zxySettingController]
### let slideController = SlideViewController(newViewControllers: subViewControllers) //Sets view position based in order (ie 0 = Primary, 1 = Secondary etc)

//MARK:Funtionality options
//Many of these options as well as the options for the slider will be broken out to a struc that can be passed at any time.
public var gridStyle:SlideViewPositions = .Primary
public var rotateViewClockwise = false
private var stopEditAfterRotate = false//If a rotation event if fleeting, get out of it after one rotation.
public var editModeActive = false//Edit mode can be set here, must update views after this is set.
private var xyLock: (x:Bool,y:Bool) = (false,false)//Make it so the slider will only move in one direction.


//MARK:Slider
private var sliderView = crosshairView(frame: CGRect())
private var slideViewBorderThickness = CGFloat(9)//Unless you have another mechanism for moving the slider, anything less than 9 is hard to tap.\
private var sliderPostitionPrecise = CGPoint() {//Use preciseSliderPosition or sliderPostitionRelative for better experience.
    willSet(newPoint) {
        sliderPostitionRelative = CGPoint(x: newPoint.x / self.view.bounds.width, y: newPoint.y / self.view.bounds.height)
    }
}
public var sliderPostitionRelative = CGPoint()
