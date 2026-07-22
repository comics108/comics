package com.fulldome.mahabharata.model.visual.animation;

import com.fulldome.mahabharata.model.visual.Layer;

public class TranslateAnim extends LayerAnim {
	private int x;
	private int y;

	public TranslateAnim() {
	}

	public TranslateAnim(int x, int y) {
		this.x = x;
		this.y = y;
	}

	public int getX() {
		return x;
	}

	public int getY() {
		return y;
	}

	@Override
	public TranslateAnim interpolate(LayerAnim endAnim, float fraction) {
		TranslateAnim end = (TranslateAnim) endAnim;
		return new TranslateAnim(Layer.INT_EVALUATOR.evaluate(fraction, getX(), end.getX()), Layer.INT_EVALUATOR.evaluate(fraction, getY(), end.getY()));
	}

	@Override
	public void apply(Layer.ViewData data, int width, int height) {
		data.getMatrix().postTranslate(x, y);
	}
}
