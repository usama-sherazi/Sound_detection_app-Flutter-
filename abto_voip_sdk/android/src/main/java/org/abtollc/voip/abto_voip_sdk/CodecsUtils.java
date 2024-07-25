package org.abtollc.voip.abto_voip_sdk;

import org.abtollc.sdk.AbtoPhoneCfg;
import org.abtollc.utils.codec.Codec;

import java.util.ArrayList;
import java.util.List;

public class CodecsUtils {

    private static List<Codec> getCodecs(boolean isVideo) {
        ArrayList<Codec> codecs = new ArrayList<>();
        if (isVideo) {
            codecs.add(Codec.H263);
            codecs.add(Codec.H264);
            codecs.add(Codec.VP8);
        } else {
            codecs.add(Codec.GSM);
            codecs.add(Codec.PCMA);
            codecs.add(Codec.PCMU);
            codecs.add(Codec.ILBC);
            codecs.add(Codec.speex_8000);
            codecs.add(Codec.G729);
            codecs.add(Codec.G722);
            codecs.add(Codec.G7221_16000);
            codecs.add(Codec.G723);
            codecs.add(Codec.SILK_8000);
            codecs.add(Codec.OPUS);
        }
        return codecs;
    }

    private static String getName(Codec codec) {
        switch (codec) {
            case H263: return "H263";
            case H264: return "H264";
            case VP8: return "VP8";
            case GSM: return "GSM";
            case PCMA: return "PCMA";
            case PCMU: return "PCMU";
            case ILBC: return "ILBC";
            case speex_8000: return "SPEEDX";
            case G729: return "G729";
            case G722: return "G722";
            case G7221_16000: return "G722_1";
            case G723: return "G723";
            case SILK_8000: return "SILK";
            case OPUS: return "OPUS";
            default: return "";
        }
    }

    private static Codec getCodecByName(String name) {
        for(Codec codec: Codec.values()) {
            if (getName(codec).equals(name)) return codec;
        }
        return Codec.values()[0];
    }

    public static String codecsString(AbtoPhoneCfg abtoPhoneCfg, boolean isVideo) {
        String type = abtoPhoneCfg.getCodecType();
        String data = "";
        for(Codec codec: getCodecs(isVideo)) {
            data += getName(codec) + "-" + abtoPhoneCfg.getCodecPriority(codec, type, (short) 0) + ";";
        }
        return data;
    }

    public static void applyCodecs(AbtoPhoneCfg abtoPhoneCfg, String data) {
        String type = abtoPhoneCfg.getCodecType();
        String[] array = data.split(";");
        for(String value: array) {
            String[] pair = value.split("-");
            if (pair.length == 0) break;
            abtoPhoneCfg.setCodecPriority(getCodecByName(pair[0]), type, Short.parseShort(pair[1]));
        }
    }

}
