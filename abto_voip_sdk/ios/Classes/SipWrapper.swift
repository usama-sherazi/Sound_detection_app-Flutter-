import UserNotifications
import UserNotificationsUI
import AVFoundation
import AbtoSipClientWrapper
import Flutter

class SipWrapper: NSObject, AbtoPhoneInterfaceObserver {
    
    private static var instance: SipWrapper?
    
    internal class func shared() -> SipWrapper {
        guard let currentInstance = instance else {
            instance = SipWrapper()
            return instance!
        }
        return currentInstance
    }
    
    private let DEFAULT_TIMEOUT = 300
    private let REGISTER_TIMEOUT: Int32 = 15000
    private let HANGUP_TIMEOUT: Int32 = 3000
    
    private let CHANNEL_NAME = "com.voip.sdk.channel"
    
    // Events
    private let EVENT_INIT_LICENSE = "initLicense"
    private let EVENT_REGISTER = "register"
    private let EVENT_UNREGISTER = "unregister"
    
    private let EVENT_START_AUDIO_CALL = "startAudioCall"
    private let EVENT_START_VIDEO_CALL = "startVideoCall"
    private let EVENT_END_CALL = "endCall"
    private let EVENT_PICK_UP_CALL = "pickUpCall"
    private let EVENT_HANG_UP_CALL = "hangUpCall"
    private let EVENT_REJECT_CALL = "rejectCall"
    
    private let EVENT_ENABLE_SPEAKER = "enableSpeaker"
    private let EVENT_HOLD = "hold"
    private let EVENT_MUTE = "mute"
    private let EVENT_START_RECORD = "startRecord"
    private let EVENT_STOP_RECORD = "stopRecord"
    private let EVENT_TRANSFER = "transfer"

    private let EVENT_SEND_TEXT = "sendText"

    private let EVENT_LIB_VERSION = "libVersion"
    private let EVENT_GET_CONFIGS = "getConfigs"
    private let EVENT_SET_CONFIGS = "setConfigs"
    
    private let EVENT_SET_LOG_LEVEL = "setLogLevel"
    private let EVENT_SET_SENDING_RTP_VIDEO  = "setSendingRtpVideo"
    
    private let EVENT_SEND_DTMF = "sendDtmf"
    private let EVENT_MUTE_LOCAL_VIDEO = "muteLocalVideo"
    
    // Results
    private let RESULT_REGISTERED = "registered"
    private let RESULT_UNREGISTERED = "unregistered"
    private let RESULT_REG_FAILED = "registration_failed"
    
    private let RESULT_CALL_CONNECTED = "call_connected"
    private let RESULT_CALL_DISCONNECTED = "call_disconnected"
    
    private let RESULT_ON_HOLD_STATE = "on_hold_state"
    private let RESULT_ACTIVE = "active"
    private let RESULT_LOCAL_HOLD = "local_hold"
    private let RESULT_REMOTE_HOLD = "remote_hold"
    
    private let RESULT_INCOMING_CALL = "incoming_call"

    private let RESULT_MSG_RECEIVED = "message_received"
    private let RESULT_MSG_STATUS = "message_status"

    private let RESULT_DTMF_RECEIVED = "dtmf_received"

    var channel: FlutterMethodChannel?
    var phone: AbtoPhoneInterface?
    
    private var callId = 0
    private var isCallConnected = false
    private var isIncomingCall = false
    private var isVideoCall = false
    
    func setupOutView(imageView: UIImageView) {
        print("debug_v: setupOutView \(self.callId)")
        phone?.setCall(self.callId, localView: imageView)
    }
    
    func setupIncView(imageView: UIImageView) {
        print("debug_v: setupIncView \(self.callId)")
        phone?.setCall(self.callId, remoteView: imageView)
    }
    
    func setup(binaryMessenger: FlutterBinaryMessenger) {
        
        if #available(iOS 10.0, *) {
            RemoteNotificationManager.shared.register()
        }
    
        channel = FlutterMethodChannel(name: CHANNEL_NAME, binaryMessenger: binaryMessenger)
        
