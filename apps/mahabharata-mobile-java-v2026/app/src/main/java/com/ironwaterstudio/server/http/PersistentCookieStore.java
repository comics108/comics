package com.ironwaterstudio.server.http;

import android.content.Context;
import android.content.SharedPreferences;
import android.text.TextUtils;

import java.net.CookieStore;
import java.net.HttpCookie;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class PersistentCookieStore implements CookieStore {
	private static final String COOKIE_PREFS = "CookieStore";
	private static final String SEPARATOR = "|";

	private static final String COOKIE_NAME_STORE = "names";
	private static final String COOKIE_NAME_PREFIX = "cookie_";

	private final Map<URI, Set<HttpCookieParcelable>> map = new HashMap<>();

	private final SharedPreferences cookiePrefs;

	public PersistentCookieStore(Context context) {
		cookiePrefs = context.getSharedPreferences(COOKIE_PREFS, 0);
		upgrade();
		load();
	}

	private void upgrade() {
		if (!cookiePrefs.contains(COOKIE_NAME_STORE))
			return;

		Map<URI, HttpCookieParcelable> cookies = new HashMap<>();
		String[] cookieNames = TextUtils.split(cookiePrefs.getString(COOKIE_NAME_STORE, ""), ",");
		for (String name : cookieNames) {
			String encodedCookie = cookiePrefs.getString(COOKIE_NAME_PREFIX + name, null);
			if (encodedCookie == null)
				continue;

			HttpCookieParcelable decodedCookie = HttpCookieParcelable.decode(encodedCookie);
			if (decodedCookie != null)
				cookies.put(URI.create(name), decodedCookie);
		}
		SharedPreferences.Editor editor = cookiePrefs.edit();
		editor.clear();
		for (URI key : cookies.keySet()) {
			HttpCookieParcelable cookie = cookies.get(key);
			editor.putString(buildPrefKey(key, cookie), cookie.encode());
		}
		editor.apply();
	}

	private void load() {
		Map<String, ?> allPrefs = cookiePrefs.getAll();
		for (String key : allPrefs.keySet()) {
			Object object = allPrefs.get(key);
			if (object == null || !(object instanceof String))
				continue;
			int index = key.indexOf(SEPARATOR);
			if (index <= 0)
				continue;

			HttpCookieParcelable decodedCookie = HttpCookieParcelable.decode((String) object);
			if (decodedCookie != null) {
				URI uri = URI.create(key.substring(0, index));
				Set<HttpCookieParcelable> cookies = map.get(uri);
				if (cookies == null) {
					cookies = new HashSet<>();
					map.put(uri, cookies);
				}
				cookies.add(decodedCookie);
			}
		}
	}

	@Override
	public synchronized void add(URI uri, HttpCookie cookie) {
		if (cookie == null)
			throw new NullPointerException("cookie == null");

		uri = cookiesUri(uri);
		HttpCookieParcelable cookieParcelable = new HttpCookieParcelable(cookie);
		Set<HttpCookieParcelable> cookies = map.get(uri);
		if (cookies == null) {
			cookies = new HashSet<>();
			map.put(uri, cookies);
		} else {
			cookies.remove(cookieParcelable);
		}
		cookies.add(cookieParcelable);

		SharedPreferences.Editor prefsWriter = cookiePrefs.edit();
		prefsWriter.putString(buildPrefKey(uri, cookieParcelable), cookieParcelable.encode());
		prefsWriter.apply();
	}

	@Override
	public synchronized List<HttpCookie> get(URI uri) {
		if (uri == null)
			throw new NullPointerException("uri == null");

		uri = cookiesUri(uri);
		Set<HttpCookie> result = new HashSet<>();
		for (URI key : map.keySet()) {
			Set<HttpCookieParcelable> cookies = map.get(key);
			removeExpired(key, cookies);
			for (HttpCookieParcelable cookie : cookies) {
				if (uri.equals(key) || HttpCookie.domainMatches(cookie.getCookie().getDomain(), uri.getHost()))
					result.add(cookie.getCookie());
			}
		}
		return Collections.unmodifiableList(new ArrayList<>(result));
	}

	@Override
	public synchronized List<HttpCookie> getCookies() {
		Set<HttpCookie> result = new HashSet<>();
		for (URI key : map.keySet()) {
			Set<HttpCookieParcelable> cookies = map.get(key);
			removeExpired(key, cookies);
			for (HttpCookieParcelable cookie : cookies)
				result.add(cookie.getCookie());
		}
		return Collections.unmodifiableList(new ArrayList<>(result));
	}

	@Override
	public synchronized List<URI> getURIs() {
		return Collections.unmodifiableList(new ArrayList<>(map.keySet()));
	}

	@Override
	public synchronized boolean remove(URI uri, HttpCookie cookie) {
		if (cookie == null)
			throw new NullPointerException("cookie == null");

		uri = cookiesUri(uri);
		HttpCookieParcelable cookieParcelable = new HttpCookieParcelable(cookie);
		Set<HttpCookieParcelable> cookies = map.get(uri);
		if (cookies == null)
			return false;

		SharedPreferences.Editor prefsWriter = cookiePrefs.edit();
		prefsWriter.remove(buildPrefKey(uri, cookieParcelable));
		prefsWriter.apply();
		return cookies.remove(cookieParcelable);
	}

	@Override
	public synchronized boolean removeAll() {
		SharedPreferences.Editor prefsWriter = cookiePrefs.edit();
		prefsWriter.clear();
		prefsWriter.apply();

		boolean result = !map.isEmpty();
		map.clear();
		return result;
	}

	private void removeExpired(URI uri, Set<HttpCookieParcelable> cookies) {
		SharedPreferences.Editor prefsWriter = cookiePrefs.edit();
		boolean apply = false;
		for (Iterator<HttpCookieParcelable> i = cookies.iterator(); i.hasNext(); ) {
			HttpCookieParcelable cookie = i.next();
			if (cookie.hasExpired()) {
				i.remove();
				prefsWriter.remove(buildPrefKey(uri, cookie));
				apply = true;
			}
		}
		if (apply)
			prefsWriter.apply();
	}

	private static String buildPrefKey(URI uri, HttpCookieParcelable cookie) {
		return uri.toString() + SEPARATOR + cookie.hashCode();
	}

	private static URI cookiesUri(URI uri) {
		if (uri == null)
			return null;

		try {
			return new URI(uri.getScheme(), uri.getHost(), null, null);
		} catch (URISyntaxException e) {
			return uri;
		}
	}
}
