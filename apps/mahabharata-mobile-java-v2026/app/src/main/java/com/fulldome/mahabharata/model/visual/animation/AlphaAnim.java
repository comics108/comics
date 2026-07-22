package com.fulldome.mahabharata.model.visual.animation;

import androidx.annotation.FloatRange;

import com.fulldome.mahabharata.model.visual.Layer;

public class AlphaAnim extends LayerAnim {
	private float alpha;

	public AlphaAnim() {
	}

	public AlphaAnim(@FloatRange(from = 0f, to = 1f) float alpha) {
		this.alpha = alpha;
	}

	@FloatRange(from = 0f, to = 1f)
	public float getAlpha() {
		return alpha;
	}

	@Override
	protected AlphaAnim interpolate(LayerAnim endAnim, float fraction) {
		AlphaAnim end = (AlphaAnim) endAnim;
		return new AlphaAnim(Layer.FLOAT_EVALUATOR.evaluate(fraction, getAlpha(), end.getAlpha()));
	}

	@Override
	public void apply(Layer.ViewData data, int width, int height) {
		data.setAlpha(alpha);
	}
}
