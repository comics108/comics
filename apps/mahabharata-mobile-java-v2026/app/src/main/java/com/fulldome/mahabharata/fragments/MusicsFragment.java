package com.fulldome.mahabharata.fragments;

import android.annotation.SuppressLint;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.drawable.ClipDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.LayerDrawable;
import android.graphics.drawable.ShapeDrawable;
import android.graphics.drawable.shapes.RectShape;
import android.media.AudioManager;
import android.os.Bundle;
import android.os.Handler;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.constraintlayout.widget.Group;
import androidx.fragment.app.Fragment;
import androidx.core.content.ContextCompat;
import androidx.appcompat.widget.AppCompatSeekBar;
import androidx.recyclerview.widget.RecyclerView;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.adapters.MusicsAdapter;
import com.fulldome.mahabharata.decorations.DividerDecoration;
import com.fulldome.mahabharata.model.Music;
import com.fulldome.mahabharata.model.Musics;
import com.fulldome.mahabharata.screens.UiConstants;
import com.fulldome.mahabharata.server.DataService;
import com.ironwaterstudio.controls.ImageViewEx;
import com.ironwaterstudio.dialogs.AlertFragment;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.listeners.CallListener;
import com.ironwaterstudio.utils.SoundManager;
import com.ironwaterstudio.utils.UiHelper;

public class MusicsFragment extends Fragment implements View.OnClickListener {
	private static final int QUERY_INTERVAL = 1000;

	private RecyclerView rvItems;
	private MusicsAdapter adapter;
	private Group groupPlayer;
	private AppCompatSeekBar seekBar;
	private ImageViewEx btnPrevious;
	private ImageViewEx btnPlay;
	private ImageViewEx btnNext;

	private int progressHeight = -1;
	private final Handler handler = new Handler();
	private SoundManager soundManager = null;
	private Music current = null;
	private Runnable queryDownloadRunnable = null;
	private Integer goToPosition = null;
	private GlobalInfo globalInfo = new GlobalInfo() {
		@Override
		public Music getCurrent() {
			return current;
		}

		@Override
		public SoundManager getSoundManager() {
			return soundManager;
		}
	};

