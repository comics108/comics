package com.fulldome.mahabharata;

import android.content.Context;
import android.content.res.Configuration;

import androidx.multidex.MultiDex;
import androidx.multidex.MultiDexApplication;

import com.facebook.appevents.AppEventsLogger;
import com.fulldome.mahabharata.model.Seasons;
import com.fulldome.mahabharata.model.Settings;
import com.fulldome.mahabharata.model.puzzle.Puzzles;
import com.ironwaterstudio.server.http.HttpHelper;
import com.ironwaterstudio.utils.FbUtils;
import com.ironwaterstudio.utils.Utils;

import java.util.Arrays;
import java.util.List;

public class ApplicationEx extends MultiDexApplication {
	public static final String BASE64_PUBLIC_KEY = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7iMlcxD4fkznmN1iZK/saZT2bNw37GdimdpVktuGZrjBaNOKF/z6RU/CL5myTNIh+sLNvr7wpjw3Oz9Sx107LrT82dW/oQdxswvNJlpUZ2szTyR/NnRT0EMF0VxUzGYSNTLpkojyXc87jK4fxLx0Zp+/Dmk7vCzHAE/YrV27gAvdSA5BPMKEEW8pJPcKBl5y1bTEkY30+0gHWwqhg4T/P+xuzbekHklBhiKEL4b7GcgvRXlqfxFYwDgFDP8BUupobksq7B8rPjvapQAxN8n4Qegout65I6mF+5kAcZmspHtXz2mHEAoHVKMdhUciCUmezizgSwFEBrDlgZyojCFv5QIDAQAB";
	private static final List<String> LANGUAGES = Arrays.asList("en", "ru");

	@Override
	public void onCreate() {
		super.onCreate();
		HttpHelper.init(this);
		Utils.setLocale(this, LANGUAGES);
		Settings.initInstance(this);
		Seasons.init(this);
		Puzzles.init(this);
		FbUtils.init(this);
		AppEventsLogger.activateApp(this);
	}

	@Override
	public void onConfigurationChanged(Configuration newConfig) {
		super.onConfigurationChanged(newConfig);
		Utils.setLocale(this, LANGUAGES);
	}

	@Override
	public void attachBaseContext(Context base) {
		super.attachBaseContext(base);
		MultiDex.install(this);
	}
}
