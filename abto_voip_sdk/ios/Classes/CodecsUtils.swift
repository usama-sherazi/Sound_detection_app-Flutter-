//
//  CodecsUtils.swift
//  abto_voip_sdk
//
//  Created by Dmytro Palamarchuk on 05.11.2022.
//

import Foundation
import AbtoSipClientWrapper

class CodecsUtils {
    
    private static func getCodecs(isVideo: Bool) -> [PhoneAudioVideoCodec] {
        var codecs: [PhoneAudioVideoCodec] = []
        if (isVideo) {
            codecs.append(PhoneAudioVideoCodec.H263)
            codecs.append(PhoneAudioVideoCodec.h264Bp10)
            codecs.append(PhoneAudioVideoCodec.vp8)
        } else {
            codecs.append(PhoneAudioVideoCodec.gsm)
            codecs.append(PhoneAudioVideoCodec.pcma)
            codecs.append(PhoneAudioVideoCodec.pcmu)
            codecs.append(PhoneAudioVideoCodec.ilbc)
            codecs.append(PhoneAudioVideoCodec.speex)
            codecs.append(PhoneAudioVideoCodec.g729ab)
            codecs.append(PhoneAudioVideoCodec.G722)
            codecs.append(PhoneAudioVideoCodec.G722_1)
            codecs.append(PhoneAudioVideoCodec.G723)
            codecs.append(PhoneAudioVideoCodec.silk)
            codecs.append(PhoneAudioVideoCodec.opus)
        }
        return codecs
    }
    
    private static func getName(codec: PhoneAudioVideoCodec) -> String {
        switch (codec) {
        case .H263: return "H263"
        case .h264Bp10: return "H264"
        case .vp8: return "VP8"
        case .gsm: return "GSM"
        case .pcma: return "PCMA"
        case .pcmu: return "PCMU"
        case .ilbc: return "ILBC"
        case .speex: return "SPEEDX"
        case .g729ab: return "G729"
        case .G722: return "G722"
        case .G722_1: return "G722_1"
        case .G723: return "G723"
        case .silk: return "SILK"
        case .opus: return "OPUS"
        default: return ""
        }
    }
    
    private static func getCodecByName(name: String, isVideo: Bool) -> PhoneAudioVideoCodec {
        for codec in getCodecs(isVideo: isVideo) {
            if getName(codec: codec) == name { return codec }
        }
        return getCodecs(isVideo: isVideo)[0]
    }
    
    static func codecsString(cfg: AbtoPhoneConfig, isVideo: Bool) -> String {
        var data = ""
        for codec in getCodecs(isVideo: isVideo) {
            data += "\(getName(codec: codec))-\(cfg.codecPriority(codec));"
        }
        return data
    }
    
    static func applyCodecs(cfg: AbtoPhoneConfig, data: String, isVideo: Bool) {
        let array = data.components(separatedBy: ";")
        for item in array {
            let pair = item.components(separatedBy: "-")
            if pair.count == 2 {
                let codec = getCodecByName(name: pair[0], isVideo: isVideo)
                cfg.setCodecPriority(codec, priority: Int(pair[1]) ?? 0)
            }
        }
    }
    
}
