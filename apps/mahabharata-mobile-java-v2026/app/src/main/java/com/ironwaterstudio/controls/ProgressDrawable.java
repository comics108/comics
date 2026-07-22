package com.ironwaterstudio.controls;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.PropertyValuesHolder;
import android.animation.ValueAnimator;
import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.ColorFilter;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.drawable.Animatable;
import android.graphics.drawable.Drawable;
import androidx.annotation.ColorInt;
import androidx.annotation.ColorRes;
import androidx.annotation.Dimension;
import androidx.annotation.FloatRange;
import androidx.annotation.NonNull;
import androidx.annotation.Px;
import androidx.core.content.ContextCompat;
import androidx.core.content.res.TypedArrayUtils;
import androidx.interpolator.view.animation.FastOutSlowInInterpolator;
import android.view.View;
import android.view.animation.LinearInterpolator;

import com.fulldome.mahabharata.R;
import com.ironwaterstudio.utils.UiHelper;

import java.util.ArrayList;

public class ProgressDrawable extends Drawable implements Animatable, View.OnAttachStateChangeListener {
	private static final int FULL_CIRCLE = 360;
	private static final int START_OFFSET = 270;
	private static final int MIN_LENGTH = 5;

	private final Paint paint = new Paint();
	private final Paint paintBack = new Paint();
	private final RectF rect = new RectF();
	private final Rect clipRect = new Rect();
	private final View parent;

	private ArrayList<Integer> colors = new ArrayList<>();
	private int currentColorIndex = 0;
	private int sizePx;
	private int strokeWidthPx;
	private float progress = 0;
	private float tailAngle;
	private float headAngle;
	private float rotateAngle;
	private AnimationController controller = null;
	private boolean drawBackCircle = false;
	private boolean startAfterAppear = false;

	private final float tailAngleDefault;
	private final float headAngleDefault;
	private final float rotateAngleDefault;

	public ProgressDrawable(@NonNull View parent) {
		this(parent, 270, 450, 45);
	}

	@SuppressLint("RestrictedApi")
	public ProgressDrawable(@NonNull View parent, float tailAngleDefault, float headAngleDefault, float rotateAngleDefault) {
		this.parent = parent;
		this.tailAngleDefault = tailAngleDefault;
		this.headAngleDefault = headAngleDefault;
		this.rotateAngleDefault = rotateAngleDefault;
		setInitState();
		sizePx = UiHelper.dpToPx(getContext(), 30);
		strokeWidthPx = UiHelper.dpToPx(parent.getContext(), 3);
		setColorIds(TypedArrayUtils.getResourceId(parent.getContext().obtainStyledAttributes(new int[]{R.attr.colorPrimary}), 0, 0, 0));
		initPaint(paint);
		initPaint(paintBack);
		updatePaintColor();
		parent.addOnAttachStateChangeListener(this);
	}

	private Context getContext() {
		return parent.getContext();
	}

	public float getTailAngleDefault() {
		return tailAngleDefault;
	}

	public float getHeadAngleDefault() {
		return headAngleDefault;
	}

	public float getRotateAngleDefault() {
		return rotateAngleDefault;
	}

	public ProgressDrawable setSize(@Dimension(unit = Dimension.DP) float sizeDp) {
		return setSize(UiHelper.dpToPx(getContext(), sizeDp));
	}

	public ProgressDrawable setSize(@Px int sizePx) {
		this.sizePx = sizePx;
		invalidateSelf();
		return this;
	}

	public ProgressDrawable setStrokeWidth(@Dimension(unit = Dimension.DP) float widthDp) {
		return setStrokeWidth(UiHelper.dpToPx(getContext(), widthDp));
	}

	public int getStrokeWidth() {
		return strokeWidthPx;
	}

	@SuppressWarnings("WeakerAccess")
	public ProgressDrawable setStrokeWidth(@Px int widthPx) {
		this.strokeWidthPx = widthPx;
		initPaint(paint);
		initPaint(paintBack);
		invalidateSelf();
		return this;
	}

	public ProgressDrawable setColors(@ColorInt int... colors) {
		if (colors.length == 0)
			return this;
		this.colors.clear();
		return addColors(colors);
	}

	@SuppressWarnings("WeakerAccess")
	public ProgressDrawable setColorIds(@ColorRes int... colorIds) {
		if (colorIds.length == 0)
			return this;
		this.colors.clear();
		return addColorIds(colorIds);
	}

