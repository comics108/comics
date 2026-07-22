package com.fulldome.mahabharata.screens;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.util.Log;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.viewpager.widget.ViewPager;

import com.fulldome.mahabharata.BuildConfig;
import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.adapters.MenuPagerAdapter;
import com.fulldome.mahabharata.fragments.LastEpisodesFragment;
import com.fulldome.mahabharata.fragments.SeasonsFragment;
import com.fulldome.mahabharata.model.Menu;
import com.fulldome.mahabharata.model.Seasons;
import com.fulldome.mahabharata.server.DataService;
import com.google.android.material.bottomsheet.BottomSheetBehavior;
import com.ironwaterstudio.server.Request;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.listeners.SimpleCallListener;
import com.ironwaterstudio.utils.FbUtils;
import com.ironwaterstudio.utils.Utils;

public class MenuActivity extends BaseActivity {
    public static final String ACTION_SEASONS_LOADED =
        "com.fulldome.mahabharata.screens.MenuActivity.ACTION_SEASONS_LOADED";
    public static final String ACTION_OPEN_SEASON = "com.fulldome.mahabharata.screens.MenuActivity.ACTION_OPEN_SEASON";

    private ViewPager viewPager;
    private MenuPagerAdapter adapter;
    private boolean seasonsLoaded;

    private LastEpisodesFragment lastEpisodesFragment;

    private final BroadcastReceiver openSeasonReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(final Context context, final Intent intent) {
            final int seasonId = intent.getIntExtra(UiConstants.KEY_SEASON_ID, -1);
            EpisodesActivity.show(context, seasonId, seasonsLoaded);
        }
    };

    private final SimpleCallListener loadDataCallListener = new SimpleCallListener() {
        @Override
        public void onSuccess(final ApiResult result) {
            super.onSuccess(result);
            final Seasons seasons = result.getData(Seasons.class);
            Seasons.getInstance().update(MenuActivity.this, seasons);
            seasonsLoaded = true;
            Intent intent = new Intent(ACTION_SEASONS_LOADED);
            intent.setPackage(BuildConfig.APPLICATION_ID);
            sendBroadcast(intent);

            if (isFinishing()) {
                return;
            }
            updateLastEpisodes();
            updateSeasonsViews();
        }

        @Override
        public void onError(final Request request, final ApiResult result) {
            super.onError(request, result);
            Log.println(Log.ERROR, "tag", result.getMsg());
        }
    };


    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_menu);

        viewPager = findViewById(R.id.vp_menu);
        adapter = new MenuPagerAdapter(getSupportFragmentManager());
        viewPager.setAdapter(adapter);
        viewPager.setCurrentItem(selectedMenu().ordinal());
        DataService.getSeasons(loadDataCallListener);
        lastEpisodesFragment =
            (LastEpisodesFragment) getSupportFragmentManager().findFragmentById(R.id.fcv_lastEpisodes);

        final View bottomSocialsSheet = findViewById(R.id.cl_social_bottom_sheet);
        final BottomSheetBehavior behavior = BottomSheetBehavior.from(bottomSocialsSheet);
        behavior.setDraggable(true);
        behavior.setPeekHeight(getResources().getDimensionPixelSize(R.dimen.height_peek_socials));
        behavior.addBottomSheetCallback(new BottomSheetBehavior.BottomSheetCallback() {
            @Override
            public void onStateChanged(@NonNull final View bottomSheet, final int newState) {
                viewPager.setPadding(0, 0, 0, newState == BottomSheetBehavior.STATE_EXPANDED
                    ? bottomSocialsSheet.getHeight()
                    : behavior.getPeekHeight());
            }

            @Override
            public void onSlide(@NonNull final View bottomSheet, final float slideOffset) {
            }
        });
        behavior.setState(BottomSheetBehavior.STATE_COLLAPSED);
        viewPager.setPadding(0, 0, 0, behavior.getPeekHeight());

        findViewById(R.id.iv_social_donate).setOnClickListener(
            v -> Utils.openUrl(this, getString(R.string.url_social_donate)));
        findViewById(R.id.iv_social_shop).setOnClickListener(
            v -> Utils.openUrl(this, getString(R.string.url_social_shop)));
        findViewById(R.id.iv_social_patreon).setOnClickListener(
            v -> Utils.openUrl(this, getString(R.string.url_social_patreon)));
        findViewById(R.id.iv_social_instagram).setOnClickListener(
            v -> Utils.openUrl(this, getString(R.string.url_social_instagram)));
        findViewById(R.id.iv_social_facebook).setOnClickListener(
            v -> Utils.openUrl(this, getString(R.string.url_social_facebook)));
        findViewById(R.id.iv_social_youtube).setOnClickListener(
            v -> Utils.openUrl(this, getString(R.string.url_social_youtube)));
    }

    private Menu selectedMenu() {
        return getIntent().hasExtra(UiConstants.KEY_TAB)
            ? (Menu) getIntent().getSerializableExtra(UiConstants.KEY_TAB)
            : Menu.COMICS;
    }

    @Override
    protected void onStart() {
        super.onStart();
        registerReceiver(openSeasonReceiver, new IntentFilter(ACTION_OPEN_SEASON));
        FbUtils.logActivity(getClass().getSimpleName());
    }

    @Override
    protected void onStop() {
        super.onStop();
        unregisterReceiver(openSeasonReceiver);
        Seasons.getInstance().save(this);
    }

    private void updateSeasonsViews() {
        final SeasonsFragment fragment = getSeasonsFragment();
        if (fragment != null) {
            fragment.updateAllViews();
        }
    }

    private void updateLastEpisodes() {
        lastEpisodesFragment.updateLastEpisodes();
    }

    @Nullable
    private SeasonsFragment getSeasonsFragment() {
        return (SeasonsFragment) getSupportFragmentManager()
            .findFragmentByTag(getFragmentTag(Menu.COMICS.ordinal()));
    }

//	@Nullable
//	private MusicsFragment getMusicsFragment() {
//		return (MusicsFragment) getSupportFragmentManager().findFragmentByTag(getFragmentTag(Menu.MUSICS.ordinal()));
//	}

    private String getFragmentTag(final int position) {
        return "android:switcher:" + viewPager.getId() + ":" + adapter.getItemId(position);
    }
}
