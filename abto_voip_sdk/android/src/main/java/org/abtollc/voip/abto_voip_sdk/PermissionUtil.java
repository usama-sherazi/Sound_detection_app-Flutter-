package org.abtollc.voip.abto_voip_sdk;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.core.app.ActivityCompat;
import androidx.fragment.app.Fragment;

public class PermissionUtil {

    public static String[] permissions = {
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.USE_SIP,
         //   Manifest.permission.READ_CONTACTS,
            Manifest.permission.RECORD_AUDIO,
         //   Manifest.permission.WRITE_EXTERNAL_STORAGE,
            Manifest.permission.CAMERA};

    public static boolean checkPermissions(Context context, String[] keys) {
        for(String key: keys) {
            if ( ActivityCompat.checkSelfPermission(context, key) != PackageManager.PERMISSION_GRANTED ) {
                return false;
            }
        }
        return true;
    }


    private static final int REQUEST_CODE = 121;
    public static GrantedCallback grantedCallback = null;
    public static DeniedCallback deniedCallback = null;

    public static void request(Activity activity, String... keys) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            activity.requestPermissions(keys, REQUEST_CODE);
        }
    }

    public static void request(Fragment fragment, String... keys) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            fragment.requestPermissions(keys, REQUEST_CODE);
        }
    }

    public static void onRequestPermissionsResult(int requestCode, int[] grantResults) {
        if (requestCode == REQUEST_CODE) {
            for (int grantResult: grantResults) {
                if (grantResult == -1) {
                    if ( deniedCallback != null ) deniedCallback.denied();
                    clearCallbacks();
                    return;
                }
            }
        }
        if ( grantedCallback != null ) grantedCallback.granted();
        clearCallbacks();
    }

    public static boolean isAppCanRequestPermissions(Activity activity, String... keys) {
        boolean allowed = true;
        for (String key: keys) {
            if (!ActivityCompat.shouldShowRequestPermissionRationale(activity, key)) {
                allowed = false;
                break;
            }
        }
        return allowed;
    }

    public interface GrantedCallback {
        void granted();
    }
    public interface DeniedCallback {
        void denied();
    }

    private static void clearCallbacks() {
        grantedCallback = null;
        deniedCallback = null;
    }
}
