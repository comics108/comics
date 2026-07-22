package com.ironwaterstudio.server.http;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import com.ironwaterstudio.server.ProgressInputStream;
import com.ironwaterstudio.server.ResponseInfo;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.utils.Utils;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;

public class HttpImageRequest extends HttpRequest {
	private static final int BUFFER_SIZE = 64 * 1024;

	private int width = 0;
	private int height = 0;
	private boolean exact = false;
	private Context context = null;
	private int resId = -1;

	public HttpImageRequest(String action) {
		super(action);
	}

	public HttpImageRequest(Context context, int resId) {
		super(context.getResources().getResourceName(resId));
		this.context = context;
		this.resId = resId;
	}

	public HttpImageRequest(HttpImageRequest request) {
		super(request);
		width = request.width;
		height = request.height;
		exact = request.exact;
		context = request.context;
		resId = request.resId;
	}

	public int getWidth() {
		return width;
	}

	public int getHeight() {
		return height;
	}

	public HttpImageRequest setSize(int width, int height) {
		return setSize(width, height, false);
	}

	public HttpImageRequest setSize(int width, int height, boolean exact) {
		this.width = width;
		this.height = height;
		this.exact = exact;
		buildParams("width", width, "height", height, "exact", exact);
		return this;
	}

	@Override
	protected ResponseInfo execute() {
		Bitmap bitmap = (resId != -1) ? loadImageResource() : Utils.isUrl(getAction()) ? loadImageUrl() : loadImageFile();
		float factor = bitmap != null && isScaled() && exact ? getScaleFactor(bitmap.getWidth(), bitmap.getHeight()) : 1f;
		if (factor > 1f) {
			Bitmap origBitmap = bitmap;
			bitmap = Bitmap.createScaledBitmap(origBitmap, (int) (bitmap.getWidth() / factor), (int) (bitmap.getHeight() / factor), true);
			origBitmap.recycle();
		}
		// In Android 5.0 the method decodeStream doesn't throw an exception when thread is interrupted.
		// Part of bitmap is returned in this case. To solve this issue we need to analyse AsyncTask.isCancelled() flag.
		return (bitmap != null && (getTask() == null || !getTask().isCancelled())) ? new ResponseInfo(HttpURLConnection.HTTP_OK, bitmap, null) : null;
	}

	@Override
	public ApiResult parseResponse(ResponseInfo responseInfo) {
		return ApiResult.fromObject(responseInfo.getData(Bitmap.class));
	}

	@Override
	protected HttpRequest copy() {
		return new HttpImageRequest(this);
	}

	public boolean isScaled() {
		return width > 0 || height > 0;
	}

	private float getScaleFactor(int origWidth, int origHeight) {
		return Math.max((float) origWidth / (width > 0 ? width : Float.MAX_VALUE), (float) origHeight / (height > 0 ? height : Float.MAX_VALUE));
	}

	private Bitmap loadImageResource() {
		try {
			if (!isScaled())
				return BitmapFactory.decodeResource(context.getResources(), resId);

			BitmapFactory.Options opts = new BitmapFactory.Options();
			opts.inScaled = false;
			opts.inJustDecodeBounds = true;
			BitmapFactory.decodeResource(context.getResources(), resId, opts);
			opts.inSampleSize = (int) getScaleFactor(opts.outWidth, opts.outHeight);
			opts.inJustDecodeBounds = false;
			return BitmapFactory.decodeResource(context.getResources(), resId, opts);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}

	private Bitmap loadImageUrl() {
		HttpURLConnection conn = null;
		try {
			conn = HttpHelper.createRequest(HttpHelper.CT_BINARY, HttpHelper.METHOD_GET, getAction(), getHeaders(), getTimeout());
			int responseCode = HttpHelper.getResponseCode(conn);
			if (responseCode >= HttpURLConnection.HTTP_BAD_REQUEST || responseCode == HttpURLConnection.HTTP_NOT_MODIFIED)
				return null;

			if (!isScaled())
				return BitmapFactory.decodeStream(ProgressInputStream.create(getTask(), conn.getInputStream(), conn.getContentLength(), isPublishProgress()));

			InputStream stream = new BufferedInputStream(ProgressInputStream.create(getTask(), conn.getInputStream(), conn.getContentLength(), isPublishProgress()), BUFFER_SIZE);
			stream.mark(BUFFER_SIZE);
			BitmapFactory.Options opts = new BitmapFactory.Options();
			opts.inJustDecodeBounds = true;
			BitmapFactory.decodeStream(stream, null, opts);
			opts.inJustDecodeBounds = false;
			opts.inSampleSize = (int) getScaleFactor(opts.outWidth, opts.outHeight);
			try {
				stream.reset();
			} catch (IOException e) {
				stream.close();
				conn.disconnect();
				conn = HttpHelper.createRequest(HttpHelper.CT_BINARY, HttpHelper.METHOD_GET, getAction(), getHeaders(), getTimeout());
				stream = new BufferedInputStream(ProgressInputStream.create(getTask(), conn.getInputStream(), conn.getContentLength(), isPublishProgress()), BUFFER_SIZE);
			}
			return BitmapFactory.decodeStream(stream, null, opts);
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		} finally {
			try {
				if (conn != null)
					conn.disconnect();
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}

	private Bitmap loadImageFile() {
		try {
			if (!isScaled())
				return BitmapFactory.decodeFile(getAction());

			BitmapFactory.Options opts = new BitmapFactory.Options();
			opts.inScaled = false;
			opts.inJustDecodeBounds = true;
			BitmapFactory.decodeFile(getAction(), opts);
			opts.inSampleSize = (int) getScaleFactor(opts.outWidth, opts.outHeight);
			opts.inJustDecodeBounds = false;
			return BitmapFactory.decodeFile(getAction(), opts);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}
}
