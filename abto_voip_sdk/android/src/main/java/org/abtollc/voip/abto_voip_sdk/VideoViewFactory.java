package org.abtollc.voip.abto_voip_sdk;

import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.view.SurfaceView;
import android.view.View;

import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class VideoViewFactory extends PlatformViewFactory {
    private final boolean isOut;

    public VideoViewFactory(boolean isOut) {
        super(StandardMessageCodec.INSTANCE);
        this.isOut = isOut;
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        return new NativeView(context, isOut);
    }

    static class NativeView implements PlatformView {
        VoipSurfaceView surfaceView;

        public NativeView(Context context, boolean isOut) {
            surfaceView = new VoipSurfaceView(context);
            surfaceView.isOut = isOut;
        }

        @Override
        public View getView() {
            return surfaceView;
        }

        @Override
        public void dispose() {

        }
    }

    public static class VoipSurfaceView extends SurfaceView {
        public boolean isOut;

        public VoipSurfaceView(Context context) {
            super(context);
        }

        public VoipSurfaceView(Context context, AttributeSet attrs) {
            super(context, attrs);
        }

        public VoipSurfaceView(Context context, AttributeSet attrs, int defStyleAttr) {
            super(context, attrs, defStyleAttr);
        }

        @Override
        protected void onSizeChanged(int w, int h, int oldw, int oldh) {
            super.onSizeChanged(w, h, oldw, oldh);
            Log.d("debug_sc", "old: " + oldw + ", " + oldh + "; new: " + w + ", " + h);
            if (isOut) {
                SipWrapper.getInstance().setupOutVideo(this);
            } else {
                SipWrapper.getInstance().setupIncVideo(this);
            }
        }
    }
}