	@SuppressWarnings("WeakerAccess")
	public ProgressDrawable addColors(@ColorInt int... colors) {
		if (colors.length == 0)
			return this;
		for (int color : colors)
			this.colors.add(color);
		updatePaintColor();
		return this;
	}

	@SuppressWarnings("WeakerAccess")
	public ProgressDrawable addColorIds(@ColorRes int... colorIds) {
		if (colorIds.length == 0)
			return this;
		for (int colorId : colorIds)
			colors.add(ContextCompat.getColor(getContext(), colorId));
		updatePaintColor();
		return this;
	}

	@FloatRange(from = 0f, to = 1f)
	public float getProgress() {
		return progress;
	}

	@SuppressLint("Range")
	public void setProgress(@FloatRange(from = 0f, to = 1f) float progress) {
		this.progress = progress;
		rotateAngle = 0;
		tailAngle = START_OFFSET;
		headAngle = tailAngle + getProgress() * FULL_CIRCLE;
		drawBackCircle = true;
		invalidateSelf();
		if (progress == 1f && !isRunning())
			start(300);
		else
			stop();
	}

	public void setDrawParams(float tailAngle, float headAngle, float rotateAngle) {
		this.tailAngle = tailAngle;
		this.headAngle = headAngle;
		this.rotateAngle = rotateAngle;
	}

	private void nextColor() {
		currentColorIndex++;
		if (currentColorIndex >= colors.size())
			currentColorIndex = 0;
		updatePaintColor();
	}

	private void initPaint(Paint paint) {
		paint.setStrokeCap(Paint.Cap.SQUARE);
		paint.setStyle(Paint.Style.STROKE);
		paint.setAntiAlias(true);
		paint.setStrokeWidth(strokeWidthPx);
	}

	private void updatePaintColor() {
		if (colors.isEmpty() || currentColorIndex < 0 || currentColorIndex >= colors.size())
			return;
		int color = colors.get(currentColorIndex);
		paint.setColor(color);
		paintBack.setColor((color | 0xff000000) & 0x50ffffff);
		invalidateSelf();
	}

	public void setInitState() {
		tailAngle = tailAngleDefault;
		headAngle = headAngleDefault;
		rotateAngle = rotateAngleDefault;
	}

	@Override
	public void draw(@NonNull Canvas canvas) {
		rect.set(getBounds());
		int minSize = (int) Math.min(rect.width(), rect.height());
		rect.set(rect.left + (rect.width() - minSize) / 2, rect.top + (rect.height() - minSize) / 2, rect.right - (rect.width() - minSize) / 2, rect.bottom - (rect.height() - minSize) / 2);
		rect.set(rect.left + strokeWidthPx, rect.top + strokeWidthPx, rect.right - strokeWidthPx, rect.bottom - strokeWidthPx);
		if (drawBackCircle)
			canvas.drawArc(rect, 0, FULL_CIRCLE, false, paintBack);
		int saveCount = canvas.save();
		canvas.rotate(rotateAngle, rect.centerX(), rect.centerY());
		canvas.drawArc(rect, tailAngle % FULL_CIRCLE, headAngle - tailAngle, false, paint);
		canvas.restoreToCount(saveCount);
	}


	@Override
	public void setAlpha(int alpha) {
		// nothing
	}

	@Override
	public int getIntrinsicWidth() {
		return sizePx;
	}

	@Override
	public int getIntrinsicHeight() {
		return sizePx;
	}

	@Override
	public void setColorFilter(ColorFilter colorFilter) {
		// nothing
	}

	@Override
	public int getOpacity() {
		return PixelFormat.OPAQUE;
	}

	@Override
	public void start() {
		start(0);
	}

	public void start(long delay) {
		if (isRunning())
			stop();
		controller = new AnimationController(delay);
	}

	@Override
	public void stop() {
		if (!isRunning())
			return;
		controller.release();
		controller = null;
		setInitState();
		invalidateSelf();
	}

	@Override
	public boolean isRunning() {
		return controller != null;
	}

	@Override
	public boolean setVisible(boolean visible, boolean restart) {
		if (visible && restart && isRunning())
			start();
		else if (visible)
			resume();
		else
			pause();
		return super.setVisible(visible, restart);
	}

	private void pause() {
		startAfterAppear = isRunning();
		stop();
	}

	private void resume() {
		if (startAfterAppear && !isRunning())
			start();
		startAfterAppear = false;
	}

	@Override
	public void onViewAttachedToWindow(View view) {
		if (getCallback() != null) {
			resume();
		} else {
			parent.removeOnAttachStateChangeListener(this);
			stop();
		}
	}

