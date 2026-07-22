package com.fulldome.mahabharata.model.visual.animation;

import com.fulldome.mahabharata.model.visual.Layer;

public class ScaleAnim extends LayerAnim {
	private float scaleX;
	private float scaleY;
	private float pivotX;
	private float pivotY;

	public ScaleAnim() {
	}

	public ScaleAnim(float scaleX, float scaleY, float pivotX, float pivotY) {
		this.scaleX = scaleX;
		this.scaleY = scaleY;
		this.pivotX = pivotX;
		this.pivotY = pivotY;
	}

	public float getScaleX() {
		return scaleX;
	}

	public float getScaleY() {
		return scaleY;
	}

	public float getPivotX() {
		return pivotX;
	}

	public float getPivotY() {
		return pivotY;
	}

	@Override
	protected ScaleAnim interpolate(LayerAnim endAnim, float fraction) {
		ScaleAnim end = (ScaleAnim) endAnim;
		return new ScaleAnim(Layer.FLOAT_EVALUATOR.evaluate(fraction, getScaleX(), end.getScaleX()),
				Layer.FLOAT_EVALUATOR.evaluate(fraction, getScaleY(), end.getScaleY()),
				Layer.FLOAT_EVALUATOR.evaluate(fraction, getPivotX(), end.getPivotX()),
				Layer.FLOAT_EVALUATOR.evaluate(fraction, getPivotY(), end.getPivotY()));
	}

	@Override
	public void apply(Layer.ViewData data, int width, int height) {
		data.getMatrix().postTranslate(-width * pivotX, -height * pivotY);
		data.getMatrix().postScale(scaleX, scaleY);
		data.getMatrix().postTranslate(width * pivotX, height * pivotY);
	}
}
