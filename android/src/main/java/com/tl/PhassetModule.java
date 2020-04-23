package com.tl;

import android.content.Context;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.AsyncTask;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.GuardedAsyncTask;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;

import java.io.File;
import java.io.IOException;
import java.util.UUID;

public class PhassetModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;

    public PhassetModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "Phasset";
    }

    @ReactMethod
    public void requestImage(ReadableMap params, final Promise promise) {
        // Run in guarded async task to prevent blocking the React bridge
        new ResizeImageTask(reactContext, params, promise).executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
    }

    static class ResizeImageTask extends GuardedAsyncTask<Void, Void> {

        private final Context context;
        private final ReadableMap params;
        private final Promise promise;

        protected ResizeImageTask(ReactContext reactContext, ReadableMap params, Promise promise) {
            super(reactContext.getExceptionHandler());
            this.context = reactContext;
            this.params = params;
            this.promise = promise;
        }

        @Override
        protected void doInBackgroundGuarded(Void... voids) {
            final String uri = params.getString("uri");
            final int maxWidth = params.hasKey("maxWidth") ? params.getInt("maxWidth") : 1024;
            final int maxHeight = params.hasKey("maxHeight") ? params.getInt("maxHeight") : 1024;
            try {
                WritableMap result = createResizedImageWithExceptions(uri, maxWidth, maxHeight);
                promise.resolve(result);
            }
            catch (IOException e) {
                promise.reject(e);
            }
        }

        private WritableMap createResizedImageWithExceptions(String imagePath, int maxWidth, int maxHeight) throws IOException {
            Bitmap.CompressFormat compressFormat = Bitmap.CompressFormat.JPEG;
            Uri imageUri = Uri.parse(imagePath);

            Bitmap scaleBitmap = ImageResizer.decodeSampledBitmap(context, imageUri, maxWidth, maxHeight);

            if (scaleBitmap == null) {
                throw new IOException("The image failed to be resized; invalid Bitmap result.");
            }

            // Save the resulting image
            String fileName = UUID.randomUUID().toString() + "." + compressFormat.name();
            File result = new File(context.getCacheDir(), fileName);
            ImageResizer.saveImage(result.getAbsolutePath(), scaleBitmap);

            WritableMap response = Arguments.createMap();
            response.putString("path", result.getAbsolutePath());
            response.putString("uri", Uri.fromFile(result).toString());
            response.putString("name", result.getName());
            response.putDouble("size", result.length());
            response.putDouble("width", scaleBitmap.getWidth());
            response.putDouble("height", scaleBitmap.getHeight());
            // Clean up bitmap
            scaleBitmap.recycle();
            return response;
        }
    }
}
