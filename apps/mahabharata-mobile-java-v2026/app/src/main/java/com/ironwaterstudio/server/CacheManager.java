package com.ironwaterstudio.server;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import androidx.annotation.IntRange;
import android.text.TextUtils;
import android.webkit.MimeTypeMap;

import com.ironwaterstudio.utils.FileUtils;
import com.ironwaterstudio.utils.LruBitmapCache;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public final class CacheManager {
	public static final String CACHE_EXT = ".cache";
	public static final String JSON_EXT = ".json";
	public static final String XML_EXT = ".xml";
	public static final String FORM_EXT = ".form";
	private static final String SEPARATOR = "_";

	private static CacheManager instance = null;
	private static final LruBitmapCache<String> bitmapCache = new LruBitmapCache<>();

	public static CacheManager getInstance() {
		return instance;
	}

	public static void initInstance(Context context) {
		if (instance == null) {
			instance = new CacheManager(context);
		}
	}

	public static LruBitmapCache<String> getBitmapCache() {
		return bitmapCache;
	}

	private final Context context;
	private Map<String, CacheInfo> info = new HashMap<>();

	public CacheManager(Context context) {
		this.context = context;
		loadInfo();
		cleanup();
	}

	private File getCacheDir() {
		File dir = context.getExternalCacheDir();
		if (dir == null)
			dir = context.getCacheDir();
		return dir;
	}

	private File createFile(String key, long expiresTime, String extension) {
		return new File(getCacheDir(), key + SEPARATOR + expiresTime + extension);
	}

	private boolean loadFileInfo(File file) {
		String extension = MimeTypeMap.getFileExtensionFromUrl(file.getName());
		if (TextUtils.isEmpty(extension))
			return false;
		extension = "." + extension;
		String[] parts = file.getName().replace(extension, "").split(SEPARATOR);
		if (parts.length != 2)
			return false;

		long expiresTime;
		try {
			expiresTime = Long.parseLong(parts[1]);
		} catch (NumberFormatException e) {
			return false;
		}

		info.put(parts[0], new CacheInfo(expiresTime, extension));
		return true;
	}

	@SuppressWarnings("ResultOfMethodCallIgnored")
	private void loadInfo() {
		File dir = getCacheDir();
		File[] files = dir.listFiles();
		if (files == null || files.length == 0)
			return;

		for (File file : files) {
			if (!loadFileInfo(file))
				file.delete();
		}
	}

	public File getFile(String key) {
		if (!info.containsKey(key))
			return null;

		CacheInfo cacheInfo = info.get(key);
		if (cacheInfo.getExpiresTime() < System.currentTimeMillis()) {
			removeData(key);
			return null;
		}

		File file = createFile(key, cacheInfo.getExpiresTime(), cacheInfo.getExtension());
		if (!file.exists()) {
			removeData(key);
			return null;
		}
		return file;
	}

	public String getString(String key) {
		File file = getFile(key);
		return (file != null) ? FileUtils.readFile(file) : null;
	}

	public Bitmap getBitmap(String key) {
		File file = getFile(key);
		return (file != null) ? BitmapFactory.decodeFile(file.getAbsolutePath()) : null;
	}

	public byte[] getBytes(String key) {
		File file = getFile(key);
		return (file != null) ? FileUtils.readFileBytes(file) : null;
	}

	@SuppressWarnings("unchecked")
	public <T> T getObject(String key, Class<T> cls) {
		if (cls.equals(String.class))
			return (T) getString(key);
		if (cls.equals(Bitmap.class))
			return (T) getBitmap(key);
		if (cls.equals(File.class))
			return (T) getFile(key);
		if (cls.equals(byte[].class))
			return (T) getFile(key);
		return null;
	}

	public long getLastModified(String key) {
		File file = getFile(key);
		return (file != null) ? file.lastModified() : 0;
	}

	public String getExtension(String key) {
		return info.containsKey(key) ? info.get(key).getExtension() : null;
	}

	public File setData(String key, long period, String extension) {
		long expiresTime = System.currentTimeMillis() + period;
		info.put(key, new CacheInfo(expiresTime, extension));
		return createFile(key, expiresTime, extension);
	}

	public void setFile(String key, File value, long period) {
		File file = setData(key, period, "." + MimeTypeMap.getFileExtensionFromUrl(value.getName()));
		FileUtils.copyFile(value, file);
	}

	public void setString(String key, String value, long period, String extension) {
		File file = setData(key, period, extension);
		FileUtils.writeFile(file, value);
	}

	public void setBitmap(String key, Bitmap value, long period) {
		setBitmap(key, value, period, Bitmap.CompressFormat.PNG, 100);
	}

	public void setBitmap(String key, Bitmap value, long period, Bitmap.CompressFormat format, @IntRange(from = 0, to = 100) int quality) {
		File file = setData(key, period, "." + format.name().toLowerCase());
		FileUtils.writeFile(file, value, format, quality);
	}

	public void setBytes(String key, byte[] value, long period) {
		File file = setData(key, period, ".bin");
		FileUtils.writeFile(file, value);
	}

	public void setObject(String key, Object value, long period, String extension) {
		if (String.class.isInstance(value))
			setString(key, (String) value, period, extension);
		else if (Bitmap.class.isInstance(value))
			setBitmap(key, (Bitmap) value, period);
		else if (File.class.isInstance(value))
			setFile(key, (File) value, period);
		else if (byte[].class.isInstance(value))
			setBytes(key, (byte[]) value, period);
	}

	public boolean containsKey(String key) {
		return info.containsKey(key);
	}

	public void cleanup() {
		ArrayList<String> keys = new ArrayList<>();
		for (String key : info.keySet()) {
			CacheInfo cacheInfo = info.get(key);
			if (cacheInfo.getExpiresTime() < System.currentTimeMillis()) {
				keys.add(key);
				continue;
			}

			File file = createFile(key, cacheInfo.getExpiresTime(), cacheInfo.getExtension());
			if (!file.exists())
				keys.add(key);
		}

		if (keys.size() == 0)
			return;
		for (String key : keys)
			removeData(key);
	}

	@SuppressWarnings("ResultOfMethodCallIgnored")
	public void clear() {
		File dir = getCacheDir();
		if (dir.isDirectory()) {
			String[] children = dir.list();
			for (String aChildren : children)
				new File(dir, aChildren).delete();
		}
		info.clear();
	}

	@SuppressWarnings("ResultOfMethodCallIgnored")
	public void removeData(String key) {
		CacheInfo cacheInfo = info.get(key);
		if (cacheInfo == null)
			return;
		File file = createFile(key, cacheInfo.getExpiresTime(), cacheInfo.getExtension());
		if (file.exists())
			file.delete();
		info.remove(key);
	}

	private static class CacheInfo {
		private Long expiresTime;
		private String extension;

		public CacheInfo(Long expiresTime, String extension) {
			this.expiresTime = expiresTime;
			this.extension = extension;
		}

		public Long getExpiresTime() {
			return expiresTime;
		}

		public String getExtension() {
			return extension;
		}
	}
}