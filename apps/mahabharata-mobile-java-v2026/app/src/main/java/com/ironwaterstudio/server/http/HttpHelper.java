package com.ironwaterstudio.server.http;

import android.content.Context;
import android.os.Build;

import com.ironwaterstudio.server.CacheManager;
import com.ironwaterstudio.server.serializers.Serializer;
import com.ironwaterstudio.utils.Utils;

import java.io.IOException;
import java.net.CookieManager;
import java.net.CookiePolicy;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.UnknownHostException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Locale;
import java.util.Map;

public final class HttpHelper {
	public static final String CONTENT_TYPE_KEY = "Content-Type";
	private static final String USER_AGENT_KEY = "User-Agent";
	public static final int CONNECTION_TIMEOUT = 30000;
	public static final DateFormat HTTP_DATE_FORMAT = new SimpleDateFormat("EEE, d MMM yyyy HH:mm:ss 'GMT'", Locale.ENGLISH);

	public static final String METHOD_GET = "GET";
	public static final String METHOD_POST = "POST";
	public static final String CT_BINARY = "application/octet-stream";
	public static final String CT_JSON = "application/json";
	public static final String CT_XML = "application/xml";
	public static final String CT_FORM = "application/x-www-form-urlencoded";
	public static final String CT_TEXT_XML = "text/xml";
	public static final String MULTIPART_BOUNDARY = "731585a800ab43229f520cdc49452eb3";
	public static final String CT_MULTIPART = "multipart/form-data; boundary=" + MULTIPART_BOUNDARY;

	private static Context context;
	private static String userAgent = "Android";

	static {
		System.setProperty("http.keepAlive", "false");
		HTTP_DATE_FORMAT.setTimeZone(Utils.UTC_TIMEZONE);
	}

	public static void init(Context context) {
		HttpHelper.context = context;
		CacheManager.initInstance(context);
		HttpHelper.buildUserAgent();
		HttpHelper.initCookies();
		Serializer.init();
	}

	public static Context getContext() {
		return context;
	}

	public static HttpURLConnection createRequest(String contentType, String method, String url,
												  Map<String, String> headers, int timeout) throws Exception {
		HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
		conn.setConnectTimeout(timeout);
		conn.setReadTimeout(timeout);
		conn.setDoOutput(!method.equals(METHOD_GET));
		conn.setRequestMethod(method);
		conn.setRequestProperty(CONTENT_TYPE_KEY, contentType);
		conn.setRequestProperty(USER_AGENT_KEY, userAgent);
		if (headers != null) {
			for (String key : headers.keySet())
				conn.setRequestProperty(key, headers.get(key));
		}
		return conn;
	}

	public static int getResponseCode(HttpURLConnection conn) throws IOException {
		// in some Android versions method HttpURLConnection.getResponseCode() throws
		// IOException: No authentication challenges found
		// when processing server response with 401 response code
		try {
			return conn.getResponseCode();
		} catch (UnknownHostException e) {
			throw e;
		} catch (IOException e) {
			if ("No authentication challenges found".equals(e.getMessage()))
				return HttpURLConnection.HTTP_UNAUTHORIZED;
			throw e;
		}
	}

	public static String getContentType(HttpURLConnection conn) {
		String contentType = conn.getContentType();
		int index = contentType.indexOf(";");
		return index != -1 ? contentType.substring(0, index) : contentType;
	}

	private static void buildUserAgent() {
		String name = context.getPackageName();
		String version = Utils.getAppVersion(context);
		String deviceModel = Build.MODEL;
		String androidVersion = Build.VERSION.RELEASE;
		userAgent = String.format("%s/%s (%s; Android %s)", name, version, deviceModel, androidVersion);
	}

	private static void initCookies() {
		CookieManager manager = new CookieManager(new PersistentCookieStore(context), CookiePolicy.ACCEPT_ALL);
		CookieManager.setDefault(manager);
	}

	public static void clearCookies() {
		((CookieManager) CookieManager.getDefault()).getCookieStore().removeAll();
	}
}
