package com.fulldome.mahabharata.screens;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.Toolbar;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.dialogs.ShareDialog;
import com.fulldome.mahabharata.fragments.SeasonFragment;
import com.fulldome.mahabharata.model.Episode;
import com.fulldome.mahabharata.model.Season;
import com.fulldome.mahabharata.model.Seasons;
import com.fulldome.mahabharata.utils.AnalyticsEvents;
import com.fulldome.mahabharata.utils.Constants;
import com.ironwaterstudio.dialogs.AlertFragment;
import com.ironwaterstudio.utils.FbUtils;
import com.ironwaterstudio.utils.Utils;

import java.io.Serializable;

public class EpisodesActivity extends BaseActivity {
    public static final int REQ_COMICS = 5;
    private static final int REQ_SUBS = 6;
    private static final String ACTION_COMICS = "com.fulldome.mahabharata.screens.MenuActivity.comics";

    public enum Action implements Serializable {OPEN, SHARE, UPDATE, DELETE}

    private Toolbar toolbar;
    private SeasonFragment fragment;
    private boolean seasonsLoaded;
    private final Handler handler = new Handler();
    private final BroadcastReceiver seasonsLoadedReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(final Context context, final Intent intent) {
            final Season season = Seasons.getInstance().getSeason(getSeasonId());
            if (season == null) {
                finish();
                return;
            }
            seasonsLoaded = true;
            fragment.updateViews();
        }
    };

    private final BroadcastReceiver actionsComicsReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(final Context context, final Intent intent) {
            final int episodeId = intent.getIntExtra(UiConstants.KEY_EPISODE_ID, -1);
            final Episode episode = Seasons.getInstance().getEpisode(episodeId);
            if (episode == null) {
                return;
            }
            switch ((Action) intent.getSerializableExtra(UiConstants.KEY_ACTION)) {
                case OPEN:
                    openComics(episode);
                    break;
                case SHARE:
                    ShareDialog.show(EpisodesActivity.this, episodeId);
                    break;
                case UPDATE:
                    updateComics(episode);
                    break;
                case DELETE:
                    deleteComics(episode);
                    break;
            }
        }
    };

    private final View.OnClickListener subsClickListener =
        view -> Utils.openUrl(EpisodesActivity.this, "http://mahabharata.pro/subscribe");

    @Override
    protected void onCreate(@Nullable final Bundle inState) {
        super.onCreate(inState);
        seasonsLoaded = inState != null
            ? inState.getBoolean(UiConstants.KEY_LOADED)
            : getIntent().getBooleanExtra(UiConstants.KEY_LOADED, seasonsLoaded);
        setContentView(R.layout.activity_episodes);
        toolbar = findViewById(R.id.toolbar);

        toolbar.setTitle(getSeason().getBookName());
        toolbar.setSubtitle(getSeason().getBookNumber());
        toolbar.setNavigationOnClickListener(view -> finish());

        if (inState == null) {
            fragment = SeasonFragment.newInstance(getSeasonId());
            getSupportFragmentManager().beginTransaction().add(R.id.container, fragment).commit();
        } else {
            fragment = (SeasonFragment) getSupportFragmentManager().findFragmentById(R.id.container);
        }
    }

    protected void onUpdateViewStates() {
        fragment.updateStates();
    }

    @Override
    protected void onSaveInstanceState(@NonNull final Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putBoolean(UiConstants.KEY_LOADED, seasonsLoaded);
    }

    @Override
    protected void onActivityResult(final int requestCode, final int resultCode, final Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode == RESULT_OK && requestCode == REQ_COMICS) {
            if (!fragment.goToNextEpisode()) {
                final int index = Seasons.getInstance().indexOf(getSeason());
                if (index >= 0 && index < Seasons.getInstance().size()) {
                    EpisodesActivity.show(this, Seasons.getInstance().get(index + 1).getId(), seasonsLoaded);
                    finish();
                }
            }
        }
        if (resultCode == RESULT_OK && requestCode == REQ_SUBS) {
            fragment.updateStates();
        }
    }

    @Override
    protected void onStart() {
        super.onStart();
        registerReceiver(actionsComicsReceiver, new IntentFilter(ACTION_COMICS));
        registerReceiver(seasonsLoadedReceiver, new IntentFilter(MenuActivity.ACTION_SEASONS_LOADED));
        queryDownloads();
        FbUtils.logActivity(getClass().getSimpleName());
    }

    @Override
    protected void onStop() {
        super.onStop();
        unregisterReceiver(seasonsLoadedReceiver);
        unregisterReceiver(actionsComicsReceiver);
        handler.removeCallbacksAndMessages(null);
        Seasons.getInstance().save(this);
    }

    private void queryDownloads() {
        handler.removeCallbacksAndMessages(null);
        if (!Seasons.getInstance().queryDownloads(this)) {
            fragment.updateStates();
            return;
        }

        Seasons.getInstance().save(this);
        fragment.updateStates();
        handler.postDelayed(this::queryDownloads, Constants.QUERY_INTERVAL);
    }

    private void openComics(final Episode episode) {
        if (!episode.isDownloaded() && episode.getDownloadInfo() == null) {
            FbUtils.logEvent(AnalyticsEvents.CATEGORY_EPISODE,
                AnalyticsEvents.ACTION_DOWNLOAD + " " + episode.getName());
            episode.download(this);
            Seasons.getInstance().save(this);
            queryDownloads();
        } else if (episode.isDownloaded()) {
            ComicsActivity.show(this, episode.getId(), REQ_COMICS);
        }
    }

    private void updateComics(final Episode episode) {
        FbUtils.logEvent(AnalyticsEvents.CATEGORY_EPISODE, AnalyticsEvents.ACTION_UPDATE + " "
            + episode.getName() + " version from: " + episode.getLoadedVersion() + " to: " + episode.getVersion());
        episode.delete(this);
        episode.download(this);
        Seasons.getInstance().save(this);
        queryDownloads();
    }

    private void deleteComics(final Episode episode) {
        AlertFragment.create()
            .setMessage(R.string.delete_episode)
            .setPositiveText(R.string.yes)
            .setPositiveListener(
                (dialogInterface, i) -> {
                    FbUtils.logEvent(AnalyticsEvents.CATEGORY_EPISODE,
                        AnalyticsEvents.ACTION_DELETE + " " + episode.getName());
                    episode.delete(EpisodesActivity.this);
                    Seasons.getInstance().save(EpisodesActivity.this);
                    fragment.updateStates();
                })
            .setNegativeText(R.string.no)
            .setNegativeListener((dialogInterface, i) -> dialogInterface.dismiss())
            .show(this);
    }

    private Season getSeason() {
        return Seasons.getInstance().getSeason(getSeasonId());
    }

    public int getSeasonId() {
        return getIntent().getIntExtra(UiConstants.KEY_SEASON_ID, -1);
    }

    public static void emitComicsEvent(final Context context, final int episodeId, final Action action) {
        context.sendBroadcast(new Intent(ACTION_COMICS).putExtra(UiConstants.KEY_EPISODE_ID, episodeId)
            .putExtra(UiConstants.KEY_ACTION, action));
    }

    public static void show(final Context context, final int seasonId, final boolean seasonsLoaded) {
        final Intent intent = new Intent(context, EpisodesActivity.class);
        intent.putExtra(UiConstants.KEY_SEASON_ID, seasonId);
        intent.putExtra(UiConstants.KEY_LOADED, seasonsLoaded);
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        context.startActivity(intent);
    }
}
