import Flutter
import Foundation
import Appodeal

internal final class AppodealRewarded {
    
    internal let adChannel: FlutterMethodChannel
    internal let adListener: Listener
    
    init(registrar: FlutterPluginRegistrar) {
        adChannel = FlutterMethodChannel(name: "appodeal_flutter/rewarded", binaryMessenger: registrar.messenger())
        adListener = Listener(adChannel: adChannel)
    }
    
    internal final class Listener: NSObject, AppodealRewardedVideoDelegate {
        
        private let adChannel: FlutterMethodChannel
        
        fileprivate init(adChannel: FlutterMethodChannel) {
            self.adChannel = adChannel
        }
        
        func rewardedVideoDidLoadAdIsPrecache(_ precache: Bool) {
            adChannel.invokeMethod("onRewardedVideoLoaded", arguments: ["isPrecache": precache])
        }
        
        func rewardedVideoDidFailToLoadAd() {
            adChannel.invokeMethod("onRewardedVideoFailedToLoad", arguments: nil)
        }
        
        func rewardedVideoDidFailToPresentWithError(_ error: Error) {
            adChannel.invokeMethod("onRewardedVideoShowFailed", arguments: nil)
        }
        
        func rewardedVideoDidPresent() {
            adChannel.invokeMethod("onRewardedVideoShown", arguments: nil)
        }
        
        func rewardedVideoWillDismissAndWasFullyWatched(_ wasFullyWatched: Bool) {
            adChannel.invokeMethod("onRewardedVideoClosed", arguments: ["isFinished": wasFullyWatched])
        }
        
        func rewardedVideoDidFinish(_ rewardAmount: Float, name rewardName: String?) {
            adChannel.invokeMethod("onRewardedVideoFinished",
                                   arguments: ["amount": rewardAmount, "reward": rewardName ?? "empty"])
        }
        
        func rewardedVideoDidClick() {
            adChannel.invokeMethod("onRewardedVideoClicked", arguments: nil)
        }
        
        func rewardedVideoDidExpired() {
            adChannel.invokeMethod("onRewardedVideoExpired", arguments: nil)
        }
    }
}
