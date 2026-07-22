package com.fulldome.mahabharata.model.visual;

import android.content.Context;

import com.fulldome.mahabharata.model.BaseState;
import com.fulldome.mahabharata.model.ComicsDescriptor;
import com.fulldome.mahabharata.model.Settings;
import com.fulldome.mahabharata.utils.AnalyticsEvents;
import com.fulldome.mahabharata.utils.ImageManager;
import com.ironwaterstudio.server.serializers.JsonSerializer;
import com.ironwaterstudio.server.serializers.Serializer;
import com.ironwaterstudio.utils.FileUtils;
import com.ironwaterstudio.utils.FbUtils;

import java.util.ArrayList;

public class Comics {
	private int width;
	private int height;
	private ArrayList<Layer> layers;
	private ArrayList<Sound> sounds;
	private transient ComicsDescriptor descriptor = null;
	private transient int sampleSize = -1;
	private transient int previousScrollOffset = -1;
	private transient boolean skipPointSounds = false;

	public int getWidth() {
		return width;
	}

	public int getHeight() {
		return height;
	}

	public ArrayList<Layer> getLayers() {
		return layers;
	}

	public ArrayList<Sound> getSounds() {
		return sounds;
	}

	public ComicsDescriptor getDescriptor() {
		return descriptor;
	}

	public int getSampleSize() {
		return sampleSize;
	}

	public boolean isSkipPointSounds() {
		return skipPointSounds;
	}

	public void setSkipPointSounds(boolean skipPointSounds) {
		this.skipPointSounds = skipPointSounds;
	}

	public void prepare(Context context, ComicsDescriptor descriptor) {
		this.descriptor = descriptor;
		sampleSize = computeSampleSize(context);
		for (Layer layer : getLayers())
			layer.prepare();
		for (Sound sound : getSounds())
			sound.prepare(context, getDescriptor());
	}

	public void release() {
		for (Sound sound : sounds)
			sound.release();
	}

	public void process(int scrollOffset) {
		for (Layer layer : getLayers())
			layer.buildMatrixAndAlpha(scrollOffset);
		if (Settings.getInstance().isSoundOn()) {
			for (Sound sound : getSounds())
				sound.process(scrollOffset, previousScrollOffset, skipPointSounds);
		}
		previousScrollOffset = scrollOffset;
	}

	public void cancelLayerTasks() {
		for (Layer layer : layers)
			ImageManager.cancel(getDescriptor(), layer.getImage().getFile(ComicsDescriptor.ImageType.LAYER));
	}

	public boolean hasPreview() {
		for (Layer layer : layers) {
			if (layer.isPreview())
				return true;
		}
		return false;
	}

	private int computeSampleSize(Context context) {
		int size = getWidth() / context.getResources().getDisplayMetrics().widthPixels;
		int oldValue = 1;
		for (int i = 1; i <= 5; i++) {
			int value = (int) Math.pow(2, i);
			if (size < value)
				return oldValue;
			oldValue = value;
		}
		return oldValue;
	}

	public void toggleSounds() {
		toggleSoundsSettings();
		updateSoundsState();
	}

	public void updateSoundsState() {
		if (Settings.getInstance().isSoundOn())
			resumeSoundsInternal();
		else
			pauseSoundsInternal();
	}

	public void pauseSounds() {
		if (Settings.getInstance().isSoundOn())
			pauseSoundsInternal();
	}

	public void resumeSounds() {
		if (Settings.getInstance().isSoundOn())
			resumeSoundsInternal();
	}

	private void pauseSoundsInternal() {
		for (Sound audio : getSounds())
			audio.pause();
	}

	private void resumeSoundsInternal() {
		for (Sound audio : getSounds())
			audio.resume();
	}

	public static void toggleSoundsSettings() {
		Settings.getInstance().setSoundOn(!Settings.getInstance().isSoundOn());
		Settings.getInstance().save();
		FbUtils.logEvent(AnalyticsEvents.CATEGORY_SOUNDS, AnalyticsEvents.ACTION_POWER + " " + (Settings.getInstance().isSoundOn() ? "on" : "off"));
	}

	public static Comics create(Context context, BaseState state) {
		ComicsDescriptor descriptor = state != null && state.isDownloaded() ? ComicsDescriptor.create(state.getSavedFile(context)) : null;
		if (descriptor == null)
			return null;
		Comics comics = Serializer.get(JsonSerializer.class).read(FileUtils.readStream(descriptor.getData()), Comics.class);
		if (comics != null)
			comics.prepare(context, descriptor);
		return comics;
	}
}
