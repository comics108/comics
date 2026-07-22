package com.ironwaterstudio.utils;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.media.AudioManager;
import android.media.MediaPlayer;
import androidx.annotation.FloatRange;

import java.io.FileDescriptor;
import java.util.ArrayList;

public class SoundManager {
	private final AudioManager audioManager;
	private final ArrayList<SoundListener> listeners = new ArrayList<>();
	private final Context context;
	private final int streamType;
	private int position = 0;
	private boolean looping = false;
	private boolean requestFocus = true;
	private boolean playAfterPrepare = true;
	private boolean releaseAfterCompletion = true;
	private MediaPlayer mediaPlayer = null;
	private boolean prepared = false;
	private int lastError = 0;

	private MediaPlayer.OnPreparedListener preparedListener = new MediaPlayer.OnPreparedListener() {
		@Override
		public void onPrepared(MediaPlayer mp) {
			prepared = true;
			int result = AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
			if (requestFocus)
				result = audioManager.requestAudioFocus(focusChangeListener, streamType, AudioManager.AUDIOFOCUS_GAIN);
			if (playAfterPrepare && result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
				playPause(true);
			if (result != AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
				return;

			for (SoundListener listener : listeners)
				listener.onPrepare();
		}
	};

	private MediaPlayer.OnCompletionListener completionListener = new MediaPlayer.OnCompletionListener() {
		@Override
		public void onCompletion(MediaPlayer mp) {
			if (releaseAfterCompletion)
				release();
			for (SoundListener listener : listeners)
				listener.onCompleted();
		}
	};

	private MediaPlayer.OnErrorListener errorListener = new MediaPlayer.OnErrorListener() {
		@Override
		public boolean onError(MediaPlayer mp, int what, int extra) {
			lastError = extra;
			release();
			for (SoundListener listener : listeners)
				listener.onError();
			return true;
		}
	};

	private AudioManager.OnAudioFocusChangeListener focusChangeListener = new AudioManager.OnAudioFocusChangeListener() {
		private boolean paused = false;

		@Override
		public void onAudioFocusChange(int focusChange) {
			switch (focusChange) {
				case AudioManager.AUDIOFOCUS_GAIN:
					if (paused) {
						playPause(true);
						paused = false;
					}
					break;
				case AudioManager.AUDIOFOCUS_LOSS:
					release();
					break;
				case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT:
				case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK:
					if (isPlaying()) {
						playPause(false);
						paused = true;
					}
					break;
			}
		}
	};

	public SoundManager(Context context) {
		this(context, AudioManager.STREAM_MUSIC);
	}

	public SoundManager(Context context, int streamType) {
		audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
		this.context = context;
		this.streamType = streamType;
	}

	public int getLastError() {
		return lastError;
	}

	public void setPosition(int position) {
		this.position = position;
	}

	public void setLooping(boolean looping) {
		this.looping = looping;
		if (isInitialized())
			mediaPlayer.setLooping(looping);
	}

	public void setRequestFocus(boolean requestFocus) {
		this.requestFocus = requestFocus;
	}

	public void addSoundListener(SoundListener listener) {
		if (!listeners.contains(listener))
			listeners.add(listener);
	}

	public void removeSoundListener(SoundListener listener) {
		listeners.remove(listener);
	}

	public boolean isInitialized() {
		return mediaPlayer != null;
	}

	public boolean isPrepared() {
		return isInitialized() && prepared;
	}

	public boolean isReleaseAfterCompletion() {
		return releaseAfterCompletion;
	}

	public void setReleaseAfterCompletion(boolean releaseAfterCompletion) {
		this.releaseAfterCompletion = releaseAfterCompletion;
	}

	private void initPlayer() {
		mediaPlayer.setAudioStreamType(streamType);
		mediaPlayer.setOnPreparedListener(preparedListener);
		mediaPlayer.setOnCompletionListener(completionListener);
		mediaPlayer.setOnErrorListener(errorListener);
		mediaPlayer.setLooping(looping);
		mediaPlayer.prepareAsync();
		prepared = false;
	}

	public void play(int raw) {
		play(context.getResources().openRawResourceFd(raw));
	}

	public void play(String path) {
		prepareInternal(path, true);
	}

	public void prepare(String path) {
		prepareInternal(path, false);
	}

	private void prepareInternal(String path, boolean playAfterPrepare) {
		this.playAfterPrepare = playAfterPrepare;
		release();
		try {
			mediaPlayer = new MediaPlayer();
			mediaPlayer.setDataSource(path);
			initPlayer();
		} catch (Exception e) {
			e.printStackTrace();
			release();
		}
	}

	public void play(FileDescriptor file) {
		prepareInternal(file, true);
	}

	public void prepare(FileDescriptor file) {
		prepareInternal(file, false);
	}

	private void prepareInternal(FileDescriptor file, boolean playAfterPrepare) {
		this.playAfterPrepare = playAfterPrepare;
		release();
		try {
			mediaPlayer = new MediaPlayer();
			mediaPlayer.setDataSource(file);
			initPlayer();
		} catch (Exception e) {
			e.printStackTrace();
			release();
		}
	}

	public void play(AssetFileDescriptor file) {
		prepareInternal(file, true);
	}

	public void prepare(AssetFileDescriptor file) {
		prepareInternal(file, false);
	}

	private void prepareInternal(AssetFileDescriptor file, boolean playAfterPrepare) {
		this.playAfterPrepare = playAfterPrepare;
		release();
		try {
			mediaPlayer = new MediaPlayer();
			mediaPlayer.setDataSource(file.getFileDescriptor(), file.getStartOffset(), file.getLength());
			initPlayer();
		} catch (Exception e) {
			e.printStackTrace();
			release();
		}
	}

	public void playPause(boolean play) {
		if (mediaPlayer == null || play == mediaPlayer.isPlaying())
			return;

		if (play) {
			if (position > 0) {
				mediaPlayer.seekTo(position);
				position = 0;
			}
			mediaPlayer.start();
		} else {
			mediaPlayer.pause();
		}

		for (SoundListener listener : listeners)
			listener.onPlay(mediaPlayer.isPlaying(), mediaPlayer.getCurrentPosition());
	}

	public boolean isPlaying() {
		return mediaPlayer != null && mediaPlayer.isPlaying();
	}

	public void setVolume(@FloatRange(from = 0f, to = 1f) float leftVolume, @FloatRange(from = 0f, to = 1f) float rightVolume) {
		if (mediaPlayer == null)
			return;
		mediaPlayer.setVolume(leftVolume, rightVolume);
	}

	public int getCurrentPosition() {
		return isPrepared() ? mediaPlayer.getCurrentPosition() : 0;
	}

	public int getDuration() {
		return isPrepared() ? mediaPlayer.getDuration() : 0;
	}

	public void seekTo(int position) {
		if (mediaPlayer != null)
			mediaPlayer.seekTo(position);
		for (SoundListener listener : listeners)
			listener.onPlay(isPlaying(), position);
	}

	public void release() {
		if (mediaPlayer != null) {
			mediaPlayer.release();
			mediaPlayer = null;
			audioManager.abandonAudioFocus(focusChangeListener);
		}
	}

	public interface SoundListener {
		void onPrepare();

		void onPlay(boolean isPlaying, int position);

		void onCompleted();

		void onError();
	}
}
