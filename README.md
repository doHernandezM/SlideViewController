#  SlideViewController
   ==================

SlideViewController.

As easy as creating the view then giving it some viewControllers

For example:
* let subViewControllers =[zxyMapController, xyzfavesTableController, zxySettingController]
* let slideController = SlideViewController(newViewControllers: subViewControllers) //Sets view position based in order (ie 0 = Primary, 1 = Secondary etc)

Funtionality options

1. Many of these options as well as the options for the slider will be broken out to a struct that can be passed at any time.
* public var gridStyle:SlideViewPositions = .Primary
* public var rotateViewClockwise = false

2. If a rotation event if fleeting, get out of it after one rotation.
* private var stopEditAfterRotate = false

3. Edit mode can be set here, must update views after this is set.
* public var editModeActive = false

4. Make it so the slider will only move in one direction.
* private var xyLock: (x:Bool,y:Bool) = (false,false)
