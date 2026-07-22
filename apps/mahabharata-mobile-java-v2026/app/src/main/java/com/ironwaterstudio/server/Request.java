package com.ironwaterstudio.server;

import android.text.TextUtils;

import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.listeners.CallListener;
import com.ironwaterstudio.server.listeners.OnCallListener;

import java.util.HashMap;
import java.util.Map;

public abstract class Request {
	public static final int CACHE_NONE = 0;
	public static final int CACHE_STATIC = 1;
	public static final int CACHE_DYNAMIC = 2;
	public static final int CACHE_OFFLINE = 4;
	public static final int CACHE_SMART = 8;
	public static final long CACHE_10_YEARS = 315360000000L;

	private final String action;
	private int cacheMode = CACHE_NONE;
	private long cachePeriod = 0;
	private Object params = null;
	private String serializedParams = null;
	private String cacheKey = null;
	private Class<?> resultClass = null;
	private Object tag;
	private boolean publishProgress = false;
	private ServiceCallTask task = null;
	private ApiResult cacheResult = null;

	public Request(String action) {
		this.action = action;
	}

	public Request(Request request) {
		action = request.action;
		cacheMode = request.cacheMode;
		cachePeriod = request.cachePeriod;
		params = request.params;
		serializedParams = request.serializedParams;
		cacheKey = request.cacheKey;
		resultClass = request.resultClass;
		tag = request.tag;
	}

	public String getAction() {
		return action;
	}

	public int getCacheMode() {
		return cacheMode;
	}

	public long getCachePeriod() {
		return cachePeriod;
	}

	public Request setCache(int cacheMode) {
		return setCache(cacheMode, CACHE_10_YEARS);
	}

	public Request setCache(int cacheMode, long cachePeriod) {
		this.cacheMode = cacheMode;
		this.cachePeriod = cachePeriod;
		return this;
	}

	protected boolean isCacheEnabled() {
		return getCacheMode() > 0 && getCachePeriod() > 0 && !TextUtils.isEmpty(getCacheKey());
	}

	public boolean hasCacheMode(int cacheMode) {
		return isCacheEnabled() && (getCacheMode() & cacheMode) == cacheMode;
	}

	public String getSerializedParams() {
		if (TextUtils.isEmpty(serializedParams) && params != null)
			serializedParams = serializeParams(params);
		return serializedParams;
	}

	public Object getParams() {
		return params;
	}

	public Request setParams(Object params) {
		this.params = params;
		return this;
	}

	public Request buildParams(Object... params) {
		return setParams(convertParams(params));
	}

	public String getCacheKey() {
		if (TextUtils.isEmpty(cacheKey)) {
			String key = getAction();
			String params = getSerializedParams();
			if (!TextUtils.isEmpty(params))
				key += ";" + params;
			cacheKey = "c" + key.hashCode();
		}
		return cacheKey;
	}

	public Request setCacheKey(String cacheKey) {
		this.cacheKey = cacheKey;
		return this;
	}

	public Class<?> getResultClass() {
		return resultClass;
	}

	public Request setResultClass(Class<?> resultClass) {
		this.resultClass = resultClass;
		return this;
	}

	public Object getTag() {
		return tag;
	}

	public Request setTag(Object tag) {
		this.tag = tag;
		return this;
	}

	public boolean isPublishProgress() {
		return publishProgress;
	}

	public Request setPublishProgress(boolean publishProgress) {
		this.publishProgress = publishProgress;
		return this;
	}

	protected ServiceCallTask getTask() {
		return task;
	}

	protected void setTask(ServiceCallTask task) {
		this.task = task;
	}

	protected boolean beforeExecute() {
		return true;
	}

	protected abstract ResponseInfo execute();

	protected abstract Request copy();

	public ApiResult call() {
		try {
			ApiResult result = hasCacheMode(CACHE_STATIC) && !hasCacheMode(CACHE_SMART) ? fromCache() : null;
			if (result != null)
				return result;

			ResponseInfo response = null;
			if (beforeExecute())
				response = execute();

			result = response != null ? processResponse(response) : hasCacheMode(CACHE_SMART) ?
					ApiResult.createCancel() : (hasCacheMode(CACHE_OFFLINE) || hasCacheMode(CACHE_DYNAMIC)) ? fromCache() : null;
			if (result == null)
				result = ApiResult.connectionError();

			if (isCacheEnabled() && result.isSuccess() && response != null)
				response.toCache(getCacheKey(), getCachePeriod());
			return result;
		} catch (Throwable t) {
			t.printStackTrace();
			return ApiResult.create(ApiResult.ERROR);
		}
	}

	private ApiResult fromCache() {
		if (cacheResult != null)
			return cacheResult;
		cacheResult = processResponse(ResponseInfo.fromCache(getCacheKey()));
		return cacheResult;
	}

	private ApiResult processResponse(ResponseInfo response) {
		ApiResult result = (response != null) ? parseResponse(response) : null;
		if (result != null && result.isSuccess() && getResultClass() != null)
			result.setObject(result.getData(getResultClass()));
		return result;
	}

	public final ServiceCallTask call(OnCallListener listener) {
		if (!hasCacheMode(CACHE_SMART) || !CacheManager.getInstance().containsKey(getCacheKey()))
			return callInternal(listener);
		copy().setCache(CACHE_STATIC, getCachePeriod()).callInternal(listener);
		return callInternal(listener);
	}

	private ServiceCallTask callInternal(OnCallListener listener) {
		return task = listener instanceof CallListener ? ServiceLoader.execute(this, (CallListener) listener) : ServiceCallTask.execute(this, listener);
	}

	protected String serializeParams(Object params) {
		return null;
	}

	protected ApiResult parseResponse(ResponseInfo responseInfo) {
		return null;
	}

	protected static Map<String, Object> convertParams(Object... params) {
		Map<String, Object> mapParams = new HashMap<>();
		for (int i = 0; i < params.length / 2; i++)
			mapParams.put(params[2 * i].toString(), params[2 * i + 1]);
		return mapParams;
	}
}