	private BroadcastReceiver actionReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			Music music = (Music) intent.getSerializableExtra(UiConstants.KEY_DATA);
			switch ((Music.ActionType) intent.getSerializableExtra(UiConstants.KEY_ACTION)) {
				case PLAY:
					playMusic(music);
					break;
				case LOAD:
					downloadMusic(music);
					break;
				case DELETE:
					deleteMusic(music);
					break;
			}
		}
	};

	private BroadcastReceiver fileActionsReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			Music music = (Music) intent.getSerializableExtra(UiConstants.KEY_DATA);
			Music.FileActionType type = (Music.FileActionType) intent.getSerializableExtra(UiConstants.KEY_ACTION);
			switch (type) {
				case DELETE:
					if (current == null || !isMusicReady() || music.getId() != current.getId())
						break;

					goToPosition = soundManager.getCurrentPosition();
					pauseMusic();
			}
		}
	};

	private CallListener getMusicsCallListener = new CallListener(this, false) {
		@Override
		protected void onSuccess(ApiResult result) {
			super.onSuccess(result);
			adapter.animateTo(result.getData(Musics.class));
			queryDownloads();
		}
	};

	private Runnable musicProgressUpdater = new Runnable() {
		@Override
		public void run() {
			if (isMusicReady()) {
				seekBar.setMax(soundManager.getDuration());
				seekBar.setProgress(soundManager.getCurrentPosition());
			}
			handler.postDelayed(musicProgressUpdater, 500);
		}
	};

	private SoundManager.SoundListener soundListener = new SoundManager.SoundListener() {
		private boolean transaction = false;

		@Override
		public void onPrepare() {

		}

		@Override
		public void onPlay(boolean isPlaying, int position) {
			if (transaction)
				return;

			transaction = true;
			if (goToPosition != null) {
				soundManager.seekTo(goToPosition);
				goToPosition = null;
			}
			if (isPlaying)
				musicProgressUpdater.run();
			else
				handler.removeCallbacks(musicProgressUpdater);
			updatePlayerView();
			transaction = false;
		}

		@Override
		public void onCompleted() {
			if (current == null) {
				soundManager.playPause(false);
				return;
			}
			int index = adapter.indexOf(current.getId());
			if (index == -1 || index >= adapter.getItems().size() - 1) {
				pauseMusic();
				return;
			}
			playMusic(adapter.getItem(index + 1));
		}

		@Override
		public void onError() {
			handler.removeCallbacks(musicProgressUpdater);
			if (soundManager.getLastError() == -1005)
				UiHelper.showSnackbar(getActivity(), R.string.error_connection);
		}
	};

	private View.OnTouchListener seekBarTouchListener = new View.OnTouchListener() {
		@SuppressLint("ClickableViewAccessibility")
		@Override
		public boolean onTouch(View v, MotionEvent event) {
			switch (event.getAction()) {
				case MotionEvent.ACTION_DOWN:
					handler.removeCallbacks(musicProgressUpdater);
					break;
				case MotionEvent.ACTION_CANCEL:
				case MotionEvent.ACTION_UP:
					seekBar.post(new Runnable() {
						@Override
						public void run() {
							if (isMusicReady())
								soundManager.seekTo(seekBar.getProgress());
						}
					});
					break;
			}
			return false;
		}
	};

	@Nullable
	@Override
	public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
		View v = inflater.inflate(R.layout.fragment_musics, container, false);
		rvItems = v.findViewById(R.id.rv_items);
		groupPlayer = v.findViewById(R.id.group_player);
		seekBar = v.findViewById(R.id.seek_bar);
		btnPrevious = v.findViewById(R.id.btn_previous);
		btnPlay = v.findViewById(R.id.btn_play);
		btnNext = v.findViewById(R.id.btn_next);
		return v;
	}

	@Override
	public void onActivityCreated(@Nullable Bundle inState) {
		super.onActivityCreated(inState);
		if (adapter == null)
			adapter = new MusicsAdapter(getContext(), globalInfo);
		rvItems.setAdapter(adapter);
		rvItems.setItemViewCacheSize(10);
		rvItems.addItemDecoration(new DividerDecoration(getContext(), R.color.yellow_10, R.dimen.divider_size, UiHelper.dpToPx(getContext(), 18), DividerDecoration.MIDDLE | DividerDecoration.BOTTOM));
		seekBar.setOnTouchListener(seekBarTouchListener);
		seekBar.addOnLayoutChangeListener(new View.OnLayoutChangeListener() {
			@Override
			public void onLayoutChange(View v, int left, int top, int right, int bottom, int oldLeft, int oldTop, int oldRight, int oldBottom) {
				if (progressHeight == -1) {
					progressHeight = seekBar.getProgressDrawable().getIntrinsicHeight() > 0 ? seekBar.getProgressDrawable().getIntrinsicHeight() : seekBar.getHeight();
					seekBar.setProgressDrawable(buildProgress());
					if (isMusicReady()) {
						seekBar.setMax(soundManager.getDuration());
						seekBar.setProgress(0);
						seekBar.setProgress(soundManager.getCurrentPosition());
					}
					ConstraintLayout.LayoutParams params = (ConstraintLayout.LayoutParams) rvItems.getLayoutParams();
					params.bottomMargin = seekBar.getHeight() / 2;
					rvItems.requestLayout();
				} else {
					recompute((LayerDrawable) seekBar.getProgressDrawable());
				}
			}
		});
		btnPrevious.setOnClickListener(this);
		btnPlay.setOnClickListener(this);
		btnNext.setOnClickListener(this);
		getMusicsCallListener.register();
		DataService.getMusics(getMusicsCallListener);
	}

	@SuppressWarnings("ConstantConditions")
	@Override
	public void onResume() {
		super.onResume();
		getActivity().registerReceiver(actionReceiver, new IntentFilter(UiConstants.ACTION_MUSIC));
		getActivity().registerReceiver(fileActionsReceiver, new IntentFilter(UiConstants.ACTION_FILE));
		if (isMusicPlaying())
			musicProgressUpdater.run();
		queryDownloads();
		updatePlayerView();
	}

	@SuppressWarnings("ConstantConditions")
	@Override
	public void onPause() {
		super.onPause();
		if (queryDownloadRunnable != null)
			handler.removeCallbacks(queryDownloadRunnable);
		queryDownloadRunnable = null;
		handler.removeCallbacks(musicProgressUpdater);
		getActivity().unregisterReceiver(fileActionsReceiver);
		getActivity().unregisterReceiver(actionReceiver);
	}

	@Override
	public void onDestroy() {
		if (soundManager != null) {
			soundManager.release();
			soundManager = null;
		}
		super.onDestroy();
	}

	@Override
	public void onClick(View v) {
		switch (v.getId()) {
			case R.id.btn_play:
				if (current == null && soundManager == null)
					return;

				if (soundManager.isPlaying())
					pauseMusic();
				else
					playMusic(current);
				updatePlayerView();
				break;
			case R.id.btn_previous:
				if (current == null)
					break;
				int index = adapter.indexOf(current.getId());
				if (index > 0)
					playMusic(adapter.getItem(index - 1));
				break;
			case R.id.btn_next:
				if (current == null)
					break;
				int index2 = adapter.indexOf(current.getId());
				if (index2 < adapter.getItems().size() - 1)
					playMusic(adapter.getItem(index2 + 1));
				break;
		}
	}

	private Drawable buildProgress() {
		ShapeDrawable background = new ShapeDrawable(new RectShape());
		background.getPaint().setColor(ContextCompat.getColor(getContext(), R.color.yellow_22));
		ShapeDrawable progress = new ShapeDrawable(new RectShape());
		progress.getPaint().setColor(ContextCompat.getColor(getContext(), R.color.yellow));
		LayerDrawable layer = new LayerDrawable(new Drawable[]{background, new ClipDrawable(progress, Gravity.LEFT | Gravity.CENTER_VERTICAL, ClipDrawable.HORIZONTAL)});
		recompute(layer);
		return layer;
	}

	private void recompute(LayerDrawable layer) {
		int horizontal = UiHelper.dpToPx(getContext(), -7);
		int vertical = (progressHeight - UiHelper.dpToPx(getContext(), 2)) / 2;
		layer.setLayerInset(0, horizontal, vertical, horizontal, vertical);
		layer.setLayerInset(1, horizontal, vertical, horizontal, vertical);
	}

	public void onDeactivate() {
		progressHeight = -1;
		if (isMusicPlaying())
			soundManager.playPause(false);
	}

	private boolean isMusicPlaying() {
		return isMusicReady() && soundManager.isPlaying();
	}

	private boolean isMusicReady() {
		return soundManager != null && soundManager.isInitialized() && soundManager.isPrepared();
	}

	private void queryDownloads() {
		if (queryDownloadRunnable != null)
			handler.removeCallbacks(queryDownloadRunnable);
		if (!Musics.queryDownloads(getContext(), adapter.getItems()))
			return;

		adapter.notifyItemRangeChanged(0, adapter.getItemCount(), UiConstants.Payload.UPDATE_ACTION);
		handler.postDelayed(queryDownloadRunnable = new Runnable() {
			@Override
			public void run() {
				queryDownloadRunnable = null;
				queryDownloads();
			}
		}, QUERY_INTERVAL);
	}

	private void playMusic(Music music) {
		if (getContext() == null)
			return;

		int oldMusic = -1;
		if (goToPosition == null && current != null && current.getId() == music.getId()) {
			if (!soundManager.isPlaying())
				soundManager.playPause(true);
			updatePlayerView();
			return;
		} else if (current != null) {
			oldMusic = adapter.indexOf(current.getId());
		}
		current = music;
		if (soundManager == null) {
			soundManager = new SoundManager(getContext(), AudioManager.STREAM_MUSIC);
			soundManager.addSoundListener(soundListener);
			soundManager.setRequestFocus(true);
			soundManager.setReleaseAfterCompletion(false);
		}
		soundManager.play(music.getPreferSavedFilePath(getContext()));
		if (oldMusic != -1)
			adapter.notifyItemChanged(oldMusic, UiConstants.Payload.UPDATE_EQUALIZER);
		updatePlayerView();
	}

	private void pauseMusic() {
		soundManager.playPause(false);
		updatePlayerView();
	}

	private void downloadMusic(Music music) {
		music.download(getContext());
		queryDownloads();
	}

	private void deleteMusic(final Music music) {
		AlertFragment.create().setMessage(R.string.delete_music).setPositiveText(R.string.yes).setPositiveListener(new DialogInterface.OnClickListener() {
			@Override
			public void onClick(DialogInterface dialog, int which) {
				music.delete(getContext());
				int index = adapter.indexOf(music.getId());
				if (index != -1)
					adapter.notifyItemChanged(index, UiConstants.Payload.UPDATE_ACTION);
			}
		}).setNegativeText(R.string.no).setNegativeListener(new DialogInterface.OnClickListener() {
			@Override
			public void onClick(DialogInterface dialog, int which) {
				dialog.dismiss();
			}
		}).show(getActivity());
	}

	private void updatePlayerView() {
		groupPlayer.setVisibility(soundManager != null ? View.VISIBLE : View.GONE);
		if (soundManager == null)
			return;

		seekBar.setMax(soundManager.getDuration());
		seekBar.setProgress(soundManager.getCurrentPosition());
		btnPlay.setImageDrawable(ContextCompat.getDrawable(getContext(), soundManager.isPlaying() ? R.drawable.icn_pause : R.drawable.icn_play));
		if (current != null) {
			int index = adapter.indexOf(current.getId());
			if (index != -1) {
				adapter.notifyItemChanged(index, UiConstants.Payload.UPDATE_EQUALIZER);
				btnPrevious.setClickable(index > 0);
				btnNext.setClickable(index < adapter.getItems().size() - 1);
				btnPrevious.setAlpha(btnPrevious.isClickable() ? 1f : 0.5f);
				btnNext.setAlpha(btnNext.isClickable() ? 1f : 0.5f);
			}
		}
	}

	public interface GlobalInfo {
		Music getCurrent();

		SoundManager getSoundManager();
	}
}
