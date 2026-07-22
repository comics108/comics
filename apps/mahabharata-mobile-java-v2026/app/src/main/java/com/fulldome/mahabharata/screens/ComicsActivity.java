package com.fulldome.mahabharata.screens;

import android.app.Activity;
import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Point;
import android.os.Bundle;
import androidx.annotation.IdRes;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import android.text.TextUtils;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.RadioGroup;
import android.widget.TextView;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.controls.LayersView;
import com.fulldome.mahabharata.controls.SoundBadge;
import com.fulldome.mahabharata.controls.ZoomFrameLayout;
import com.fulldome.mahabharata.model.Episode;
import com.fulldome.mahabharata.model.Language;
import com.fulldome.mahabharata.model.Seasons;
import com.fulldome.mahabharata.model.Settings;
import com.fulldome.mahabharata.model.visual.Comics;
import com.fulldome.mahabharata.utils.AnalyticsEvents;
import com.ironwaterstudio.controls.ImageViewEx;
import com.ironwaterstudio.controls.RadioButtonEx;
import com.ironwaterstudio.dialogs.AlertFragment;
import com.ironwaterstudio.server.ActionRequest;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.listeners.CallListener;
import com.ironwaterstudio.utils.FbUtils;

public class ComicsActivity extends AppCompatActivity {
	private boolean hasRead = false;
	private ZoomFrameLayout zoomLayout;
	private LayersView layersView;
	private View vFooter;
	private RadioGroup rgLanguage;
	private TextView tvChapter;
	private TextView tvName;
	private SoundBadge soundBadge;
	private ImageViewEx ivNextPoster;
	private TextView tvNextChapter;
	private TextView tvNextName;
	private TextView tvSoon;
	private TextView tvNextState;
	private Comics comics = null;

