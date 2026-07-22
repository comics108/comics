package com.fulldome.mahabharata.model.visual.animation;

import android.support.annotation.FloatRange;

import com.fulldome.mahabharata.model.visual.Layer;

public class RotateAnim extends LayerAnim {
	private float angle;
	private float pivotX;
	private float pivotY;

	public RotateAnim() {
	}

	public RotateAnim(float angle, float pivotX, float pivotY) {
		this.angle = angle;
		this.pivotX = pivotX;
		this.pivotY = pivotY;
	}

	@FloatRange(from = 0f, to = 360f)
	public float getAngle() {
		return angle;
	}

	@FloatRange(from = 0f, to = 1f)
	public float getPivotX() {
		return pivotX;
	}

	@FloatRange(from = 0f, to = 1f)
	public float getPivotY() {
		return pivotY;
	}

	@Override
	protected RotateAnim interpolate(LayerAnim endAnim, float fraction) {
		RotateAnim end = (RotateAnim) endAnim;
		return new RotateAnim(Layer.FLOAT_EVALUATOR.evaluate(fraction, getAngle(), end.getAngle()),
				Layer.FLOAT_EVALUATOR.evaluate(fraction, getPivotX(), end.getPivotX()),
				Layer.FLOAT_EVALUATOR.evaluate(fraction, getPivotY(), end.getPivotY()));
	}

	@Override
	public void apply(Layer.ViewData data, int width, int height) {
		data.getMatrix().postTranslate(-width * pivotX, -height * pivotY);
		data.getMatrix().postRotate(angle);
		data.getMatrix().postTranslate(width * pivotX, height * pivotY);
	}
}
