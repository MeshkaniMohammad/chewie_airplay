#import "VideoplayPlugin.h"
#import <videoplay/videoplay-Swift.h>

@implementation VideoPlayPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [AirPlayPlugin registerWithRegistrar:registrar];
}
@end
