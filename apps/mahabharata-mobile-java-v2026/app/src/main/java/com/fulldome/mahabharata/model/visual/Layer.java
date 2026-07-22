package com.fulldome.mahabharata.model.visual;

import android.animation.FloatEvaluator;
import android.animation.IntEvaluator;
import android.graphics.Matrix;

import com.fulldome.mahabharata.model.Settings;
import com.fulldome.mahabharata.model.visual.animation.AlphaAnim;
import com.fulldome.mahabharata.model.visual.animation.LayerAnim;
import com.fulldome.mahabharata.model.visual.animation.RotateAnim;
import com.fulldome.mahabharata.model.visual.animation.ScaleAnim;
import com.fulldome.mahabharata.model.visual.animation.TranslateAnim;

import java.util.ArrayList;
import java.util.List;

public class Layer {
	private static final TranslateAnim DEFAULT_TRANSLATE = new TranslateAnim(0, 0);
	private static final RotateAnim DEFAULT_ROTATE = new RotateAnim(0f, 0.5f, 0.5f);
	private static final ScaleAnim DEFAULT_SCALE = new ScaleAnim(1f, 1f, 0.5f, 0.5f);
	private static final AlphaAnim DEFAULT_ALPHA = new AlphaAnim(1f);
	public static final FloatEvaluator FLOAT_EVALUATOR = new FloatEvaluator();
	public static final IntEvaluator INT_EVALUATOR = new IntEvaluator();

	private boolean preview;
	private ArrayList<Image> images;
	private ArrayList<LayerAnim> animations;

	private transient final ArrayList<TranslateAnim> translates = new ArrayList<>();
	private transient final ArrayList<RotateAnim> rotates = new ArrayList<>();
	private transient final ArrayList<ScaleAnim> scales = new ArrayList<>();
	private transient final ArrayList<AlphaAnim> alphas = new ArrayList<>();
	private transient ViewData viewData = new ViewData();
	private transient Matrix inverse = new Matrix();

	public void prepare() {
		for (LayerAnim anim : animations) {
			switch (anim.getType()) {
				case TRANSLATE:
					sortedAdd(translates, (TranslateAnim) anim);
					break;
				case ROTATE:
					sortedAdd(rotates, (RotateAnim) anim);
					break;
				case SCALE:
					sortedAdd(scales, (ScaleAnim) anim);
					break;
				case ALPHA:
					sortedAdd(alphas, (AlphaAnim) anim);
					break;
			}
		}
		animations = null;
	}

	public Matrix getMatrix() {
		return viewData.getMatrix();
	}

	public float getAlpha() {
		return viewData.getAlpha();
	}

	public Matrix getInverse() {
		return inverse;
	}

	public void buildInverse() {
		getMatrix().invert(inverse);
	}

	public boolean isPreview() {
		return preview;
	}

	public Image getImage() {
		if (images == null || images.isEmpty())
			return null;
		Image image = images.get(Settings.getInstance().getLanguage().ordinal());
		if (!image.isEmpty())
			return image;

		for (Image item : images) {
			if (!item.isEmpty())
				return item;
		}
		return null;
	}

	public String getPopup() {
		if (images == null || images.isEmpty())
			return null;
		Image image = images.get(Settings.getInstance().getLanguage().ordinal());
		if (image.hasPopup())
			return image.getPopup();

		for (Image item : images) {
			if (item.hasPopup())
				return item.getPopup();
		}
		return null;
	}

	public void buildMatrixAndAlpha(int scrollOffset) {
		if (getImage() == null)
			return;

		viewData.getMatrix().reset();
		applyAnimations(scales, DEFAULT_SCALE, scrollOffset);
		applyAnimations(rotates, DEFAULT_ROTATE, scrollOffset);
		applyAnimations(translates, DEFAULT_TRANSLATE, scrollOffset);
		applyAnimations(alphas, DEFAULT_ALPHA, scrollOffset);
	}

	private <T extends LayerAnim> void applyAnimations(List<T> list, T defaultValue, int scrollOffset) {
		T previousAnim = defaultValue;
		T currentAnim = null;
		for (T anim : list) {
			if (currentAnim != null)
				previousAnim = currentAnim;
			currentAnim = anim;
			if (scrollOffset < anim.getEnd())
				break;
		}
		if (currentAnim == null)
			currentAnim = defaultValue;
		Image image = getImage();
		previousAnim.interpolate(currentAnim, scrollOffset).apply(viewData, image.getWidth(), image.getHeight());
	}

	private static <T extends LayerAnim> void sortedAdd(ArrayList<T> list, T anim) {
		if (list.isEmpty()) {
			list.add(anim);
			return;
		}
		int index = 0;
		for (T item : list) {
			if (anim.getStart() >= item.getEnd())
				index++;
			else
				break;
		}
		list.add(index, anim);
	}

	public static class ViewData {
		private Matrix matrix = new Matrix();
		private float alpha = 1;

		public Matrix getMatrix() {
			return matrix;
		}

		public float getAlpha() {
			return alpha;
		}

		public void setAlpha(float alpha) {
			this.alpha = alpha;
		}
	}
}
