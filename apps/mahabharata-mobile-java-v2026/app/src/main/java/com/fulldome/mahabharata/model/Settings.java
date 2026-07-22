package com.fulldome.mahabharata.model;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;

import com.ironwaterstudio.server.serializers.JsonSerializer;
import com.ironwaterstudio.server.serializers.Serializer;

import java.util.Locale;

public class Settings {
	private static Settings instance = null;

	private static final String PERSISTENCE_NAME = "Settings";
	private static final String KEY_LANGUAGE = "language";
	private static final String KEY_SOUND_ON = "soundOn";
	private static final String KEY_SUBSCRIBED = "subscribed";
	private static final String KEY_DEVICE_TOKEN = "deviceToken";
	private static final String KEY_MUSIC_DOWNLOAD_INFOS = "musicDownloadInfos";

	private SharedPreferences sharedPrefs = null;
	private Language language = Locale.getDefault().getLanguage().toLowerCase().equals("ru") ? Language.RU : Language.EN;
	private boolean soundOn = true;
	private boolean subscribed = false;
	private String deviceToken = null;
	private DownloadInfoMap musicDownloadInfos = new DownloadInfoMap();

	public static Settings getInstance() {
		return instance;
	}

	public static void initInstance(Context context) {
		if (instance == null)
			instance = new Settings(context);
	}

	private Settings(Context context) {
		sharedPrefs = context.getSharedPreferences(PERSISTENCE_NAME, Activity.MODE_PRIVATE);
		load();
	}

	private void load() {
		language = load(KEY_LANGUAGE, Language.class, language);
		soundOn = sharedPrefs.getBoolean(KEY_SOUND_ON, soundOn);
		subscribed = sharedPrefs.getBoolean(KEY_SUBSCRIBED, subscribed);
		deviceToken = sharedPrefs.getString(KEY_DEVICE_TOKEN, deviceToken);
		musicDownloadInfos = load(KEY_MUSIC_DOWNLOAD_INFOS, DownloadInfoMap.class, musicDownloadInfos);
	}

	private <T> T load(String key, Class<T> cls, T defValue) {
		String str = sharedPrefs.getString(key, null);
		T result = Serializer.get(JsonSerializer.class).read(str, cls);
		if (result == null)
			result = defValue;
		return result;
	}

	public void save() {
		SharedPreferences.Editor editor = sharedPrefs.edit();
		editor.putString(KEY_LANGUAGE, Serializer.get(JsonSerializer.class).write(language));
		editor.putBoolean(KEY_SOUND_ON, soundOn);
		editor.putBoolean(KEY_SUBSCRIBED, subscribed);
		editor.putString(KEY_DEVICE_TOKEN, deviceToken);
		editor.putString(KEY_MUSIC_DOWNLOAD_INFOS, Serializer.get(JsonSerializer.class).write(musicDownloadInfos));
		editor.apply();
	}

	public Language getLanguage() {
		return language;
	}

	public void setLanguage(Language language) {
		this.language = language;
	}

	public boolean isSoundOn() {
		return soundOn;
	}

	public void setSoundOn(boolean soundOn) {
		this.soundOn = soundOn;
	}

	public boolean isSubscribed() {
		return subscribed;
	}

	public void setSubscribed(boolean subscribed) {
		this.subscribed = subscribed;
	}

	public String getDeviceToken() {
		return deviceToken;
	}

	public void setDeviceToken(String deviceToken) {
		this.deviceToken = deviceToken;
	}

	public DownloadInfoMap getMusicDownloadInfos() {
		return musicDownloadInfos;
	}
}
