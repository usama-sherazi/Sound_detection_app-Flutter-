package org.abtollc.voip.abto_voip_sdk;

import android.content.Context;
import android.content.Intent;
import android.os.Environment;
import android.os.RemoteException;
import android.util.Log;
import android.view.SurfaceView;
import android.widget.Toast;

import androidx.annotation.NonNull;

import org.abtollc.sdk.AbtoApplication;
import org.abtollc.sdk.AbtoPhone;
import org.abtollc.sdk.AbtoPhoneCfg;
import org.abtollc.sdk.OnCallTransferListener;
import org.abtollc.sdk.OnInitializeListener;
import org.abtollc.sdk.OnRegistrationListener;
import org.abtollc.utils.codec.Codec;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Random;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class SipWrapper implements MethodChannel.MethodCallHandler {
    private static SipWrapper instance;

    public static SipWrapper getInstance() {
        if (instance == null) instance = new SipWrapper();
        return instance;
    }


    private static final int DEFAULT_TIMEOUT = 300;
    private static final int REGISTER_TIMEOUT = 15000;
    private static final int HANGUP_TIMEOUT = 3000;

    private static final String CHANNEL_NAME = "com.voip.sdk.channel";

    // Events
    private static final String EVENT_INIT_LICENSE = "initLicense";
    private static final String EVENT_REGISTER = "register";
    private static final String EVENT_UNREGISTER = "unregister";

    private static final String EVENT_START_AUDIO_CALL = "startAudioCall";
    private static final String EVENT_START_VIDEO_CALL = "startVideoCall";
    private static final String EVENT_END_CALL = "endCall";
    private static final String EVENT_PICK_UP_CALL = "pickUpCall";
    private static final String EVENT_HANG_UP_CALL = "hangUpCall";
    private static final String EVENT_REJECT_CALL = "rejectCall";

    private static final String EVENT_ENABLE_SPEAKER = "enableSpeaker";
    private static final String EVENT_HOLD = "hold";
    private static final String EVENT_MUTE = "mute";
    private static final String EVENT_START_RECORD = "startRecord";
    private static final String EVENT_STOP_RECORD = "stopRecord";
    private static final String EVENT_TRANSFER = "transfer";

    private static final String EVENT_SEND_TEXT = "sendText";

    private static final String EVENT_LIB_VERSION = "libVersion";
    private static final String EVENT_GET_CONFIGS = "getConfigs";
    private static final String EVENT_SET_CONFIGS = "setConfigs";
    private static final String EVENT_SET_LOG_LEVEL = "setLogLevel";
    private static final String EVENT_SET_SENDING_RTP_VIDEO = "setSendingRtpVideo";

    private static final String EVENT_SEND_DTMF = "sendDtmf";
    private static final String EVENT_MUTE_LOCAL_VIDEO = "muteLocalVideo";

    // Results
    private static final String RESULT_REGISTERED = "registered";
    private static final String RESULT_UNREGISTERED = "unregistered";
    private static final String RESULT_REG_FAILED = "registration_failed";

    private static final String RESULT_CALL_CONNECTED = "call_connected";
    private static final String RESULT_CALL_DISCONNECTED = "call_disconnected";

    private static final String RESULT_ON_HOLD_STATE = "on_hold_state";
    private static final String RESULT_ACTIVE = "active";
    private static final String RESULT_LOCAL_HOLD = "local_hold";
    private static final String RESULT_REMOTE_HOLD = "remote_hold";

    private static final String RESULT_INCOMING_CALL = "incoming_call";

    private static final String RESULT_MSG_RECEIVED = "message_received";
    private static final String RESULT_MSG_STATUS = "message_status";

    private static final String RESULT_DTMF_RECEIVED = "dtmf_received";

    private MethodChannel channel;
    private AbtoPhone phone;

    private boolean isCallConnected = false;
    private boolean isIncomingCall = false;
    private int callId = 0;
    private String recordFilePath;
    private Context context;
    private SurfaceView outVideo;
    private SurfaceView incVideo;

    public void setup(FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        phone = ((AbtoApplication) flutterPluginBinding.getApplicationContext()).getAbtoPhone();
        initAbtoPhone();
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler(this);
    }

    public void clear() {
        channel = null;
        context = null;
        phone = null;
    }

    private void initAbtoPhone() {
        AbtoPhoneCfg cfg = phone.getConfig();

        int sipPortValue = new Random().nextInt(64000) + 1000;
        cfg.setSipPort(sipPortValue);

        for (Codec c : Codec.values()) {
            switch (c) {
                case PCMU:
                    cfg.setCodecPriority(c, (short) 250);
                    break;
                case PCMA:
                    cfg.setCodecPriority(c, (short) 249);
                    break;
                case G729:
                    cfg.setCodecPriority(c, (short) 248);
                    break;
                case GSM:
                    cfg.setCodecPriority(c, (short) 247);
                    break;
                case H264:
                    cfg.setCodecPriority(c, (short) 220);
                    break;
                case VP8:
                    cfg.setCodecPriority(c, (short) 210);
                    break;
                case G723:
                    cfg.setCodecPriority(c, (short) 200);
                    break;
                default:
                    cfg.setCodecPriority(c, (short) 0);
                    break;
            }
        }

        cfg.setSignallingTransport(AbtoPhoneCfg.SignalingTransportType.UDP);

        AbtoPhoneCfg.setLogLevel(7, true);

        cfg.setHangupTimeout(HANGUP_TIMEOUT);
        cfg.setRegisterTimeout(REGISTER_TIMEOUT);

        cfg.setSTUNServer("stun.l.google.com:19302");

        if (!PermissionUtil.checkPermissions(context, PermissionUtil.permissions)) {
            context.startActivity(new Intent(context, GetPermissionsActivity.class)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        }

        phone.setInitializeListener((state, s) -> {
            Log.d("DEBUG_SIP_WRAPPER", "setInitializeListener: " + state + ", " + s);
            if (state == OnInitializeListener.InitializeState.SUCCESS) {
                try {
                    phone.register();
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
            }
        });

        phone.setRegistrationStateListener(new OnRegistrationListener() {
            @Override
            public void onRegistered(long p0) {
                Log.d("DEBUG_SIP_WRAPPER", "onRegistered");
                channel.invokeMethod(RESULT_REGISTERED, null);
            }

            @Override
            public void onUnRegistered(long p0) {
                Log.d("DEBUG_SIP_WRAPPER", "onUnRegistered");
                channel.invokeMethod(RESULT_UNREGISTERED, null);
            }

            @Override
            public void onRegistrationFailed(long p0, int p1, String p2) {
                if (p1 == 100) return;
                Log.d("DEBUG_SIP_WRAPPER", "onRegistrationFailed: " + p0 + ", " + p1 + ", " + p2);
                channel.invokeMethod(RESULT_REG_FAILED, null);
            }
        });

        phone.setCallConnectedListener((callId, contact) -> {
      /*Log.d("DEBUG_SIP_WRAPPER", "onCallConnected outVideoLay: " + (outVideoLay != null)
      + ", inVideoLay: " + (inVideoLay != null) + ", callId: " + callId);*/
            isCallConnected = true;
            SipWrapper.this.callId = callId;
            //  phone.setVideoWindows(callId, outVideoLay, inVideoLay);

            //  outVideoLay.setZOrderOnTop(true);
            //  outVideoLay.setZOrderMediaOverlay(true);

            channel.invokeMethod(RESULT_CALL_CONNECTED, contact);
        });

        phone.setCallDisconnectedListener((callId, var2, var3, var4) -> {
            Log.d("DEBUG_SIP_WRAPPER", "onCallDisconnected");
            if (SipWrapper.this.callId != callId) return;
            SipWrapper.this.isCallConnected = false;
            phone.setVideoWindows(callId, (SurfaceView) null, null);
            channel.invokeMethod(RESULT_CALL_DISCONNECTED, null);
        });

        phone.setCallErrorListener((p0, p1, p2) -> {
            Log.d("DEBUG_SIP_WRAPPER", "onCallError");
            isCallConnected = false;
            phone.setVideoWindows(callId, (SurfaceView) null, null);
            channel.invokeMethod(RESULT_CALL_DISCONNECTED, null);
        });

        phone.setOnCallHeldListener((i, holdState) -> {
            String holdStateValue = null;
            switch (holdState) {
                case ACTIVE: {
                    holdStateValue = RESULT_ACTIVE;
                    break;
                }
                case LOCAL_HOLD: {
                    holdStateValue = RESULT_LOCAL_HOLD;
                    break;
                }
                case REMOTE_HOLD: {
                    holdStateValue = RESULT_REMOTE_HOLD;
                    break;
                }
            }
            if (holdStateValue != null) {
                channel.invokeMethod(RESULT_ON_HOLD_STATE, holdStateValue);
            }
        });

        phone.setCallTransferListener(new OnCallTransferListener() {
            @Override
            public void onCallTransferRequest(int i, String s) {
            }

            @Override
            public void onCallTransferState(int i, int statusCode, String s) {
                if (statusCode == 200) {
                    try {
                        phone.hangUp(callId);
                        Log.d("DEBUG_SIP_WRAPPER", "hangUp");
                    } catch (RemoteException e) {
                        e.printStackTrace();
                    }
                }
            }
        });

        phone.setIncomingCallListener((callId, remoteContact, l) -> {
            SipWrapper.this.callId = callId;

            boolean isVideoCall = phone.isVideoCall(callId);

            SipWrapper.this.isIncomingCall = true;

            ArrayList<String> list = new ArrayList<>();
            list.add(remoteContact);
            list.add(String.valueOf(isVideoCall));
            channel.invokeMethod(RESULT_INCOMING_CALL, list);
        });

        phone.setInMessageListener((message, remoteContact, accId) -> {
            String localContact = accId != null ? accId : "";
            ArrayList<String> list = new ArrayList<>();
            list.add(remoteContact);
            list.add(localContact);
            list.add(message);
            channel.invokeMethod(RESULT_MSG_RECEIVED, list);
        });

        phone.setTextMessageStatusListener((message) -> {
            String error = message.getErrorContent();
            ArrayList<String> list = new ArrayList<>();
            list.add(message.getRemoteNumber());
            list.add(error != null ? error : "OK");
            list.add(String.valueOf((int)(message.getStatus() / 100) == 2));
            channel.invokeMethod(RESULT_MSG_STATUS, list);
        });
        
        phone.setToneReceivedListener((callId, tone) -> {
            channel.invokeMethod(RESULT_DTMF_RECEIVED, String.valueOf(tone));
        });
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        String method = call.method;
        Object arguments = call.arguments;

        switch (method) {
            case EVENT_LIB_VERSION: {
                Log.d("DEBUG_SIP_WRAPPER", "libVersion");
                result.success(AbtoApplication.BUILD);
                return;
            }
            case EVENT_GET_CONFIGS: {
                Log.d("DEBUG_SIP_WRAPPER", method);
                result.success(buildConfigsMap());
                return;
            }
            case EVENT_SET_CONFIGS: {
                Log.d("DEBUG_SIP_WRAPPER", method);
                Map<String, Object> map = (Map<String, Object>) arguments;
                applyConfigs(map);
                return;
            }
            case EVENT_INIT_LICENSE: {
                Log.d("DEBUG_SIP_WRAPPER", "initLicense");
                ArrayList<String> array = (ArrayList<String>) arguments;
                AbtoPhoneCfg cfg = phone.getConfig();
                cfg.setLicenseUserId(array.get(0));
                cfg.setLicenseKey(array.get(1));
                break;
            }
            case EVENT_REGISTER: {
                ArrayList<String> array = (ArrayList<String>) arguments;
                AbtoPhoneCfg cfg = phone.getConfig();
                String domain = array.get(0);
                String proxy = array.get(1);
                String user = array.get(2);
                String pass =array.get(3);
                String authId = array.get(4);
                String displName = array.get(5);
                int expire = Integer.parseInt(array.get(6));
                cfg.addAccount(
                        domain,
                        proxy,
                        user,
                        pass,
                        authId,
                        displName,
                        expire,
                        false
                );

                phone.initialize(true);
                break;
            }
            case EVENT_UNREGISTER: {
                try {
                    phone.unregister();
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
            case EVENT_START_AUDIO_CALL: {
                this.isIncomingCall = false;
                String number = (String) arguments;
                Log.d("DEBUG_SIP_WRAPPER", "EVENT_START_AUDIO_CALL: " + number);
                try {
                    callId = phone.startCall(number, phone.getCurrentAccountId());
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
            case EVENT_START_VIDEO_CALL: {
                this.isIncomingCall = false;
                String number = (String) arguments;
                Log.d("DEBUG_SIP_WRAPPER", "EVENT_START_VIDEO_CALL: " + number);
                try {
                    callId = phone.startVideoCall(number, phone.getCurrentAccountId());
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
            case EVENT_END_CALL: {
                Log.d("DEBUG_SIP_WRAPPER", "EVENT_END_CALL: " +
                        "isIncomingCall: " + isIncomingCall + ", " +
                        "isCallConnected: " + isCallConnected + ", " +
                        "callId: " + callId);
                if (isIncomingCall && !isCallConnected) {
                    try {
                        phone.rejectCall(callId);
                        Log.d("DEBUG_SIP_WRAPPER", "rejectCall");
                    } catch (RemoteException e) {
                        e.printStackTrace();
                    }
                } else {
                    try {
                        phone.hangUp(callId);
                        Log.d("DEBUG_SIP_WRAPPER", "hangUp");
                    } catch (RemoteException e) {
                        e.printStackTrace();
                    }
                }
                break;
            }
            case EVENT_HANG_UP_CALL: {
                try {
                    int status = (int) arguments;
                    phone.hangUp(callId, status);
                    Log.d("DEBUG_SIP_WRAPPER", "hangUp");
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
            case EVENT_REJECT_CALL: {
                try {
                    phone.rejectCall(callId);
                    Log.d("DEBUG_SIP_WRAPPER", "reject");
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
            case EVENT_PICK_UP_CALL: {
                boolean isVideo = (Boolean) arguments;
                Log.d("DEBUG_SIP_WRAPPER", "EVENT_PICK_UP_CALL: " + isVideo);
                answerCall(callId, isVideo);
                break;
            }
            case EVENT_ENABLE_SPEAKER: {
                boolean enableSpeaker = (Boolean) arguments;
                Log.d("DEBUG_SIP_WRAPPER", "EVENT_ENABLE_SPEAKER: " + enableSpeaker);
                try {
                    phone.setSpeakerphoneOn(enableSpeaker);
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
            case EVENT_HOLD: {
                Log.d("DEBUG_SIP_WRAPPER", "EVENT_HOLD");
                try {
                    phone.holdRetriveCall(callId);
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
            case EVENT_MUTE: {
                boolean mute = (Boolean) arguments;
                Log.d("DEBUG_SIP_WRAPPER", "EVENT_MUTE: " + mute);
                try {
                    phone.setMicrophoneMute(mute);
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
            case EVENT_START_RECORD: {
                Log.d("DEBUG_SIP_WRAPPER", "EVENT_START_RECORD");
                recordFilePath = Environment.getExternalStoragePublicDirectory(
                        Environment.DIRECTORY_DOWNLOADS)
                        + File.separator + "audio "
                        + new SimpleDateFormat("MMMM dd, yyyy HH_mm_ss", Locale.ENGLISH).format(new Date())
                        + ".wav";
                try {
                    phone.startRecording(callId, recordFilePath);
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
            case EVENT_STOP_RECORD: {
                try {
                    phone.stopRecording(callId);
                    Toast.makeText(context, "Audio saved to: " + recordFilePath, Toast.LENGTH_LONG).show();
                    recordFilePath = null;
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
            case EVENT_TRANSFER: {
                String number = (String) arguments;
                phone.callXfer(callId, number);
                break;
            }
            case EVENT_SEND_TEXT: {
                ArrayList<String> array = (ArrayList<String>) arguments;
                try {
                    phone.sendTextMessage(phone.getCurrentAccountId(), array.get(1), array.get(0));
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
            case EVENT_SET_LOG_LEVEL: {
                ArrayList<Integer> array = (ArrayList<Integer>) arguments;
                AbtoPhoneCfg.setLogLevel(array.get(0), array.get(1) == 1);
                break;
            }
            case EVENT_SET_SENDING_RTP_VIDEO: {
                boolean enable = (boolean) arguments;
                try {
                    phone.setSendingRtpVideo(callId, enable);
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
            case EVENT_SEND_DTMF: {
                String dtmf = (String) arguments;
                try {
                    phone.sendTone(callId, dtmf.charAt(0));
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
            case EVENT_MUTE_LOCAL_VIDEO: {
                boolean mute = (boolean) arguments;
                try {
                    phone.muteLocalVideo(callId, mute);
                } catch (RemoteException e) {
                    e.printStackTrace();
                }
                break;
            }
        }
        result.success(null);
    }

    public void answerCall(int callId, boolean isVideo) {
        try {
            phone.answerCall(callId, 200, isVideo);
        } catch (RemoteException e) {
            e.printStackTrace();
        }
    }

    public void setupOutVideo(SurfaceView surfaceView) {
        this.outVideo = surfaceView;
        setupVideo();
    }

    public void setupIncVideo(SurfaceView surfaceView) {
        this.incVideo = surfaceView;
        setupVideo();
    }

    private void setupVideo() {
        if (outVideo != null && incVideo != null) {
            phone.setVideoWindows(callId, outVideo, incVideo);
        }
    }

    private Map<String, Object> buildConfigsMap() {
        AbtoPhoneCfg cfg = phone.getConfig();
        HashMap<String, Object> map = new HashMap<>();
        map.put("isSTUNEnabled", cfg.isSTUNEnabled());
        map.put("STUNServer", cfg.getSTUNServer());
        map.put("SipPort", cfg.getSipPort());
        map.put("SignalingTransport", cfg.getSignalingTransport().getValue());
        map.put("ICEEnabled", cfg.isICEEnabled());
        map.put("KeepAliveInterval", cfg.getKeepAliveInterval(cfg.getSignalingTransport()));
        map.put("InviteTimeout", cfg.getInviteTimeout());
        map.put("HangupTimeout", cfg.getHangupTimeout());
        map.put("RegisterTimeout", cfg.getRegisterTimeout());
        map.put("isUseSRTP", cfg.isUseSRTP());
        map.put("isEnabledAutoSendRtpVideo", cfg.isEnabledAutoSendRtpVideo());
        map.put("audioCodecs", CodecsUtils.codecsString(cfg, false));
        map.put("videoCodecs", CodecsUtils.codecsString(cfg, true));
        return map;
    }

    private void applyConfigs(Map<String, Object> map) {
        try {
            AbtoPhoneCfg cfg = phone.getConfig();
            cfg.setSTUNEnabled((Boolean) map.get("isSTUNEnabled"));
            cfg.setSTUNServer((String) map.get("STUNServer"));
            cfg.setSipPort((Integer) map.get("SipPort"));
            cfg.setSignallingTransport(AbtoPhoneCfg.SignalingTransportType.getTypeByValue(
                    (Integer) map.get("SignalingTransport")));
            cfg.setICEEnabled((Boolean) map.get("ICEEnabled"));
            cfg.setKeepAliveInterval(cfg.getSignalingTransport(), (Integer) map.get("KeepAliveInterval"));
            cfg.setInviteTimeout((Integer) map.get("InviteTimeout"));
            cfg.setHangupTimeout((Integer) map.get("HangupTimeout"));
            cfg.setRegisterTimeout((Integer) map.get("RegisterTimeout"));
            cfg.setUseSRTP((Boolean) map.get("isUseSRTP"));
            cfg.setEnableAutoSendRtpAudio((Boolean) map.get("isEnabledAutoSendRtpVideo"));
            CodecsUtils.applyCodecs(cfg, (String) map.get("audioCodecs"));
            CodecsUtils.applyCodecs(cfg, (String) map.get("videoCodecs"));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
