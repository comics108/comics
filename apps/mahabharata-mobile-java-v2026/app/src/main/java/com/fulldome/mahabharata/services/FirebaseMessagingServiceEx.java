package com.fulldome.mahabharata.services;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.text.TextUtils;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.model.PushType;
import com.fulldome.mahabharata.screens.MenuActivity;
import com.fulldome.mahabharata.screens.UiConstants;
import com.fulldome.mahabharata.server.DataService;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

public class FirebaseMessagingServiceEx extends FirebaseMessagingService {
	private static final String KEY_TITLE = "title";
	private static final String KEY_TEXT = "text";
	private static final String KEY_TYPE = "type";
	public static final String ANDROID_CHANNEL_ID = "com.fulldome.mahabharata";

	@Override
	public void onNewToken(@NonNull String token) {
		super.onNewToken(token);
		DataService.updatePushToken(token);
	}

	@Override
	public void onMessageReceived(RemoteMessage remoteMessage) {
		if (remoteMessage.getData().size() > 0)
			sendNotification(remoteMessage.getData().get(KEY_TITLE), remoteMessage.getData().get(KEY_TEXT), PushType.parse(remoteMessage.getData().get(KEY_TYPE)));
	}

	@SuppressWarnings("ConstantConditions")
	private void sendNotification(String title, String message, PushType type) {
		if (TextUtils.isEmpty(message))
			return;

		NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
		Intent intent = new Intent(this, MenuActivity.class);
		intent.putExtra(UiConstants.KEY_TAB, type.getMenu());
		intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NEW_TASK);
		PendingIntent contentIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_ONE_SHOT);

		createChannelIfNeeded(manager);
		NotificationCompat.Builder builder = new NotificationCompat.Builder(this, ANDROID_CHANNEL_ID)
				.setContentIntent(contentIntent)
				.setSmallIcon(R.drawable.icon_splash)
				.setContentTitle(title)
				.setContentText(message)
				.setTicker(message)
				.setDefaults(Notification.DEFAULT_ALL)
				.setAutoCancel(true);
		try {
			manager.notify(type.ordinal(), builder.build());
		} catch (Exception e) {
			// On some devices it can throw java.lang.SecurityException: Requires VIBRATE permission
			e.printStackTrace();
		}
	}

	private void createChannelIfNeeded(NotificationManager manager) {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O)
			return;

		NotificationChannel channel = manager.getNotificationChannel(ANDROID_CHANNEL_ID);
		if (channel == null) {
			channel = new NotificationChannel(ANDROID_CHANNEL_ID, getString(R.string.app_name), NotificationManager.IMPORTANCE_DEFAULT);
			manager.createNotificationChannel(channel);
		}
	}
}
