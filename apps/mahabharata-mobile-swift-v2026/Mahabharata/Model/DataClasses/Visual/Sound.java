//package com.fulldome.mahabharata.model.visual;
//
//import android.animation.Animator;
//import android.animation.ValueAnimator;
//import android.content.Context;
//import android.media.AudioManager;
//import android.support.annotation.FloatRange;
//import android.support.v4.view.animation.FastOutSlowInInterpolator;
//
//import com.fulldome.mahabharata.model.ComicsDescriptor;
//import com.fulldome.mahabharata.model.visual.animation.SoundAnim;
//import com.ironwaterstudio.utils.SimpleAnimatorListener;
//import com.ironwaterstudio.utils.SoundManager;
//
//import java.util.ArrayList;

public class Sound {
	private static final FastOutSlowInInterpolator INTERPOLATOR = new FastOutSlowInInterpolator();


	private enum State {PLAYING, PAUSED, STOPPED;}

//	private String file;
//
//	private ArrayList<SoundAnim> animations;
	private transient SoundManager soundManager = null;

	private transient State state = State.STOPPED;
	private transient float oldVolume = 0f;
	private transient float newVolume = 1f;
	private transient float volume = 0f;
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
	private transient ValueAnimator.AnimatorListener volumeAnimatorListener = new SimpleAnimatorListener() {
		@Override
		public void onAnimationEnd(Animator animation) {
			super.onAnimationEnd(animation);
			if (volume == 0 && soundManager != null)
				stop(false);
		}
	};
	private transient final SoundManager.SoundListener listener = new SoundManager.SoundListener() {
		@Override
		public void onPlay(boolean isPlaying, int position) {

		}

		@Override
		public void onCompleted() {
			soundManager.playPause(false);
			state = State.STOPPED;
		}

		@Override
		public void onError() {

		}
	};

	public Sound() {
		volumeAnimator.addUpdateListener(volumeUpdateListener);
		volumeAnimator.addListener(volumeAnimatorListener);
		volumeAnimator.setDuration(3000);
		volumeAnimator.setInterpolator(INTERPOLATOR);
	}

	public String getFile() {
		return file;
	}

	public ArrayList<SoundAnim> getAnimations() {
		return animations;
	}

	public void prepare(Context context, ComicsDescriptor descriptor) {
		if (soundManager == null) {
			soundManager = new SoundManager(context, AudioManager.STREAM_MUSIC);
			soundManager.addSoundListener(listener);
			soundManager.setRequestFocus(false);
			soundManager.setReleaseAfterCompletion(false);
			soundManager.prepare(descriptor.getSound(getFile()));
		}
	}

	public void process(int scrollOffset, int previousScrollOffset, boolean skipPointSounds) {
		for (SoundAnim anim : getAnimations()) {
			if (anim.isPoint()) {
				if (!skipPointSounds && previousScrollOffset < scrollOffset && previousScrollOffset < anim.getStart() && scrollOffset >= anim.getStart())
					play(false, false);
				return;
			}
			if (scrollOffset < anim.getStart() || scrollOffset > anim.getEnd()) {
				stop(true);
				return;
			}
			if (!isPlaying()) {
				play(true, true);
				return;
			}
		}
	}

	public boolean isPlaying() {
		return soundManager != null && state == State.PLAYING;
	}

	public void play(boolean looping, boolean anim) {
		if (soundManager == null || state == State.PLAYING)
			return;
		state = State.PLAYING;
		soundManager.setLooping(looping);
		if (!soundManager.isPlaying())
			soundManager.seekTo(0);
		soundManager.playPause(true);
		if (anim)
			animateVolume(1f);
		else
			setVolume(1f);
	}

	public void resume() {
		if (soundManager == null || state != State.PAUSED)
			return;
		soundManager.playPause(true);
		state = State.PLAYING;
	}

	public void pause() {
		if (soundManager == null || state != State.PLAYING)
			return;
		state = State.PAUSED;
		soundManager.playPause(false);
	}

	public void stop(boolean anim) {
		if (soundManager == null || state == State.STOPPED)
			return;
		state = State.STOPPED;
		if (anim) {
			animateVolume(0f);
		} else {
			setVolume(0f);
			soundManager.playPause(false);
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