        channel?.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            print("SipWrapper IOS: call.method: " + call.method + " \(String(describing: call.arguments))")
            self.receiveEvent(method: call.method, arguments: call.arguments, result: result)
        }
        initAbtoPhone()
        
        print("debug_v: setup")
        //print("CreateViewDebug: inView1: \(inView == nil) outView: \(outView == nil)")
    }
    
    private func initAbtoPhone() {
        phone = AbtoPhoneInterface()

        phone?.config().localPort = 0
        
        phone?.config().setCodecPriority(PhoneAudioVideoCodec.pcmu, priority: 128)
        phone?.config().setCodecPriority(PhoneAudioVideoCodec.pcma, priority: 127)
        phone?.config().setCodecPriority(PhoneAudioVideoCodec.g729ab, priority: 126)
        phone?.config().setCodecPriority(PhoneAudioVideoCodec.gsm, priority: 125)
        phone?.config().setCodecPriority(PhoneAudioVideoCodec.silk, priority: 124)
        phone?.config().setCodecPriority(PhoneAudioVideoCodec.h264Svc, priority: 123)
        phone?.config().setCodecPriority(PhoneAudioVideoCodec.H263, priority: 122)
        phone?.config().setCodecPriority(PhoneAudioVideoCodec.vp8, priority: 121)
        phone?.config().setCodecPriority(PhoneAudioVideoCodec.G723, priority: 120)
        
        phone?.config().signalingTransport = PhoneSignalingTransport.udp
        phone?.config().hangupTimeout = HANGUP_TIMEOUT
        phone?.config().registerTimeout = REGISTER_TIMEOUT
        
        AbtoPhoneConfig.logLevel = 5
    }
    
    private func receiveEvent(method: String!, arguments: Any?, result: @escaping FlutterResult) {
        switch method {
        case EVENT_LIB_VERSION:
            print("SipWrapper IOS: EVENT_LIB_VERSION")
            result(AbtoPhoneInterface.libVersion)
            break
        case EVENT_GET_CONFIGS:
            print("SipWrapper IOS: EVENT_GET_CONFIGS")
            result(buildConfigsMap())
            break
        case EVENT_SET_CONFIGS:
            print("SipWrapper IOS: EVENT_SET_CONFIGS")
            let map = arguments as! Dictionary<String, Any>
            applyConfigs(map: map)
            break
        case EVENT_INIT_LICENSE:
            print("SipWrapper IOS: EVENT_INIT_LICENSE")
            let array = arguments as! NSArray
            AbtoPhoneConfig.licenseUserId = array[0] as? String
            AbtoPhoneConfig.licenseKey = array[1] as? String
            phone!.initialize(self)
            break
        case EVENT_REGISTER:
            print("SipWrapper IOS: REGISTER")
            let array = arguments as! NSArray
            phone?.config().regDomain = array[0] as? String
            phone?.config().proxy = array[1] as? String
            phone?.config().regUser = array[2] as? String
            phone?.config().regPassword = array[3] as? String
            phone?.config().regAuthId = array[4] as? String
            phone?.config().displayName = array[5] as? String
            phone?.config().regExpirationTime = Int32(array[6] as? String ?? "0") ?? 0
            
            phone?.finalizeConfiguration()
            break
        case EVENT_UNREGISTER:
            phone?.setLocalView(nil)
            phone?.setRemoteView(nil)
            phone?.unregister()
            break
        case EVENT_START_AUDIO_CALL:
            let number: String = arguments as! String
            self.isIncomingCall = false
            self.isVideoCall = false
            phone?.startCall(number, withVideo: false)
            break
        case EVENT_START_VIDEO_CALL:
            let number: String = arguments as! String
            self.isIncomingCall = false
            self.isVideoCall = true
            phone?.startCall(number, withVideo: true)
            break
        case EVENT_END_CALL:
            if ( isIncomingCall && !isCallConnected ) {
                phone?.hangUpCall(callId, status:  486)
            } else {
                phone?.hangUpCall(callId, status: 0)
            }
            break
        case EVENT_HANG_UP_CALL:
            let status = arguments as! Int32
            phone?.hangUpCall(callId, status:  status)
            break
        case EVENT_REJECT_CALL:
            phone?.hangUpCall(callId, status: 0)
            break
        case EVENT_PICK_UP_CALL:
            let isVideo = arguments as! Bool
            print("SipWrapper IOS: answerCall: isVideo: \(isVideo)")
            phone?.answerCall(callId, status: 200, withVideo: isVideo)
            break
        case EVENT_ENABLE_SPEAKER:
            let enableSpeaker = arguments as! Bool
            print("SipWrapper IOS: enableSpeaker: \(enableSpeaker)")
            phone?.setSpeakerphoneOn(enableSpeaker)
            break
        case EVENT_HOLD:
            print("SipWrapper IOS: hold")
            phone?.holdRetrieveCall(callId)
            break
        case EVENT_MUTE:
            let mute = arguments as! Bool
            print("SipWrapper IOS: mute: \(mute)")
            phone?.muteMicrophone(callId, on: mute)
            break
        case EVENT_START_RECORD:
            print("SipWrapper IOS: startRecord")
            let locale = Locale(identifier: "en_US_POSIX")
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
            formatter.locale = locale
            
            let filename = String(format: "%@/rec_%@_%@.wav",
                                  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?.path ?? "",
                                  String(callId), formatter.string(from: Date()))
            
            phone?.startRecording(for: callId, filePath: filename)
            break
        case EVENT_STOP_RECORD:
            print("SipWrapper IOS: stopRecord")
            phone?.stopRecording()
            break
        case EVENT_TRANSFER:
            print("SipWrapper IOS: transfer")
            let number: String = arguments as! String
            phone?.transferCall(callId, toContact: number)
            break
        case EVENT_SEND_TEXT:
            print("SipWrapper IOS: sendTextMessage")
            let array = arguments as! NSArray
            let number = array[0] as! String
            let message = array[1] as! String
            phone?.sendTextMessage(number, withBody: message)
            break
        case EVENT_SET_LOG_LEVEL:
            print("SipWrapper IOS: setLogLevel")
            let array = arguments as! NSArray
            AbtoPhoneConfig.logLevel = array[0] as! Int32
            AbtoPhoneConfig.logToFile = (array[1] as! Int32) == 1
            break
        case EVENT_SET_SENDING_RTP_VIDEO:
            print("SipWrapper IOS: setSendingRtpVideo")
            let enable = arguments as! Bool
            phone?.setSendingRtpVideo(callId, on: enable)
            break
        case EVENT_SEND_DTMF:
            print("SipWrapper IOS: send dtmf")
            let dtmf: String = arguments as! String
            guard dtmf.count > 0, let tone = dtmf[dtmf.startIndex].asciiValue else {
                break
            }
            phone?.sendTone(callId, tone: unichar(tone))
            break
        case EVENT_MUTE_LOCAL_VIDEO:
            let mute = arguments as! Bool
            print("SipWrapper IOS: mute local video: \(mute)")
            phone?.muteVideo(callId, on: mute)
            break
        case .none, .some(_): break
        }
    }
    
    func onRegistered(_ accId: Int) {
        print("SipWrapper IOS: onRegistered")
        channel?.invokeMethod(RESULT_REGISTERED, arguments: nil)
    }
    
    func onRegistrationFailed(_ accId: Int, statusCode: Int32, statusText: String) {
        print("SipWrapper IOS: onRegistrationFailed")
        channel?.invokeMethod(RESULT_REG_FAILED, arguments: nil)
    }
    
    func onUnRegistered(_ accId: Int) {
        print("SipWrapper IOS: onUnRegistered")
        channel?.invokeMethod(RESULT_UNREGISTERED, arguments: nil)
    }
    
    func onRemoteAlerting(_ accId: Int, statusCode: Int32) {
        
    }
    
    func onIncomingCall(_ callId: Int, remoteContact: String) {
        guard callId != kInvalidCallId else {
            return
        }
        
        self.callId = callId
        self.isIncomingCall = true
        self.isVideoCall = phone?.isVideoCall(callId) ?? false
        let list = [remoteContact, String(isVideoCall)]
        print("SipWrapper IOS: onIncomingCall " + remoteContact)
        channel?.invokeMethod(RESULT_INCOMING_CALL, arguments: list)
        
        if #available(iOS 10.0, *) {
            let app = UIApplication.shared
            let state = app.applicationState
            if ( state == UIApplication.State.background || state == UIApplication.State.inactive ) {
                let remotePartyNumber = AbtoPhoneInterface.sipUriUsername(remoteContact)
                RemoteNotificationManager.shared.showNotification(title: "Incoming call", msg: remotePartyNumber)
            }
        }
    }
    
    func onCallConnected(_ callId: Int, remoteContact: String) {
        print("SipWrapper IOS: onCallConnected \(callId), \(remoteContact)")
        self.callId = callId
        self.isCallConnected = true
        channel?.invokeMethod(RESULT_CALL_CONNECTED, arguments: remoteContact)
    }
    
    func onCallDisconnected(_ callId: Int, remoteContact: String, statusCode: Int, message: String) {
        print("SipWrapper IOS: onCallDisconnected \(callId), \(remoteContact), \(statusCode), \(message)")
        if ( self.callId != callId ) { return }
        self.callId = 0
        self.isCallConnected = false
        channel?.invokeMethod(RESULT_CALL_DISCONNECTED, arguments: nil)
    }
    
    func onCallAlerting(_ callId: Int, statusCode: Int32) {
        
    }
    
    func onCallHeld(_ callId: Int, state: Bool) {
        channel?.invokeMethod(RESULT_ON_HOLD_STATE, arguments: state ? RESULT_LOCAL_HOLD : RESULT_ACTIVE)
    }
    
    func onToneReceived(_ callId: Int, tone: Int) {
        let dtmf = String(UnicodeScalar(UInt8(tone)))
        channel?.invokeMethod(RESULT_DTMF_RECEIVED, arguments: dtmf)
    }
    
    func onTextMessageReceived(_ from: String, to: String, body: String) {
        let list = [from, to, body]
        print("SipWrapper IOS: onTextMessageReceived " + body)
        channel?.invokeMethod(RESULT_MSG_RECEIVED, arguments: list)
    }
    
    func onTextMessageStatus(_ address: String, reason: String, status: Bool) {
        let list = [address, reason, String(status)]
        print("SipWrapper IOS: onTextMessageStatus " + address)
        channel?.invokeMethod(RESULT_MSG_STATUS, arguments: list)
    }
    
    func onPresenceChanged(_ uri: String, status: PhoneBuddyStatus, note: String) {
        
    }
    
    func onTransferStatus(_ callId: Int, statusCode: Int32, message: String) {
        if ( statusCode == 200 ) {
            if ( isIncomingCall && !isCallConnected ) {
                phone?.hangUpCall(callId, status:  486)
            } else {
                phone?.hangUpCall(callId, status: 0)
            }
        }
    }
    
    private func buildConfigsMap() -> Dictionary<String, Any> {
        var map = Dictionary<String, Any>()
        let configs = phone?.config()
        print("SipWrapper IOS: phone == nil \(phone == nil)")
        print("SipWrapper IOS: phone?.config() == nil \(configs == nil)")
        guard let cfg = phone?.config() else {
            print("SipWrapper IOS: return empty map")
            return map
            
        }
        map["isSTUNEnabled"] = cfg.enableStun
        map["STUNServer"] = cfg.stun ?? ""
        map["SipPort"] = cfg.localPort
        
        let signalingTransportKey: Int
        switch (cfg.signalingTransport) {
            case .udp: signalingTransportKey = 1
            case .tcp: signalingTransportKey = 2
            case .tls: signalingTransportKey = 3
            default: signalingTransportKey = 1
        }
        map["SignalingTransport"] = signalingTransportKey
        map["ICEEnabled"] = cfg.enableIce
        map["KeepAliveInterval"] = cfg.keepAliveInterval
        map["InviteTimeout"] = cfg.inviteTimeout
        map["HangupTimeout"] = cfg.hangupTimeout
        map["RegisterTimeout"] = cfg.registerTimeout
        map["isUseSRTP"] = cfg.enableSrtp
        map["isEnabledAutoSendRtpVideo"] = cfg.enableAutoSendRtpVideo
        map["audioCodecs"] = CodecsUtils.codecsString(cfg: cfg, isVideo: false)
        map["videoCodecs"] = CodecsUtils.codecsString(cfg: cfg, isVideo: true)
        
        print("SipWrapper IOS: map size \(map.count)")
        return map
    }
    
    private func applyConfigs(map: Dictionary<String, Any>) {
        guard let configs = phone?.config() else { return }
        configs.enableStun = map["isSTUNEnabled"] as! Bool
        configs.stun = map["STUNServer"] as? String ?? ""
        configs.localPort = map["SipPort"] as! Int32
        
        let signalingTransport: PhoneSignalingTransport
        switch (map["SignalingTransport"] as! Int) {
        case 1: signalingTransport = PhoneSignalingTransport.udp
        case 2: signalingTransport = PhoneSignalingTransport.tcp
        case 3: signalingTransport = PhoneSignalingTransport.tls
        default: signalingTransport = PhoneSignalingTransport.udp
        }
        configs.signalingTransport = signalingTransport
        
        configs.enableIce = map["ICEEnabled"] as! Bool
        configs.keepAliveInterval = map["KeepAliveInterval"] as! Int32
        configs.inviteTimeout = map["InviteTimeout"] as! Int32
        configs.hangupTimeout = map["HangupTimeout"] as! Int32
        configs.registerTimeout = map["RegisterTimeout"] as! Int32
        configs.enableSrtp = map["isUseSRTP"] as! Bool
        configs.enableAutoSendRtpVideo = map["isEnabledAutoSendRtpVideo"] as! Bool
        CodecsUtils.applyCodecs(cfg: configs, data: map["audioCodecs"] as! String, isVideo: false)
        CodecsUtils.applyCodecs(cfg: configs, data: map["videoCodecs"] as! String, isVideo: true)
        
        phone?.finalizeConfiguration()
    }
}

