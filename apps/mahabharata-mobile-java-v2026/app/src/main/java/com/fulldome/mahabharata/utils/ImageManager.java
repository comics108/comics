package com.fulldome.mahabharata.utils;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import com.fulldome.mahabharata.model.ComicsDescriptor;
import com.ironwaterstudio.server.ActionRequest;
import com.ironwaterstudio.server.CacheManager;
import com.ironwaterstudio.server.Request;
import com.ironwaterstudio.server.ServiceCallTask;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.listeners.SimpleCallListener;

import java.util.HashMap;

public class ImageManager {
	private static final HashMap<String, ServiceCallTask> tasks = new HashMap<>();

	public static Bitmap getBitmap(final ComicsDescriptor descriptor, final String fileName, final int sampleSize, ImageCallListener listener) {
		String key = buildKey(descriptor, fileName);
		Bitmap bitmap = CacheManager.getBitmapCache().get(key);
		if (bitmap != null)
			return bitmap;
		if (tasks.containsKey(key))
			return null;
		tasks.put(key, new ActionRequest(new ActionRequest.Runnable() {
			@Override
			public Object run() {
				return ApiResult.fromObject(loadImage(descriptor, fileName, sampleSize));
			}
		}).setTag(key).call(listener));
		return null;
	}

	public static Bitmap loadImage(ComicsDescriptor descriptor, String fileName, int sampleSize) {
		BitmapFactory.Options options = new BitmapFactory.Options();
		options.inSampleSize = sampleSize;
		return BitmapFactory.decodeStream(descriptor.getImage(fileName), null, options);
	}

	public static String buildKey(ComicsDescriptor descriptor, final String fileName) {
		return descriptor.getName() + "_" + fileName;
	}

	public static void cancel(ComicsDescriptor descriptor, String fileName) {
		String key = buildKey(descriptor, fileName);
		ServiceCallTask task = tasks.get(key);
		if (task != null) {
			task.cancel(true);
			tasks.remove(key);
		}
	}

	public static class ImageCallListener extends SimpleCallListener {
		@Override
		public void onSuccess(Request request, ApiResult result) {
			String key = (String) request.getTag();
			tasks.remove(key);
			Bitmap bitmap = result.getData(Bitmap.class);
			if (bitmap != null)
				CacheManager.getBitmapCache().put(key, bitmap);
			super.onSuccess(request, result);
		}

		@Override
		public void onError(Request request, ApiResult result) {
			String key = (String) request.getTag();
			tasks.remove(key);
			super.onError(request, result);
		}
	}
}
