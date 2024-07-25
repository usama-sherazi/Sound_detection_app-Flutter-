#import "AbtoVoipSdkPlugin.h"
#if __has_include(<abto_voip_sdk/abto_voip_sdk-Swift.h>)
#import <abto_voip_sdk/abto_voip_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "abto_voip_sdk-Swift.h"
#endif

@implementation AbtoVoipSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAbtoVoipSdkPlugin registerWithRegistrar:registrar];
}
@end