class RemoteNotificationManager: NSObject {
    static let shared = RemoteNotificationManager()
    
    @available(iOS 10.0, *)
    func register() {
        //UNUserNotificationCenter.current().delegate = self
        //UIApplication.shared.registerForRemoteNotifications()

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current()
            .requestAuthorization(options: authOptions) { [weak self] granted, error in
                print("Permission granted: \(granted)")
                guard granted else { return }
                self?.getNotificationSettings()
        }
    }
    
    @available(iOS 10.0, *)
    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")

            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func handle(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) { }
    
    @available(iOS 10.0, *)
    func showNotification(title: String, msg: String) {
        print("DEBUG_PUSH: showNotification: \(title): \(msg)")
        
        let content = UNMutableNotificationContent()
        
        content.title = title
        content.body = msg
        content.sound = UNNotificationSound.default
        content.threadIdentifier = "ABTO_VOIP"
        if #available(iOS 12.0, *) {
            content.summaryArgument = "ABTO VOIP notifications"
            content.summaryArgumentCount = 2
        }
        
        let date = Date(timeIntervalSinceNow: 1)
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = "alert"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
    }
    
    @available(iOS 10.0, *)
    func cancelNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
}

/*extension AppDelegate {
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        SipWrapper.sipWrapper?.phone?.keepAwake(true)
    }
    
    override func applicationWillEnterForeground(_ application: UIApplication) {
        SipWrapper.sipWrapper?.phone?.keepAwake(false)
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            RemoteNotificationManager.shared.cancelNotifications()
        }
    }
    
    override func applicationWillTerminate(_ application: UIApplication) {
        SipWrapper.sipWrapper?.phone?.deinitialize()
       // AVAudioSession.sharedInstance().setActive(false, options: AVAudioSession.SetActiveOptions.Type.self)
    }
}*/
