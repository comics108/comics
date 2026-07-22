package com.fulldome.mahabharata.adapters.holders;

import android.content.Intent;
import android.graphics.drawable.Drawable;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.appcompat.widget.AppCompatImageView;
import androidx.core.content.ContextCompat;
import androidx.vectordrawable.graphics.drawable.Animatable2Compat;
import androidx.vectordrawable.graphics.drawable.AnimatedVectorDrawableCompat;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.fragments.MusicsFragment;
import com.fulldome.mahabharata.model.DownloadInfo;
import com.fulldome.mahabharata.model.Music;
import com.fulldome.mahabharata.model.Settings;
import com.fulldome.mahabharata.screens.UiConstants;
import com.ironwaterstudio.adapters.BaseHolder;
import com.ironwaterstudio.controls.ImageViewEx;
import com.ironwaterstudio.controls.ProgressDrawable;

import java.util.List;

public class MusicHolder extends BaseHolder<Music> implements View.OnClickListener {
	private final TextView tvNumber;
	private final AppCompatImageView ivMusic;
	private final TextView tvName;
	private final TextView tvAuthor;
	private final ImageViewEx btnAction;
	private final MusicsFragment.GlobalInfo globalInfo;
	private boolean equalizerIsRunning = false;

	private Animatable2Compat.AnimationCallback animationCallback = new Animatable2Compat.AnimationCallback() {
		@Override
		public void onAnimationEnd(Drawable drawable) {
			super.onAnimationEnd(drawable);
			ivMusic.post(new Runnable() {
				@Override
				public void run() {
					getEqualizer().start();
				}
			});
		}
	};

	public MusicHolder(ViewGroup parent, MusicsFragment.GlobalInfo globalInfo) {
		super(R.layout.item_music, parent);
		this.globalInfo = globalInfo;
		tvNumber = itemView.findViewById(R.id.tv_number);
		ivMusic = itemView.findViewById(R.id.iv_music);
		tvName = itemView.findViewById(R.id.tv_name);
		tvAuthor = itemView.findViewById(R.id.tv_author);
		btnAction = itemView.findViewById(R.id.btn_action);
		ivMusic.setImageDrawable(AnimatedVectorDrawableCompat.create(getContext(), R.drawable.ic_equalizer));
		itemView.setOnClickListener(this);
		btnAction.setOnClickListener(this);
	}

	@Override
	public void update(Music item) {
		super.update(item);
		tvNumber.setText(String.valueOf(getAdapterPosition() + 1));
		tvName.setText(item.getName());
		tvAuthor.setText(item.getAuthor());
		updateAction();
		updateEqualizer();
	}

	@Override
	public void update(Music item, List<Object> payloads) {
		super.update(item, payloads);
		if (payloads.contains(UiConstants.Payload.UPDATE_ACTION))
			updateAction();
		if (payloads.contains(UiConstants.Payload.UPDATE_EQUALIZER))
			updateEqualizer();
	}

	private void updateEqualizer() {
		if (getModel() == null) {
			return;
		}

		tvNumber.setVisibility(globalInfo.getCurrent() != null && globalInfo.getCurrent().getId() == getModel().getId()
			? View.INVISIBLE
			: View.VISIBLE);
		ivMusic.setVisibility(tvNumber.getVisibility() != View.VISIBLE ? View.VISIBLE : View.GONE);
		if (globalInfo.getCurrent() == null || globalInfo.getSoundManager() == null ||
			globalInfo.getCurrent().getId() != getModel().getId()) {
			stopEqualizer();
			return;
		}

		if (globalInfo.getSoundManager().isPlaying() && !getEqualizer().isRunning()) {
			startEqualizer();
		} else if (!globalInfo.getSoundManager().isPlaying() && getEqualizer().isRunning()) {
			stopEqualizer();
		}
	}

	private void updateAction() {
		if (!Settings.getInstance().getMusicDownloadInfos().containsKey(getModel().getId())) {
			btnAction.setImageDrawable(ContextCompat.getDrawable(getContext(),
				getModel().isDownloaded(getContext()) ? R.drawable.icn_del : R.drawable.icn_download));
			return;
		}

		DownloadInfo info = Settings.getInstance().getMusicDownloadInfos().get(getModel().getId());
		ProgressDrawable progress = btnAction.getMainImageView().getDrawable() instanceof ProgressDrawable
			? (ProgressDrawable) btnAction.getMainImageView().getDrawable()
			: null;
		if (progress == null) {
			btnAction.setImageDrawable(
				progress = new ProgressDrawable(btnAction).setColorIds(R.color.yellow).setSize(18f).setStrokeWidth(2f));
		}
		progress.setProgress(info.getPercent() / 100f);
	}

	@Override
	public void onAttach() {
		super.onAttach();
		updateEqualizer();
	}

	@Override
	public void onDetach() {
		super.onDetach();
		if (ivMusic.getVisibility() == View.VISIBLE)
			stopEqualizer();
	}

	@Override
	public void onClick(View v) {
		Intent intent = new Intent(UiConstants.ACTION_MUSIC);
		Music.ActionType type = Music.ActionType.PLAY;
		if (v.getId() == R.id.btn_action) {
			type = getModel().isDownloaded(getContext()) ? Music.ActionType.DELETE : Music.ActionType.LOAD;
		}
		intent.putExtra(UiConstants.KEY_ACTION, type);
		intent.putExtra(UiConstants.KEY_DATA, getModel());
		getContext().sendBroadcast(intent);
	}

	private void startEqualizer() {
		if (equalizerIsRunning)
			return;

		getEqualizer().registerAnimationCallback(animationCallback);
		getEqualizer().start();
		equalizerIsRunning = true;
	}

	private void stopEqualizer() {
		if (!equalizerIsRunning)
			return;

		getEqualizer().clearAnimationCallbacks();
		getEqualizer().stop();
		equalizerIsRunning = false;
		ivMusic.setImageDrawable(AnimatedVectorDrawableCompat.create(getContext(), R.drawable.ic_equalizer));
	}

	private Animatable2Compat getEqualizer() {
		return (Animatable2Compat) ivMusic.getDrawable();
	}
}
