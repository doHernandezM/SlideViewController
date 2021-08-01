#  SlideViewController

![A SlideViewController](https://dohernandez.net/wp-content/uploads/sites/2/2021/08/IMG_0421.jpeg)
![A SlideViewController](https://dohernandez.net/wp-content/uploads/sites/2/2021/08/IMG_0416.jpeg)

Do you need to display multiple UIVIewControllers in a small space? Do their frames need to be user adjustable? That's what SlideViewController is for.
Automatically displays up to four views depending on how many views it is sent. Can be configured with a horizontal or vertical orientation and to rotate clockwise or counter-clockwise.

Slider Gestures:
* PAN will move the slider around.
* LONGPRESS will toggle edit mode on and off.
* TAP during edit mode will rotate the views. Or you can set it to change the configuration(horizontal/vertical/top/bottom) by calling `changeGridStyle`.

As easy as creating the view then giving it some viewControllers

For example:
```swift
let subViewControllers = [zxyMapController, xyzfavesTableController, zxySettingController]
let slideController = SlideViewController(newViewControllers: subViewControllers) //Sets view position based in order (ie 0 = Primary, 1 = Secondary, etc.)
```
Funtionality options

* Many of these options as well as the options for the slider will be broken out to a struct that can be passed at any time. For now, many are private and are not meant to be called during runtime, but can.
```swift
public var gridStyle:SlideViewPositions = .Primary
public var rotateViewClockwise = false
```

* If a rotation event is fleeting, get out of it after one rotation.
```swift
private var stopEditAfterRotate = false
```

* Edit mode can be set here, must update views after this is set.
```swift
public var editModeActive = false
```
* Make it so the slider will only move in one direction.
```swift
private var xyLock: (x:Bool,y:Bool) = (false,false)
```

To Fix:
* Add accessibility
* While devs should make sure they are inside safe area, add a more fool proof way to ensure this.
