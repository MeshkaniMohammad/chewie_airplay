import AVKit
import Flutter

class RoutePickerView : NSObject, FlutterPlatformView {
    
    private var viewId: Int64 = 0
    private var channel: FlutterMethodChannel?
    private var routePickerView: UIView
    

    init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) {
        if #available(iOS 11.0, *) {
            routePickerView = AVRoutePickerView()
            routePickerView.tintColor = UIColor.clear
            routePickerView.backgroundColor = UIColor.clear
            (routePickerView as? AVRoutePickerView)?.activeTintColor = UIColor.clear
        } else {
            routePickerView = UIView()
        }
    }

    func view() -> UIView {
        return routePickerView
    }
}
