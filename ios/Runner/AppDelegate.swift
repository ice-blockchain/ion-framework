import UIKit
import Flutter
import AVKit
import AVFoundation
import BanubaAudioBrowserSDK
import BanubaPhotoEditorSDK
import AppsFlyerLib
import app_links

// Audio Focus Handler implementation
class AudioFocusHandler: NSObject {
    private let channel: FlutterMethodChannel
    private var hasFocus = false
    
    init(flutterEngine: FlutterEngine) {
        self.channel = FlutterMethodChannel(name: "audio_focus_channel", binaryMessenger: flutterEngine.binaryMessenger)
        super.init()
        
        setupAudioSession()
        setupMethodChannel()
        
        // Register for audio interruption notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "initAudioFocus":
                self.setupAudioSession()
                result(true)
                
            case "requestAudioFocus":
                do {
                    // When requesting focus, use playback category without mixWithOthers
                    // This will pause any external audio
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    self.hasFocus = true
                    self.channel.invokeMethod("onAudioFocusChange", arguments: true)
                    result(true)
                } catch {
                    print("Failed to request audio focus: \(error)")
                    result(false)
                }
                
            case "abandonAudioFocus":
                do {
                    // When abandoning focus, set back to mixWithOthers
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                    try AVAudioSession.sharedInstance().setActive(true)
                    self.hasFocus = false
                    self.channel.invokeMethod("onAudioFocusChange", arguments: false)
                    result(true)
                } catch {
                    print("Failed to abandon audio focus: \(error)")
                    result(false)
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    @objc private func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Interruption began, another app started playing audio
            hasFocus = false
            channel.invokeMethod("onAudioFocusChange", arguments: false)
            
        case .ended:
            // Interruption ended
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Should resume playback
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        hasFocus = true
                        channel.invokeMethod("onAudioFocusChange", arguments: true)
                    } catch {
                        print("Failed to resume audio session: \(error)")
                    }
                }
            }
            
        @unknown default:
            break
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    // Photo Editor Methods
    static let methodInitPhotoEditor = "initPhotoEditor"
    static let methodStartPhotoEditor = "startPhotoEditor"
    static let argExportedPhotoFile = "argExportedPhotoFilePath"
    
    // Video Editor Methods
    static let methodInitVideoEditor = "initVideoEditor"
    static let methodStartVideoEditorTrimmer = "startVideoEditorTrimmer"
    static let argExportedVideoFile = "argExportedVideoFilePath"
    static let argExportedVideoCoverPreviewPath = "argExportedVideoCoverPreviewPath"
    
    static let errEditorNotInitialized = "ERR_SDK_NOT_INITIALIZED"
    
    private let configEnableCustomAudioBrowser = false
    
    lazy var audioBrowserFlutterEngine = FlutterEngine(name: "audioBrowserEngine")
    
    private var audioFocusHandler: AudioFocusHandler?
    
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        var photoEditor: PhotoEditorModule?
        let videoEditor = VideoEditorModule()
        
        if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }

        if let controller = window?.rootViewController as? FlutterViewController,
           let binaryMessenger = controller as? FlutterBinaryMessenger {
            
            let flutterEngine = controller.engine
            audioFocusHandler = AudioFocusHandler(flutterEngine: flutterEngine)
            
            let channel = FlutterMethodChannel(
                name: "banubaSdkChannel",
                binaryMessenger: binaryMessenger
            )

            channel.setMethodCallHandler { methodCall, result in
                let call = methodCall.method
                switch call {
                case AppDelegate.methodInitPhotoEditor:
                    guard let token = methodCall.arguments as? String else {
                        print("Missing token")
                        return
                    }
                    photoEditor = PhotoEditorModule(
                        token: token,
                        flutterResult: result
                    )

                case AppDelegate.methodStartPhotoEditor:
                    guard let arguments = methodCall.arguments as? [String: Any],
                          let imagePath = arguments["imagePath"] as? String else {
                        print("Missing or invalid arguments")
                        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing imagePath", details: nil))
                        return
                    }

                    if let photoEditor = photoEditor {
                        photoEditor.presentPhotoEditor(
                            fromViewController: controller,
                            imagePath: imagePath,
                            flutterResult: result
                        )
                    } else {
                        print("The Photo Editor is not initialized")
                        result(FlutterError(code: AppDelegate.errEditorNotInitialized, message: "", details: nil))
                    }
                case AppDelegate.methodInitVideoEditor:
                                    let token = methodCall.arguments as? String
                                    videoEditor.initVideoEditor(
                                        token: token,
                                        flutterResult: result
                                    )
                case AppDelegate.methodStartVideoEditorTrimmer:
                    let arguments = methodCall.arguments as? [String: Any]
                                    let trimmerVideoFilePath = arguments?["videoFilePath"] as? String
                    let maxVideoDurationMs = arguments?["maxVideoDurationMs"] as? Int ?? 60000
                    let coverSelectionEnabled = arguments?["coverSelectionEnabled"] as? Bool ?? true
                    let maxVideoDurationSec = maxVideoDurationMs / 1000
                                    if let videoFilePath = trimmerVideoFilePath {
                                        videoEditor.openVideoEditorTrimmer(
                                            fromViewController: controller,
                                            videoURL: URL(fileURLWithPath: videoFilePath),
                                            maxVideoDuration: maxVideoDurationSec,
                                            coverSelectionEnabled: coverSelectionEnabled,
                                            flutterResult: result
                                        )
                                    } else {
                                        print("Cannot start video editor in trimmer mode: missing or invalid video!")
                                        result(FlutterError(code: "ERR_START_TRIMMER_MISSING_VIDEO", message: "", details: nil))
                                    }
                default:
                    print("Flutter method is not implemented on platform.")
                    result(FlutterMethodNotImplemented)
                }
            }

        }
        GeneratedPluginRegistrant.register(with: self)

        // Register VideoCompressionPlugin
        if let controller = window?.rootViewController as? FlutterViewController {
            let registrar = controller.engine.registrar(forPlugin: "VideoCompressionPlugin")
            VideoCompressionPlugin.register(with: registrar!)
        }

        audioBrowserFlutterEngine.run(withEntrypoint: "audioBrowser")
        GeneratedPluginRegistrant.register(with: audioBrowserFlutterEngine)

        // Retrieve the link from parameters
        if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
        // We have a link, propagate it to your Flutter app or not
        AppLinks.shared.handleLink(url: url)
        return true // Returning true will stop the propagation to other packages
    }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - AppsFlyer Deep Linking
    
    // Universal Links handler
    override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return true
    }

    // URI Scheme handler (fallback)
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }

    
    // Custom View Factory is used to provide you custom UI/UX experience in Video Editor SDK
        // i.e. custom audio browser
        func provideCustomViewFactory() -> FlutterCustomViewFactory? {
            let factory: FlutterCustomViewFactory?
            
            if configEnableCustomAudioBrowser {
                factory = FlutterCustomViewFactory()
            } else {
                // Set your Mubert Api key here
                let mubertApiLicense = ""
                let mubertApiKey = ""
                AudioBrowserConfig.shared.musicSource = .allSources
                BanubaAudioBrowser.setMubertKeys(
                    license: mubertApiLicense,
                    token: mubertApiKey
                )
                factory = nil
            }
            
            return factory
        }
}