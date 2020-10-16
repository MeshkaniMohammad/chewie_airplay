import Flutter
import Foundation

class SharePlatformViewFactory : NSObject, FlutterPlatformViewFactory {
    private weak var messenger: FlutterBinaryMessenger?

    init(messager: FlutterBinaryMessenger) {
        super.init()
        messenger = messager
    }

    private func createArgsCodec() -> FlutterMessageCodec {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) ->  FlutterPlatformView {
        let routePickerView = RoutePickerView(frame: frame, viewIdentifier: viewId, arguments: args)
        return routePickerView
    }
}
