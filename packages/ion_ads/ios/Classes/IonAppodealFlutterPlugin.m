#import "IonAppodealFlutterPlugin.h"

#if __has_include(<ion_ads/ion_ads-Swift.h>)
#import <ion_ads/ion_ads-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ion_ads-Swift.h"

#endif

@implementation IonAppodealFlutterPlugin
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    [SwiftIonAppodealFlutterPlugin registerWithRegistrar:registrar];
}
@end
