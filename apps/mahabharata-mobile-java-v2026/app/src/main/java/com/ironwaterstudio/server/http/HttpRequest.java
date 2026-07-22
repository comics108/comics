package com.ironwaterstudio.server.http;

import android.text.TextUtils;
import android.util.Log;

import com.ironwaterstudio.server.CacheManager;
import com.ironwaterstudio.server.ProgressInputStream;
import com.ironwaterstudio.server.ProgressOutputStream;
import com.ironwaterstudio.server.Request;
import com.ironwaterstudio.server.ResponseInfo;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.serializers.MultipartSerializer;
import com.ironwaterstudio.server.serializers.Serializer;
import com.ironwaterstudio.utils.FileUtils;

import java.io.InputStream;
import java.io.StringReader;
import java.io.StringWriter;
import java.net.HttpURLConnection;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

public class HttpRequest extends Request {
	private static final String LOG_TAG = "HttpRequest";
	private static final int LOG_PARAMS_LENGTH = 1000;

	private String httpMethod = HttpHelper.METHOD_POST;
	private String contentType = HttpHelper.CT_JSON;
	private int timeout = HttpHelper.CONNECTION_TIMEOUT;
	private Object urlParams = null;
	private String url = null;

	private final Map<String, String> headers = new HashMap<>();

	public HttpRequest(String action) {
		super(action);
	}

	public HttpRequest(HttpRequest request) {
		super(request);
		httpMethod = request.httpMethod;
		contentType = request.contentType;
		timeout = request.timeout;
		urlParams = request.urlParams;
		url = request.url;
		headers.putAll(request.headers);
	}

	@Override
	public String getAction() {
		if (TextUtils.isEmpty(url))
			url = urlParams != null ? super.getAction() + "?" + serializeParams(urlParams) : super.getAction();
		return url;
	}

	public String getHttpMethod() {
		return httpMethod;
	}

	public String getContentType() {
		return contentType;
	}

	public int getTimeout() {
		return timeout;
	}

	public Map<String, String> getHeaders() {
		return headers;
	}

	public HttpRequest setHttpMethod(String httpMethod) {
		this.httpMethod = httpMethod;
		return this;
	}

	public HttpRequest setContentType(String contentType) {
		this.contentType = contentType;
		return this;
	}

	public HttpRequest setTimeout(int timeout) {
		this.timeout = timeout;
		return this;
	}

	public HttpRequest setUrlParams(Object urlParams) {
		this.urlParams = urlParams;
		return this;
	}

	public HttpRequest buildUrlParams(Object... params) {
		return setUrlParams(convertParams(params));
	}

	public HttpRequest addHeader(String key, String value) {
		headers.put(key, value);
		return this;
	}

	@Override
	protected boolean beforeExecute() {
		long lastModified = hasCacheMode(CACHE_DYNAMIC) ? CacheManager.getInstance().getLastModified(getCacheKey()) : 0;
		if (lastModified > 0)
			addHeader("If-Modified-Since", HttpHelper.HTTP_DATE_FORMAT.format(new Date(lastModified)));
		return true;
	}

	@SuppressWarnings("unchecked")
	@Override
	protected ResponseInfo execute() {
		HttpURLConnection conn = null;
		try {
			Log.d(LOG_TAG, String.format("url: %s, params: %s", getAction(), getDataForLog(getSerializedParams())));
			conn = HttpHelper.createRequest(getContentType(), getHttpMethod(), getAction(), getHeaders(), getTimeout());

			if (getContentType().equals(HttpHelper.CT_MULTIPART))
				new MultipartSerializer(ProgressOutputStream.create(getTask(), conn.getOutputStream(), MultipartSerializer.sizeOf(getParams()), isPublishProgress())).write(getParams());
			else if (!getHttpMethod().equals(HttpHelper.METHOD_GET) && !TextUtils.isEmpty(getSerializedParams()))
				FileUtils.writeStream(ProgressOutputStream.create(getTask(), conn.getOutputStream(), getSerializedParams().length(), isPublishProgress()), getSerializedParams());

			int responseCode = HttpHelper.getResponseCode(conn);
			InputStream is = responseCode < HttpURLConnection.HTTP_BAD_REQUEST ?
					ProgressInputStream.create(getTask(), conn.getInputStream(), conn.getContentLength(), isPublishProgress()) : conn.getErrorStream();
			String response = FileUtils.readStream(is);
			Log.d(LOG_TAG, String.format("url: %s, code: %d, response: %s", getAction(), responseCode, getDataForLog(response)));
			return (responseCode != HttpURLConnection.HTTP_NOT_MODIFIED) ? new ResponseInfo(responseCode, response, HttpHelper.getContentType(conn)) : null;
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

	@Override
	protected HttpRequest copy() {
		return new HttpRequest(this);
	}

	@Override
	protected String serializeParams(Object params) {
		StringWriter sw = new StringWriter();
		Serializer.write(params == urlParams ? HttpHelper.CT_FORM : getContentType(), params, sw);
		return sw.toString();
	}

	@Override
	public ApiResult parseResponse(ResponseInfo responseInfo) {
		ApiResult result = Serializer.read(responseInfo.getContentType(), new StringReader(responseInfo.getData(String.class)), ApiResult.class);
		if (result != null && responseInfo.isFromCache())
			result.setCode(ResponseInfo.CODE_CACHE);
		return result;
	}

	private static String getDataForLog(String data) {
		return (data == null) ? "" : (data.length() > LOG_PARAMS_LENGTH) ?
				data.substring(0, LOG_PARAMS_LENGTH) + "..." : data;
	}
}