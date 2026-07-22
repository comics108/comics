package com.fulldome.mahabharata.controls;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ValueAnimator;
import android.content.Context;
import android.graphics.Point;
import android.graphics.Rect;
import android.graphics.RectF;
import android.support.annotation.NonNull;
import android.view.View;
import android.view.animation.AccelerateDecelerateInterpolator;
import android.view.animation.Transformation;
import android.widget.FrameLayout;

import com.fulldome.mahabharata.model.ComicsDescriptor;
import com.fulldome.mahabharata.model.visual.Comics;
import com.fulldome.mahabharata.model.visual.Layer;

import java.util.HashSet;
import java.util.Set;

public class LayersView extends FrameLayout implements ZoomFrameLayout.ZoomableView {
	private Comics comics = null;
	private RectF transformedRect = new RectF();
	private boolean init = false;
	private final Point preloadOffset = new Point();
	private final boolean zoomEnabled;

	public LayersView(@NonNull Context context, Comics comics) {
		this(context, comics, new Point(), true);
	}

	public LayersView(@NonNull Context context, Comics comics, Point preloadOffset, boolean zoomEnabled) {
		super(context);
		this.zoomEnabled = zoomEnabled;
		this.preloadOffset.set(preloadOffset.x, preloadOffset.y);
		setClipChildren(false);
		setStaticTransformationsEnabled(true);
		this.comics = comics;
		initLayers();
	}

	public Comics getComics() {
		return comics;
	}

	public void setComics(Comics comics) {
		this.comics = comics;
		initLayers();
	}

	@Override
	public void onUpdate(float scale, int scrollX, int scrollY, int extendedX, int extendedY) {
		if (getComics() != null)
			getComics().process(scrollY);
		for (int i = 0; i < getChildCount(); i++) {
			View view = getChildAt(i);
			if (view instanceof ZoomFrameLayout.ZoomableView)
				((ZoomFrameLayout.ZoomableView) view).onUpdate(scale, (int) (scrollX - getX()), (int) (scrollY - getY()), getWidth(), getHeight());
			view.invalidate();
		}
	}

	@Override
	public boolean getChildVisibleRect(View child, Rect rect, Point offset) {
		boolean isLayer = child.getTag() instanceof Layer;
		if (isLayer) {
			Layer layer = (Layer) child.getTag();
			transformedRect.set(rect);
			layer.getMatrix().mapRect(transformedRect);
			transformedRect.round(rect);
			layer.buildInverse();
		} else {
			rect.offset((int) child.getX(), (int) child.getY());
		}
		rect.offset((int) getX(), (int) getY());
		boolean visible = getParent() == null || getParent().getChildVisibleRect(child, rect, offset);
		if (!visible)
			return false;
		rect.offset((int) -getX(), (int) -getY());
		if (isLayer) {
			Layer layer = (Layer) child.getTag();
			transformedRect.set(rect);
			layer.getInverse().mapRect(transformedRect);
			transformedRect.round(rect);
		} else {
			rect.offset((int) -child.getX(), (int) -child.getY());
		}
		return !rect.isEmpty();
	}

	@Override
	protected boolean getChildStaticTransformation(View child, Transformation t) {
		if (child.getTag() instanceof Layer) {
			Layer layer = (Layer) child.getTag();
			t.getMatrix().set(layer.getMatrix());
			t.setAlpha(layer.getAlpha());
			return true;
		}
		return false;
	}

	public void reloadLayers() {
		removeLayers();
		initLayers();
	}

	public void removeLayers() {
		init = false;
		for (int i = 0; i < getChildCount(); i++) {
			View view = getChildAt(i);
			if (view instanceof TileImageView)
				removeView(view);
		}
	}

	protected boolean needShowPreview() {
		return false;
	}

	private boolean contains(Layer layer) {
		for (int i = 0; i < getChildCount(); i++) {
			if (getChildAt(i) instanceof TileImageView && getChildAt(i).getTag() == layer)
				return true;
		}
		return false;
	}

	public void initLayers() {
		if (getComics() == null) {
			removeLayers();
			return;
		}
		if (init)
			return;
		init = true;
		for (Layer layer : getComics().getLayers()) {
			if (layer.isPreview() != needShowPreview())
				continue;
			FrameLayout.LayoutParams params = new LayoutParams(layer.getImage().getWidth(), layer.getImage().getHeight());
			TileImageView view = new TileImageView(getContext(), getComics().getDescriptor(), getComics().getSampleSize(), layer.getImage().getFile(ComicsDescriptor.ImageType.LAYER), zoomEnabled);
			view.setPreloadOffset(preloadOffset);
			view.setTag(layer);
			addView(view, params);
		}
	}

	public void animateReloadLayers() {
		if (getComics() == null) {
			removeLayers();
			return;
		}
		final Set<View> animViews = new HashSet<>();
		for (Layer layer : getComics().getLayers()) {
			if (layer.isPreview() != needShowPreview() || contains(layer))
				continue;
			FrameLayout.LayoutParams params = new LayoutParams(layer.getImage().getWidth(), layer.getImage().getHeight());
			TileImageView view = new TileImageView(getContext(), getComics().getDescriptor(), getComics().getSampleSize(), layer.getImage().getFile(ComicsDescriptor.ImageType.LAYER), zoomEnabled);
			view.setPreloadOffset(preloadOffset);
			view.setTag(layer);
			view.setVisibility(INVISIBLE);
			animViews.add(view);
			addView(view, params);
		}
		ValueAnimator animator = ValueAnimator.ofFloat(0, 1);
		animator.setDuration(200);
		animator.setInterpolator(new AccelerateDecelerateInterpolator());
		animator.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
			@Override
			public void onAnimationUpdate(ValueAnimator animation) {
				float value = (float) animation.getAnimatedValue();
				for (View view : animViews)
					view.setAlpha(value);
			}
		});
		animator.addListener(new AnimatorListenerAdapter() {
			@Override
			public void onAnimationStart(Animator animation) {
				super.onAnimationStart(animation);
				for (View view : animViews)
					view.setVisibility(VISIBLE);
			}

			@Override
			public void onAnimationEnd(Animator animation) {
				super.onAnimationEnd(animation);
				init = true;
				int i = 0;
				while (i < getChildCount()) {
					View view = getChildAt(i);
					if (view instanceof TileImageView && view.getTag() instanceof Layer && ((Layer) view.getTag()).isPreview() != needShowPreview())
						removeView(view);
					else
						i++;
				}
			}
		});
		animator.start();
	}
}
