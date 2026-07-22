package com.ironwaterstudio.server;

import android.text.TextUtils;

import com.ironwaterstudio.server.http.HttpHelper;

public class ResponseInfo {
	public static int CODE_CACHE = 87435;

	private final int code;
	private final Object data;
	private final String contentType;

	public ResponseInfo(int code, Object data, String contentType) {
		this.code = code;
		this.data = data;
		this.contentType = contentType;
	}

	public int getCode() {
		return code;
	}

	public Object getData() {
		return data;
	}

	@SuppressWarnings("unchecked")
	public <T> T getData(Class<T> cls) {
		if (isFromCache())
			return CacheManager.getInstance().getObject((String) data, cls);
		if (data != null && cls.isInstance(data))
			return (T) data;
		return null;
	}

	public boolean isFromCache() {
		return code == CODE_CACHE;
	}

	public String getContentType() {
		return contentType;
	}

	public void toCache(String key, long period) {
		CacheManager.getInstance().setObject(key, getData(), period, getExtension(contentType));
	}

	public static ResponseInfo fromCache(String key) {
		return CacheManager.getInstance().containsKey(key) ? new ResponseInfo(CODE_CACHE, key, getContentType(CacheManager.getInstance().getExtension((key)))) : null;
	}

	private static String getExtension(String contentType) {
		if (TextUtils.isEmpty(contentType))
			return CacheManager.CACHE_EXT;

		switch (contentType) {
			case HttpHelper.CT_JSON:
				return CacheManager.JSON_EXT;
			case HttpHelper.CT_XML:
			case HttpHelper.CT_TEXT_XML:
				return CacheManager.XML_EXT;
			case HttpHelper.CT_FORM:
				return CacheManager.FORM_EXT;
			default:
				return CacheManager.CACHE_EXT;
		}
	}

	private static String getContentType(String extension) {
		switch (extension) {
			case CacheManager.JSON_EXT:
				return HttpHelper.CT_JSON;
			case CacheManager.XML_EXT:
				return HttpHelper.CT_XML;
			case CacheManager.FORM_EXT:
				return HttpHelper.CT_FORM;
			default:
				return null;
		}
	}
}