	private BroadcastReceiver completeDownloadReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			Long downloadId = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, 0);
			Episode downloadedEpisode = Seasons.getInstance().getEpisode(downloadId);
			Episode nextEpisode = getNextEpisode();
			if (downloadedEpisode != null && nextEpisode != null && downloadedEpisode.getId() == nextEpisode.getId())
				tvNextState.setText(R.string.read);
		}
	};

	private CallListener initDescriptorListener = new CallListener(this) {
		@Override
		public void onSuccess(ApiResult result) {
			super.onSuccess(result);
			initComics(result.getData(Comics.class));
		}
	};

	private final ActionRequest.Runnable initDescriptorRunnable = new ActionRequest.Runnable() {
		@Override
		public Object run() {
			return ApiResult.fromObject(Comics.create(ComicsActivity.this, getEpisode()));
		}
	};

	private GestureDetector.SimpleOnGestureListener gestureListener = new GestureDetector.SimpleOnGestureListener() {
		@Override
		public boolean onSingleTapConfirmed(MotionEvent e) {
			if (comics == null)
				return super.onSingleTapConfirmed(e);

			comics.toggleSounds();
			zoomLayout.invalidateAll();
			soundBadge.show(Settings.getInstance().isSoundOn());
			return super.onSingleTapConfirmed(e);
		}
	};

	private View.OnClickListener nextEpisodeClickListener = new View.OnClickListener() {
		@Override
		public void onClick(View view) {
			FbUtils.logEvent(AnalyticsEvents.CATEGORY_EPISODE, AnalyticsEvents.ACTION_GO_TO_NEXT + " " + getEpisode().getName());
			setResult(RESULT_OK);
			finish();
		}
	};

	private final RadioGroup.OnCheckedChangeListener languageChangeListener = new RadioGroup.OnCheckedChangeListener() {
		@Override
		public void onCheckedChanged(RadioGroup radioGroup, @IdRes int id) {
			int index = radioGroup.indexOfChild(radioGroup.findViewById(id));
			Settings.getInstance().setLanguage(Language.values()[index]);
			Settings.getInstance().save();
			comics.cancelLayerTasks();
			if (layersView != null)
				layersView.reloadLayers();
			postInvalidateAll();
			FbUtils.logEvent(AnalyticsEvents.CATEGORY_LANGUAGE, AnalyticsEvents.ACTION_CHANGE_TO + " " + Settings.getInstance().getLanguage());
		}
	};

	private final ZoomFrameLayout.OnScrollListener scrollListener = new ZoomFrameLayout.OnScrollListener() {
		@Override
		public void onScroll(int contentWidth, int contentHeight, int scrollX, int scrollY, int extendedX, int extendedY) {
			if (!hasRead && scrollY + extendedY == contentHeight) {
				FbUtils.logEvent(AnalyticsEvents.CATEGORY_EPISODE, getEpisode().getName() + " " + AnalyticsEvents.ACTION_HAS_READ);
				hasRead = true;
			}
		}
	};

	@Override
	protected void onCreate(@Nullable Bundle inState) {
		super.onCreate(inState);
		setContentView(R.layout.activity_comics);
		zoomLayout = findViewById(R.id.zoom_layout);
		vFooter = findViewById(R.id.v_footer);
		rgLanguage = findViewById(R.id.rg_language);
		tvChapter = findViewById(R.id.tv_chapter);
		tvName = findViewById(R.id.tv_name);
		soundBadge = findViewById(R.id.sound_badge);
		ivNextPoster = findViewById(R.id.iv_next_poster);
		tvNextChapter = findViewById(R.id.tv_next_chapter);
		tvNextName = findViewById(R.id.tv_next_name);
		tvSoon = findViewById(R.id.tv_soon);
		tvNextState = findViewById(R.id.tv_next_state);

		for (Language language : Language.values()) {
			RadioButtonEx button = (RadioButtonEx) getLayoutInflater().inflate(R.layout.item_language_button, rgLanguage, false);
			button.setId(language.getResId());
			button.setText(language.getResId());
			button.setFont(language.getFont());
			rgLanguage.addView(button);
		}
		vFooter.setOnClickListener(nextEpisodeClickListener);
		rgLanguage.check(Settings.getInstance().getLanguage().getResId());
		rgLanguage.setOnCheckedChangeListener(languageChangeListener);
		tvChapter.setText(getString(R.string.episode_template, getEpisode().getOrder()));
		tvName.setText(getEpisode().getName());

		zoomLayout.setGestureListener(gestureListener);
		zoomLayout.setScrollListener(scrollListener);
		initDescriptorListener.register();
		new ActionRequest(initDescriptorRunnable).call(initDescriptorListener);
		FbUtils.logEvent(AnalyticsEvents.CATEGORY_EPISODE, AnalyticsEvents.ACTION_OPEN + " " + getEpisode().getName());
	}

	@Override
	protected void onStart() {
		super.onStart();
		registerReceiver(completeDownloadReceiver, new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE));
		if (comics != null)
			comics.resumeSounds();
		FbUtils.logActivity(getClass().getSimpleName());
	}

	@Override
	protected void onStop() {
		super.onStop();
		unregisterReceiver(completeDownloadReceiver);
		getEpisode().setCurrentScroll(zoomLayout.getCurrentScrollY());
		FbUtils.logEvent(AnalyticsEvents.CATEGORY_EPISODE, AnalyticsEvents.ACTION_EXIT + " on scroll " + zoomLayout.getCurrentScrollY());
		if (comics != null)
			comics.pauseSounds();
		Seasons.getInstance().save(this);
	}

	@Override
	protected void onDestroy() {
		super.onDestroy();
		if (comics != null)
			comics.release();
	}

	public void invalidateAll() {
		zoomLayout.invalidateAll();
	}

	public void postInvalidateAll() {
		zoomLayout.post(new Runnable() {
			@Override
			public void run() {
				invalidateAll();
			}
		});
	}

	public void initComics(Comics comics) {
		this.comics = comics;
		initNextEpisodePoster();
		zoomLayout.setContentSize(comics.getWidth(), comics.getHeight());
		FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(comics.getWidth(), comics.getHeight());
		zoomLayout.addView(layersView = new LayersView(zoomLayout.getContext(), comics, new Point(0, getResources().getDisplayMetrics().heightPixels), false), 0, params);
		invalidateAll();
		postInvalidateAll();

		final int lastScroll = getEpisode().getCurrentScroll();
		if (lastScroll <= 0)
			return;
		AlertFragment.create().setMessage(R.string.continue_from_last_position).setPositiveText(R.string.yes).setPositiveListener(new DialogInterface.OnClickListener() {
			@Override
			public void onClick(DialogInterface dialogInterface, int i) {
				ComicsActivity.this.comics.setSkipPointSounds(true);
				zoomLayout.translate(0, lastScroll * zoomLayout.getScale());
				ComicsActivity.this.comics.setSkipPointSounds(false);
			}
		}).setNegativeText(R.string.no).setNegativeListener(new DialogInterface.OnClickListener() {
			@Override
			public void onClick(DialogInterface dialogInterface, int i) {
				dialogInterface.dismiss();
			}
		}).show(this);
	}

	private void initNextEpisodePoster() {
		Episode nextEpisode = getNextEpisode();
		vFooter.setVisibility(nextEpisode != null ? View.VISIBLE : View.GONE);
		if (nextEpisode == null)
			return;
		ivNextPoster.setImage(nextEpisode.getImage());
		tvNextChapter.setText(getString(R.string.episode_template, nextEpisode.getOrder()));
		tvNextName.setText(nextEpisode.getName());
		tvNextState.setVisibility(nextEpisode.hasComics() ? View.VISIBLE : View.GONE);
		tvSoon.setVisibility(nextEpisode.hasComics() ? View.GONE : View.VISIBLE);
		String state = nextEpisode.getStatusText(this);
		tvNextState.setText(TextUtils.isEmpty(state) ? getString(R.string.loading) : state);
	}

	private Episode getEpisode() {
		return Seasons.getInstance().getEpisode(getEpisodeId());
	}

	private int getEpisodeId() {
		return getIntent().getIntExtra(UiConstants.KEY_EPISODE_ID, -1);
	}

	private Episode getNextEpisode() {
		return Seasons.getInstance().getNextEpisode(getEpisodeId());
	}

	public static void show(Activity activity, int episodeId, int reqCode) {
		Intent intent = new Intent(activity, ComicsActivity.class);
		intent.putExtra(UiConstants.KEY_EPISODE_ID, episodeId);
		activity.startActivityForResult(intent, reqCode);
	}
}
