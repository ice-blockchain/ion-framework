//
//  VEExternalViewFactory.swift
//  Runner
//
//  Created by Andrei Sak on 7.10.22.
//

import BanubaVideoEditorSDK
import BanubaUtilities
import Flutter

class FlutterCustomViewFactory: ExternalViewControllerFactory {
    // Set nil to use BanubaAudioBrowser
    var musicEditorFactory: MusicEditorExternalViewControllerFactory? = CustomAudioBrowserViewControllerFactory()
    
    var countdownTimerViewFactory: CountdownTimerViewFactory?
    
    var exposureViewFactory: AnimatableViewFactory?
}

class CustomAudioBrowserViewControllerFactory: MusicEditorExternalViewControllerFactory {
    
    // Audio Browser selection view controller
    func makeTrackSelectionViewController(selectedAudioItem: AudioItem?, isAudioPartSelectionEnabled: Bool) -> TrackSelectionViewController? {
        let flutterEngine = (UIApplication.shared.delegate as! AppDelegate).audioBrowserFlutterEngine
        
        // Only single instance of the FlutterEngine can be attached to FlutterViewController at a time.
        // Set FlutterEngine.viewController to nil before attaching it to another FlutterViewController.
        flutterEngine.viewController = nil
        
        let flutterTrackSelectionViewController = FlutterTrackSelectionViewController(
            engine: flutterEngine,
            nibName: nil,
            bundle: nil
        )
        
        flutterTrackSelectionViewController.listenFlutterCalls()
        
        return flutterTrackSelectionViewController
    }
    
    // Effects selection view controller. Used at Music editor screen
    func makeEffectSelectionViewController(selectedAudioItem: AudioItem?) -> EffectSelectionViewController? {
        return nil
    }
    
    // Returns recorder countdown view for voice recorder screen
    func makeRecorderCountdownAnimatableView() -> MusicEditorCountdownAnimatableView? {
        return nil
    }
}

private class FlutterTrackSelectionViewController: FlutterViewController, TrackSelectionViewController {
    
    let channelAudioBrowser = "audioBrowserChannel"
    let methodApplyAudioTrack = "applyAudioTrack"
    let methodDiscardAudioTrack = "discardAudioTrack"
    let methodClose = "close"
    
    // MARK: - TrackSelectionViewController
    var trackSelectionDelegate: TrackSelectionViewControllerDelegate?
    
    private var channel: FlutterMethodChannel?
    
    func listenFlutterCalls() {
        channel = FlutterMethodChannel(
            name: channelAudioBrowser,
            binaryMessenger: binaryMessenger
        )
        channel?.setMethodCallHandler { [weak self] methodCall, resultHandler in
            guard let self = self else {
                resultHandler(FlutterMethodNotImplemented)
                return
            }
            
            switch methodCall.method {
            case self.methodApplyAudioTrack:
                self.handleApplyAudioTrack(args: methodCall.arguments, resultHandler: resultHandler)
                
            case self.methodDiscardAudioTrack:
              self.trackSelectionDelegate?.trackSelectionViewControllerDiscardCurrentTrack(
                viewController: self
              )
              self.trackSelectionDelegate?.trackSelectionViewControllerDidCancel(
                  viewController: self
              )
              resultHandler(nil)
                
            case self.methodClose:
                self.trackSelectionDelegate?.trackSelectionViewControllerDidCancel(viewController: self)
                resultHandler(nil)
                
            default: resultHandler(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func handleApplyAudioTrack(args: Any?, resultHandler: (Any?) -> Void) {
        struct Track: Codable {
            let url: URL
            let id: UUID
            let title: String
        }
        guard let string = args as? String,
              let data = string.data(using: .utf8),
              let track = try? JSONDecoder().decode(Track.self, from: data) else {
            resultHandler(FlutterMethodNotImplemented)
            return
        }
        trackSelectionDelegate?.trackSelectionViewController(
            viewController: self,
            didSelectFile: track.url,
            remoteURL: nil,
            coverURL: nil,
            timeRange: nil,
            isEditable: true,
            title: track.title,
            additionalTitle: nil,
            uuid: track.id
        )
        resultHandler(nil)
    }
}
