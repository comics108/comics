package com.fulldome.mahabharata.server;

import android.annotation.SuppressLint;
import android.content.Context;
import android.provider.Settings;

import com.fulldome.mahabharata.model.Musics;
import com.fulldome.mahabharata.model.Quotes;
import com.fulldome.mahabharata.model.Seasons;
import com.fulldome.mahabharata.model.Subscriptions;
import com.fulldome.mahabharata.model.TokenModel;
import com.fulldome.mahabharata.model.puzzle.Puzzles;
import com.ironwaterstudio.server.Request;
import com.ironwaterstudio.server.listeners.OnCallListener;
import com.ironwaterstudio.utils.Utils;

import java.util.Date;

public final class DataService {
    // Get Seasons
    public static void getSeasons(final OnCallListener listener) {
        new ComicsRequest("api/Data/Seasons")
            .setResultClass(Seasons.class)
            .call(listener);
    }

    public static void getSubscriptions(final OnCallListener listener) {
        new ComicsRequest("api/Data/Subscriptions").setResultClass(Subscriptions.class).call(listener);
    }

    public static void getPuzzles(final OnCallListener listener) {
        new ComicsRequest("api/Data/Puzzles").setResultClass(Puzzles.class).call(listener);
    }

    public static void getQuotes(final OnCallListener listener) {
        new ComicsRequest("api/Data/Quotes").setResultClass(Quotes.class).call(listener);
    }

    public static void getMusics(final OnCallListener listener) {
        new ComicsRequest("api/Data/Music").setCache(Request.CACHE_SMART).setResultClass(Musics.class).call(listener);
    }

    @SuppressLint("HardwareIds")
    public static void updateDevice(final Context context, final OnCallListener listener) {
        final String deviceId = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
        new ComicsRequest("api/Auth/UpdateDevice")
            .buildParams("deviceId", deviceId, "localTime", Utils.toUnixTimeStamp(new Date()))
            .setResultClass(TokenModel.class)
            .call(listener);
    }

    public static void updatePushToken(final String token) {
        new ComicsRequest("api/Auth/UpdatePushToken").buildParams("token", token).call();
    }
}
