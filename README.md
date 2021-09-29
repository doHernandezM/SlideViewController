#  SlideViewController

<img src="githubMedia/slider1.PNG" alt="drawing" height="200"/>
<img src="githubMedia/slider2.PNG" alt="drawing" width="300"/>
<img src="githubMedia/slider3.PNG" alt="drawing" height="200"/>

Do you need to display multiple UIVIewControllers in a small space? Do their frames need to be user adjustable? That's what SlideViewController is for.
Automatically displays up to four views depending on how many views it is sent. Can be configured with a horizontal or vertical orientation and to rotate clockwise or counter-clockwise.
This swift UIViewController subclass requires iOS 13+ or macOS Catalyst 10.15+.

Slider Gestures:
* PAN will move the slider around.
* LONGPRESS will toggle edit mode on and off.
* TAP during edit mode will rotate the views. Or you can set it to change the configuration(horizontal/vertical/top/bottom) by calling `changeGridStyle`.

As easy as creating the view then giving it some viewControllers

For example:
```swift
let subViewControllers = [zxyMapController, xyzFavesTableController, zxySettingController]
let slideController = SlideViewController(newViewControllers: subViewControllers) //Sets view position based in order (ie 0 = Primary, 1 = Secondary, etc.)
```
## Funtionality options:
Many of these options are not meant to be called during runtime, but can be.
* This struct passes configuration options to the SlideViewController. 
```swift
struct SlideViewConfiguarationStruct {}
```
* Color and Size options:
```swift
func setConfiguration(newConfiguration: SlideViewConfiguarationStruct?)

var backgroundColor:UIColor = .systemBackground
var crosshairColor:UIColor = .systemGray
var crosshairActiveColor:UIColor = .systemBlue
```
* Inter-view border thickness. Unless you have another mechanism for moving the slider, anything less than 9 is hard to tap.

```swift
var slideViewBorderThickness = CGFloat(9)
```
* Interface options:
```swift
var gridStyle:SlideViewPositions = .Primary
var rotateClockwise:Bool = true
var rotateViews:Bool = false
var stopEditAfterRotate:Bool = false//If a rotation event if fleeting, get out of it after one rotation.
var editModeActive:Bool = false//Edit mode can be set here, must update views after this is set.
var xyLock: (x:Bool,y:Bool) = (false,false)//Make it so the slider will only move in one direction.
```

## Accessibility options:
* SlideView calls out the slider location, but will not call out child view locations. Possible for future update.


## To Fix:
* ~~Add accessibility~~ Catalyst accessibility needs work/Slider's voiceover script needs to support internationalization, just english for now.
* ~~When adding views, if you are in edit mode, new views do not get rounded corners.
* ~~Single view mode is currently stuck in the upper left hand corner.~~
* Change "config" to primary view position and change SliderViewPosition to something else
