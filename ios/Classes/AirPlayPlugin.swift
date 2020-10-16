import Flutter

public class AirPlayPlugin : NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "airplay", binaryMessenger: registrar.messenger())
        let instance = AirPlayPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        registrar.register(SharePlatformViewFactory(messager: registrar.messenger()), withId: "airplay")

    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if ("getPlatformVersion" == call.method) {
            result("iOS " + (UIDevice.current.systemVersion))
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}
