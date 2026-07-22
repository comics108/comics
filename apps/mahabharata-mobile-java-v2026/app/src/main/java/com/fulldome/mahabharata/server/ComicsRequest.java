package com.fulldome.mahabharata.server;

import android.text.TextUtils;

import com.fulldome.mahabharata.BuildConfig;
import com.fulldome.mahabharata.model.Settings;
import com.ironwaterstudio.server.http.HttpHelper;
import com.ironwaterstudio.server.http.HttpRequest;

import java.util.Locale;

public class ComicsRequest extends HttpRequest {
	public ComicsRequest(ComicsRequest request) {
		super(request);
	}

	public ComicsRequest(String action) {
		super(BuildConfig.HOST + action);
		setHttpMethod(HttpHelper.METHOD_POST);
		addHeader("Accept-Language", Locale.getDefault().getLanguage());
		if (!TextUtils.isEmpty(Settings.getInstance().getDeviceToken()))
			addHeader("Authorization", "Mahabharata " + Settings.getInstance().getDeviceToken());
	}

	@Override
	protected HttpRequest copy() {
		return new ComicsRequest(this);
	}
}
