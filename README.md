#  SlideViewController
   ==================

SlideViewController.

As easy as creating the view then giving it some viewControllers

For example:
1. let subViewControllers = [zxyMapController, xyzfavesTableController, zxySettingController]
2. let slideController = SlideViewController(newViewControllers: subViewControllers) //Sets view position based in order (ie 0 = Primary, 1 = Secondary, etc.)

Funtionality options

* Many of these options as well as the options for the slider will be broken out to a struct that can be passed at any time.
<public var gridStyle:SlideViewPositions = .Primary>
<public var rotateViewClockwise = false>

* If a rotation event if fleeting, get out of it after one rotation.
private var stopEditAfterRotate = false

* Edit mode can be set here, must update views after this is set.
public var editModeActive = false

* Make it so the slider will only move in one direction.
private var xyLock: (x:Bool,y:Bool) = (false,false)
