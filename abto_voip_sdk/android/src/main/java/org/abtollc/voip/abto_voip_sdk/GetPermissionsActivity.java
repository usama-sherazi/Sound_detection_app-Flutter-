package org.abtollc.voip.abto_voip_sdk;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import org.abtollc.utils.Log;

public class GetPermissionsActivity extends AppCompatActivity {
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d("DEBUG_SIP_WRAPPER", "request2");
        PermissionUtil.grantedCallback = this::finish;
        PermissionUtil.deniedCallback = this::finish;
        PermissionUtil.request(this, PermissionUtil.permissions);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        PermissionUtil.onRequestPermissionsResult(requestCode, grantResults);
    }
}