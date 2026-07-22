package com.ironwaterstudio.utils;

import android.content.Context;
import android.util.Log;

import com.fulldome.mahabharata.BuildConfig;
import com.google.firebase.analytics.FirebaseAnalytics;

public class FbUtils {
	private static Context context = null;

	public static void init(Context context) {
		FbUtils.context = context;
	}

	public static void logActivity(String name) {
		logEvent("screen", name);
	}

	public static void logEvent(String category, String action) {
		if (!BuildConfig.DEBUG)
			FirebaseAnalytics.getInstance(context).logEvent(category + "_" + action, null);
		else
			Log.d("Analytics", "Log Event: $name");
	}
}
