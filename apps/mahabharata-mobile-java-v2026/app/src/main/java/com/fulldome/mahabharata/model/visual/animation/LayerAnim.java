package com.fulldome.mahabharata.model.visual.animation;

import com.fulldome.mahabharata.model.LayerAnimTypeAdapter;
import com.fulldome.mahabharata.model.visual.Layer;
import com.google.gson.annotations.JsonAdapter;

@JsonAdapter(LayerAnimTypeAdapter.class)
public abstract class LayerAnim extends Anim {
	public LayerAnim interpolate(LayerAnim endAnim, int scrollOffset) {
		int scrollObject = scrollOffset - endAnim.getStart();
		int animHeight = endAnim.getEnd() - endAnim.getStart();
		float fraction = animHeight == 0 ? 1f : Math.min(1, Math.max(0, (float) scrollObject / (float) animHeight));
		return interpolate(endAnim, transformToCubic(fraction));
	}

	private float transformToCubic(float fraction) {
		return (--fraction) * fraction * fraction + 1;
	}

	protected abstract LayerAnim interpolate(LayerAnim endAnim, float fraction);

	public abstract void apply(Layer.ViewData data, int width, int height);
}
