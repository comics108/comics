package com.ironwaterstudio.server.serializers;

import android.graphics.Bitmap;
import android.net.Uri;
import android.text.TextUtils;
import android.util.Log;
import android.webkit.MimeTypeMap;

import com.ironwaterstudio.server.http.HttpHelper;
import com.ironwaterstudio.utils.FileUtils;
import com.ironwaterstudio.utils.ReflectionUtils;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Array;
import java.util.Map;

public class MultipartSerializer {
	private static final String NEW_LINE = "\r\n";

	private final OutputStream os;
	private String charset = "UTF-8";
	private Bitmap.CompressFormat compressFormat = Bitmap.CompressFormat.JPEG;
	private int compressQuality = 70;

	public MultipartSerializer(OutputStream os) {
		this.os = os;
	}

	public void setCharset(String charset) {
		this.charset = charset;
	}

	public void setBitmapFormat(Bitmap.CompressFormat compressFormat, int compressQuality) {
		this.compressFormat = compressFormat;
		this.compressQuality = compressQuality;
	}

	public void write(Object obj) throws IOException {
		Map<String, Object> map = ReflectionUtils.buildMap(obj, null);
		if (map == null) {
			logTypeError(obj == null ? "null" : obj.getClass().getSimpleName());
			return;
		}
		if (map.isEmpty())
			return;

		writeBoundary();
		for (String key : map.keySet())
			writeValue(key, map.get(key));
		writeString("--");
	}

	private void writeValue(String key, Object value) throws IOException {
		if (value == null)
			return;

		if (value instanceof String) {
			write(key, (String) value);
		} else if (value instanceof Boolean || value instanceof Number) {
			write(key, value.toString());
		} else if (value instanceof Bitmap) {
			write(key, (Bitmap) value);
		} else if (value instanceof byte[]) {
			write(key, (byte[]) value);
		} else if (value instanceof Uri) {
			Uri uri = (Uri) value;
			write(key, uri.getLastPathSegment(), HttpHelper.getContext().getContentResolver().openInputStream(uri));
		} else if (value instanceof File) {
			File file = (File) value;
			write(key, file.getName(), new FileInputStream(file));
		} else if (value.getClass().isArray()) {
			for (int i = 0; i < Array.getLength(value); i++)
				writeValue(key + "[]", Array.get(value, i));
		} else if (value instanceof Iterable) {
			for (Object obj : ((Iterable) value))
				writeValue(key + "[]", obj);
		}
	}

	private void write(String key, String value) throws IOException {
		writeHeader(key, null, null);
		writeString(value);
		writeString(NEW_LINE);
		writeBoundary();
	}

	private void write(String key, Bitmap value) throws IOException {
		boolean isJpg = compressFormat == Bitmap.CompressFormat.JPEG;
		writeHeader(key, key + (isJpg ? ".jpg" : ".png"), isJpg ? "image/jpeg" : "image/png");
		value.compress(compressFormat, compressQuality, os);
		writeString(NEW_LINE);
		writeBoundary();
	}

	private void write(String key, byte[] value) throws IOException {
		writeHeader(key, key + ".dat", "content/unknown");
		os.write(value);
		writeString(NEW_LINE);
		writeBoundary();
	}

	private void write(String key, String filename, InputStream value) throws IOException {
		if (TextUtils.isEmpty(filename))
			filename = key;

		int index = filename.lastIndexOf(".");
		String contentType = index >= 0 ? MimeTypeMap.getSingleton().getMimeTypeFromExtension(filename.substring(index + 1)) : null;
		if (TextUtils.isEmpty(contentType))
			contentType = "content/unknown";

		writeHeader(key, filename, contentType);
		FileUtils.copyStream(value, os, false);
		writeString(NEW_LINE);
		writeBoundary();
	}

	private void writeHeader(String name, String filename, String contentType) throws IOException {
		writeString(NEW_LINE);
		writeString("Content-Disposition: form-data; name=\"%s\"", name);
		if (!TextUtils.isEmpty(filename))
			writeString("; filename=\"%s\"", filename);
		writeString(NEW_LINE);
		if (!TextUtils.isEmpty(contentType)) {
			writeString("%s: %s", HttpHelper.CONTENT_TYPE_KEY, contentType);
			writeString(NEW_LINE);
		}
		writeString(NEW_LINE);
	}

	private void writeBoundary() throws IOException {
		writeString("--%s", HttpHelper.MULTIPART_BOUNDARY);
	}

	private void writeString(String format, Object... args) throws IOException {
		os.write(String.format(format, args).getBytes(charset));
	}

	/**
	 * Method calculates an approximate params size (without boundaries and param headers).
	 */
	public static int sizeOf(Object obj) {
		Map<String, Object> map = ReflectionUtils.buildMap(obj, null);
		if (map == null || map.isEmpty())
			return 0;

		int bytesCount = 0;
		for (String key : map.keySet())
			bytesCount += sizeOf(key, map.get(key));
		return bytesCount;
	}

	private static int sizeOf(String key, Object value) {
		if (value == null)
			return 0;

		int bytes = key.length();
		if (value instanceof String) {
			bytes += ((String) value).length();
		} else if (value instanceof Boolean || value instanceof Number) {
			bytes += value.toString().length();
		} else if (value instanceof Bitmap) {
			bytes += ((Bitmap) value).getByteCount();
		} else if (value instanceof byte[]) {
			bytes += ((byte[]) value).length;
		} else if (value instanceof Uri) {
			bytes += sizeOfUri((Uri) value);
		} else if (value instanceof File) {
			bytes += sizeOfFile((File) value);
		} else if (value.getClass().isArray()) {
			for (int i = 0; i < Array.getLength(value); i++)
				bytes += sizeOf(key + "[]", Array.get(value, i));
		} else if (value instanceof Iterable) {
			for (Object obj : ((Iterable) value))
				bytes += sizeOf(key + "[]", obj);
		}
		return bytes;
	}

	@SuppressWarnings("ConstantConditions")
	private static int sizeOfUri(Uri uri) {
		InputStream is = null;
		try {
			is = HttpHelper.getContext().getContentResolver().openInputStream(uri);
			return is.available();
		} catch (Throwable e) {
			e.printStackTrace();
		} finally {
			try {
				if (is != null)
					is.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		return 0;
	}

	private static int sizeOfFile(File file) {
		InputStream is = null;
		try {
			is = new FileInputStream(file);
			return is.available();
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			try {
				if (is != null)
					is.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		return 0;
	}

	private static void logTypeError(String className) {
		Log.w(MultipartSerializer.class.getSimpleName(), className + " is unsupported type");
	}
}