	@Override
	public void onViewDetachedFromWindow(View view) {
		if (getCallback() != null) {
			pause();
		} else {
			parent.removeOnAttachStateChangeListener(this);
			stop();
		}
	}

	private class AnimationController implements ValueAnimator.AnimatorUpdateListener {
		private static final String PROPERTY_TAIL_ANGLE = "tailAngle";
		private static final String PROPERTY_HEAD_ANGLE = "headAngle";
		private static final int ANIM_DURATION = 1500;
		private static final int PART_OF_CIRCLE = (int) (FULL_CIRCLE * 0.75f);

		private ValueAnimator headAnimator = ValueAnimator.ofPropertyValuesHolder(PropertyValuesHolder.ofFloat(PROPERTY_HEAD_ANGLE, 0, 0));
		private ValueAnimator tailAnimator = ValueAnimator.ofPropertyValuesHolder(PropertyValuesHolder.ofFloat(PROPERTY_TAIL_ANGLE, 0, 0));
		private ValueAnimator rotateAnimator = ValueAnimator.ofFloat(0, FULL_CIRCLE);

		private final ValueAnimator.AnimatorListener headListener = new AnimatorListenerAdapter() {
			@Override
			public void onAnimationEnd(Animator animation) {
				if (!rotateAnimator.isRunning())
					return;
				drawBackCircle = false;
				headAnimator.setStartDelay(0);
				rotateAnimator.setStartDelay(0);
				runTail();
			}
		};

		private final ValueAnimator.AnimatorListener tailListener = new AnimatorListenerAdapter() {
			@Override
			public void onAnimationEnd(Animator animation) {
				if (!rotateAnimator.isRunning())
					return;
				if (headAngle >= FULL_CIRCLE && tailAngle >= FULL_CIRCLE) {
					headAngle = headAngle % FULL_CIRCLE;
					tailAngle = tailAngle % FULL_CIRCLE;
				}
				nextColor();
				runHead();
			}
		};

		private AnimationController(long delay) {
			FastOutSlowInInterpolator interpolator = new FastOutSlowInInterpolator();
			headAnimator.setInterpolator(interpolator);
			headAnimator.addUpdateListener(this);
			headAnimator.addListener(headListener);
			tailAnimator.setInterpolator(interpolator);
			tailAnimator.addUpdateListener(this);
			tailAnimator.addListener(tailListener);
			rotateAnimator.setDuration(ANIM_DURATION);
			rotateAnimator.setInterpolator(new LinearInterpolator());
			rotateAnimator.addUpdateListener(this);
			rotateAnimator.setRepeatCount(ValueAnimator.INFINITE);

			headAnimator.setStartDelay(delay);
			rotateAnimator.setStartDelay(delay);
			runHead();
			rotateAnimator.start();
		}

		@Override
		public void onAnimationUpdate(ValueAnimator valueAnimator) {
			if (valueAnimator == headAnimator)
				headAngle = (float) valueAnimator.getAnimatedValue(PROPERTY_HEAD_ANGLE);
			else if (valueAnimator == tailAnimator)
				tailAngle = (float) valueAnimator.getAnimatedValue(PROPERTY_TAIL_ANGLE);
			else
				rotateAngle = (float) valueAnimator.getAnimatedValue();
			invalidateSelf();
		}

		private void release() {
			rotateAnimator.cancel();
			headAnimator.cancel();
			tailAnimator.cancel();
		}

		private void runHead() {
			float startValue = headAngle;
			float endValue = drawBackCircle ? (tailAngle + FULL_CIRCLE) : (headAngle + (PART_OF_CIRCLE - (headAngle - tailAngle - MIN_LENGTH)));
			headAnimator.setValues(PropertyValuesHolder.ofFloat(PROPERTY_HEAD_ANGLE, startValue, endValue));
			headAnimator.setDuration(calculateDuration(startValue, endValue));
			headAnimator.start();
		}

		private void runTail() {
			float startValue = tailAngle;
			float endValue = headAngle - MIN_LENGTH;
			tailAnimator.setValues(PropertyValuesHolder.ofFloat(PROPERTY_TAIL_ANGLE, startValue, endValue));
			tailAnimator.setDuration(calculateDuration(startValue, endValue));
			tailAnimator.start();
		}

		private long calculateDuration(float startValue, float endValue) {
			return (long) ((ANIM_DURATION / 2) * ((endValue - startValue) / (float) PART_OF_CIRCLE));
		}
	}
}
