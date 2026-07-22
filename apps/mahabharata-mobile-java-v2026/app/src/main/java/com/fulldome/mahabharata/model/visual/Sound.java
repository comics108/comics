package com.fulldome.mahabharata.model.visual;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ValueAnimator;
import android.content.Context;
import android.media.AudioManager;
import androidx.annotation.FloatRange;
import androidx.interpolator.view.animation.FastOutSlowInInterpolator;

import com.fulldome.mahabharata.model.ComicsDescriptor;
import com.fulldome.mahabharata.model.visual.animation.SoundAnim;
import com.ironwaterstudio.utils.SoundManager;

import java.util.ArrayList;

public class Sound {
	private static final FastOutSlowInInterpolator INTERPOLATOR = new FastOutSlowInInterpolator();

	private String file;
	private ArrayList<SoundAnim> animations;

	private transient SoundManager soundManager = null;
	private transient float oldVolume = 0f;
	private transient float newVolume = 1f;
	private transient float volume = 0f;
	private transient boolean looping = false;
	private transient ComicsDescriptor descriptor;
	private transient ValueAnimator volumeAnimator = ValueAnimator.ofFloat(0f, 1f);
	private transient ValueAnimator.AnimatorUpdateListener volumeUpdateListener = new ValueAnimator.AnimatorUpdateListener() {
		private float oldValue = -1;

		@Override
		public void onAnimationUpdate(ValueAnimator valueAnimator) {
			if (soundManager == null)
				return;

			float value = (float) valueAnimator.getAnimatedValue();
			if (oldValue == value)
				return;

			oldValue = value;
			setVolume(Layer.FLOAT_EVALUATOR.evaluate(value, oldVolume, newVolume));
		}
	};
	private transient ValueAnimator.AnimatorListener volumeAnimatorListener = new AnimatorListenerAdapter() {
		@Override
		public void onAnimationEnd(Animator animation) {
			super.onAnimationEnd(animation);
			if (volume == 0 && soundManager != null)
				stop(false);
		}
	};
	private transient final SoundManager.SoundListener listener = new SoundManager.SoundListener() {
		@Override
		public void onPrepare() {
			playInternal();
		}

		@Override
		public void onPlay(boolean isPlaying, int position) {

		}

		@Override
		public void onCompleted() {
		}

		@Override
		public void onError() {
		}
	};

	public Sound() {
		volumeAnimator.addUpdateListener(volumeUpdateListener);
		volumeAnimator.addListener(volumeAnimatorListener);
		volumeAnimator.setDuration(600);
		volumeAnimator.setInterpolator(INTERPOLATOR);
	}

	public String getFile() {
		return file;
	}

	public ArrayList<SoundAnim> getAnimations() {
		return animations;
	}

	public void prepare(Context context, ComicsDescriptor descriptor) {
		this.descriptor = descriptor;
		if (soundManager == null) {
			soundManager = new SoundManager(context, AudioManager.STREAM_MUSIC);
			soundManager.addSoundListener(listener);
			soundManager.setRequestFocus(false);
		}
	}

	public void process(int scrollOffset, int previousScrollOffset, boolean skipPointSounds) {
		for (SoundAnim anim : getAnimations()) {
			if (anim.isPoint()) {
				if (!skipPointSounds && previousScrollOffset < scrollOffset && previousScrollOffset < anim.getStart() && scrollOffset >= anim.getStart())
					play(false);
				return;
			}
			if (scrollOffset >= anim.getStart() && scrollOffset <= anim.getEnd()) {
				if (!isPlaying())
					play(true);
				return;
			}
		}
		stop(true);
	}

	public boolean isPlaying() {
		return soundManager != null && soundManager.isPrepared() && soundManager.isPlaying();
	}

	public void play(boolean looping) {
		this.looping = looping;
		if (!isPlaying())
			soundManager.prepare(descriptor.getSound(getFile()));
	}

	private void playInternal() {
		soundManager.setLooping(looping);
		if (!soundManager.isPlaying())
			soundManager.seekTo(0);
		soundManager.playPause(true);
		if (looping)
			animateVolume(1f);
		else
			setVolume(1f);
	}

	public void resume() {
		if (soundManager != null)
			soundManager.addSoundListener(listener);
		if (soundManager != null && soundManager.isPrepared() && !soundManager.isPlaying())
			soundManager.playPause(true);
	}

	public void pause() {
		if (isPlaying())
			soundManager.playPause(false);
		if (soundManager != null)
			soundManager.removeSoundListener(listener);
	}

	public void stop(boolean anim) {
		if (!isPlaying()) {
			if (soundManager != null && soundManager.isInitialized())
				soundManager.release();
			return;
		}

		if (anim) {
			animateVolume(0f);
		} else {
			setVolume(0f);
			soundManager.playPause(false);
			soundManager.release();
		}
	}

	private void animateVolume(@FloatRange(from = 0f, to = 1f) float volume) {
		if (soundManager == null)
			return;

		soundManager.setVolume(this.volume, this.volume);
		oldVolume = this.volume;
		newVolume = volume;
		volumeAnimator.start();
	}

	private void setVolume(@FloatRange(from = 0f, to = 1f) float volume) {
		if (soundManager == null)
			return;

		this.volume = volume;
		soundManager.setVolume(this.volume, this.volume);
	}

	public void release() {
		if (soundManager != null) {
			soundManager.release();
			soundManager = null;
		}
	}
}
