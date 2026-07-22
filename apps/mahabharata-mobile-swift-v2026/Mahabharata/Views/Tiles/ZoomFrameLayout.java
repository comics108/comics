package com.fulldome.mahabharata.controls;

import android.animation.Animator;
import android.animation.ValueAnimator;
import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Point;
import android.graphics.Rect;
import android.graphics.RectF;
import android.support.annotation.Nullable;
import android.util.AttributeSet;
import android.view.GestureDetector;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.view.View;
import android.view.animation.DecelerateInterpolator;
import android.widget.FrameLayout;

import com.fulldome.mahabharata.R;
import com.ironwaterstudio.utils.SimpleAnimatorListener;

public class ZoomFrameLayout extends FrameLayout implements GestureDetector.OnGestureListener, ScaleGestureDetector.OnScaleGestureListener, GestureDetector.OnDoubleTapListener {
	public enum FitMode {VERTICAL, HORIZONTAL}

	private final GestureDetector detector;
	private final ScaleGestureDetector scaleDetector;
	private final FlingHandler flingHandler = new FlingHandler();
	private final Matrix matrix = new Matrix();
	private final Matrix inverseMatrix = new Matrix();
	private final RectF viewRect = new RectF();
	private final RectF invertedViewRect = new RectF();
	private final RectF contentRect = new RectF();
	private final RectF transformedRect = new RectF();
	private float minScale = 1f;
	private float maxScale = 1f;
	private float scale = 1f;

	private FitMode fitMode = FitMode.VERTICAL;
	private boolean zoomEnabled = true;
	private OnScrollListener scrollListener = null;

	private GestureDetector.SimpleOnGestureListener gestureListener = null;

	public ZoomFrameLayout(Context context) {
		this(context, null);
	}

	public ZoomFrameLayout(Context context, @Nullable AttributeSet attrs) {
		super(context, attrs);
		setClipChildren(false);
		detector = new GestureDetector(context, this);
		scaleDetector = new ScaleGestureDetector(context, this);

		if (attrs == null)
			return;
		TypedArray a = context.obtainStyledAttributes(attrs, R.styleable.ZoomFrameLayout);
		fitMode = FitMode.values()[a.getInt(R.styleable.ZoomFrameLayout_fitMode, fitMode.ordinal())];
		zoomEnabled = a.getBoolean(R.styleable.ZoomFrameLayout_zoomEnabled, zoomEnabled);
		a.recycle();
	}

	public float getScale() {
		return scale;
	}

	public void setScrollListener(OnScrollListener scrollListener) {
		this.scrollListener = scrollListener;
	}

	public void setGestureListener(GestureDetector.SimpleOnGestureListener gestureListener) {
		this.gestureListener = gestureListener;
	}

	public void setContentSize(int width, int height) {
		if (contentRect.width() == width && contentRect.height() == height)
			return;
		contentRect.set(0, 0, width, height);
		if (viewRect.isEmpty()) {
			post(new Runnable() {
				@Override
				public void run() {
					initScale();
				}
			});
		} else {
			initScale();
			requestLayout();
		}
	}

	@Override
	protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
		super.onLayout(changed, left, top, right, bottom);
		for (int i = 0; i < getChildCount(); i++) {
			final View child = getChildAt(i);
			if (child.getVisibility() == GONE)
				continue;
			LayoutParams params = (LayoutParams) child.getLayoutParams();
			final int verticalGravity = params.gravity & Gravity.VERTICAL_GRAVITY_MASK;
			if (verticalGravity == Gravity.BOTTOM) {
				int height = child.getMeasuredHeight();
				child.layout(child.getLeft(), (int) (contentRect.height() - height), getRight(), (int) contentRect.height());
			}
		}
		viewRect.set(left, top, right, bottom);
	}

	@Override
	public boolean dispatchTouchEvent(MotionEvent event) {
		flingHandler.cancel();
		event.transform(inverseMatrix);
		if (super.dispatchTouchEvent(event))
			return true;
		event.transform(matrix);
		boolean intercept = detector.onTouchEvent(event);
		return scaleDetector.onTouchEvent(event) | intercept;
	}

	private void updateMatrixDependentData() {
		matrix.invert(inverseMatrix);
		matrix.mapRect(transformedRect, contentRect);
	}

	@Override
	public boolean getChildVisibleRect(View child, Rect rect, Point offset) {
		RectF childRect = new RectF(rect);
		childRect.offset(getX(), getY());
		invertedViewRect.set(new RectF(viewRect.left - offset.x, viewRect.top - offset.y, viewRect.right + offset.x, viewRect.bottom + offset.y));
		inverseMatrix.mapRect(invertedViewRect);
		if (!childRect.intersect(invertedViewRect))
			childRect.set(0, 0, 0, 0);
		childRect.offset(-getX(), -getY());
		childRect.round(rect);
		return !rect.isEmpty();
	}

	@Override
	protected void dispatchDraw(Canvas canvas) {
		canvas.save(Canvas.MATRIX_SAVE_FLAG);
		canvas.setMatrix(matrix);
		super.dispatchDraw(canvas);
		canvas.restore();
	}

	private void initScale() {
		minScale = fitMode == FitMode.VERTICAL ? viewRect.height() / contentRect.height() : viewRect.width() / contentRect.width();
		if (minScale > maxScale)
			maxScale = minScale;
		scale(minScale, 0, 0);
	}

	public void scale(float scaleOffset, float pivotX, float pivotY) {
		scaleOffset = constrain(scaleOffset, minScale / scale, maxScale / scale);
		this.scale *= scaleOffset;
		matrix.postScale(scaleOffset, scaleOffset, pivotX, pivotY);
		updateMatrixDependentData();
		translate(0, 0);
	}

	public void translate(float transX, float transY) {
		transX = constrain(-transX, viewRect.right - transformedRect.right, viewRect.left - transformedRect.left);
		transY = constrain(-transY, viewRect.bottom - transformedRect.bottom, viewRect.top - transformedRect.top);
		if (transX != 0 || transY != 0) {
			matrix.postTranslate(transX, transY);
			updateMatrixDependentData();
		}
		invalidateAll();
	}

	public void invalidateAll() {
		int scrollX = getCurrentScrollX();
		int scrollY = getCurrentScrollY();
		int extendX = (int) (getWidth() / scale);
		int extendY = (int) (getHeight() / scale);
		if (scrollListener != null && !contentRect.isEmpty())
			scrollListener.onScroll((int) contentRect.width(), (int) contentRect.height(), scrollX, scrollY, extendX, extendY);
		invalidate();
		for (int i = 0; i < getChildCount(); i++) {
			View view = getChildAt(i);
			fitMatchParentView(view);
			if (view instanceof ZoomableView)
				((ZoomableView) view).onUpdate(scale, scrollX, scrollY, extendX, extendY);
			view.invalidate();
		}
	}

	private void fitMatchParentView(View child) {
		LayoutParams params = (LayoutParams) child.getLayoutParams();
		if (params.width != LayoutParams.MATCH_PARENT)
			return;
		float invScale = 1f / scale;
		child.setPivotX(0);
		child.setPivotY((params.gravity & Gravity.VERTICAL_GRAVITY_MASK) == Gravity.BOTTOM ? child.getHeight() : 0);
		child.setScaleX(invScale);
		child.setScaleY(invScale);
	}

	public int getCurrentScrollX() {
		return (int) ((contentRect.left - transformedRect.left) / scale);
	}

	public int getCurrentScrollY() {
		return (int) ((contentRect.top - transformedRect.top) / scale);
	}

	@Override
	public boolean onDown(MotionEvent motionEvent) {
		return gestureListener != null && gestureListener.onDown(motionEvent);
	}

	@Override
	public void onShowPress(MotionEvent motionEvent) {
		if (gestureListener != null)
			gestureListener.onShowPress(motionEvent);
	}

	@Override
	public boolean onSingleTapUp(MotionEvent motionEvent) {
		return gestureListener != null && gestureListener.onSingleTapUp(motionEvent);
	}

	@Override
	public boolean onScroll(MotionEvent startMotionEvent, MotionEvent motionEvent, float distanceX, float distanceY) {
		if (gestureListener != null)
			gestureListener.onScroll(startMotionEvent, motionEvent, distanceX, distanceY);
		translate(distanceX, distanceY);
		return true;
	}

	@Override
	public void onLongPress(MotionEvent motionEvent) {
		if (gestureListener != null)
			gestureListener.onLongPress(motionEvent);
	}

	@Override
	public boolean onFling(MotionEvent startMotionEvent, MotionEvent motionEvent, float velocityX, float velocityY) {
		if (gestureListener != null)
			gestureListener.onFling(startMotionEvent, motionEvent, velocityX, velocityY);
		flingHandler.fling(velocityX, velocityY);
		return true;
	}

	@Override
	public boolean onScaleBegin(ScaleGestureDetector scaleDetector) {
		return true;
	}

	@Override
	public boolean onScale(ScaleGestureDetector scaleDetector) {
		if (zoomEnabled)
			scale(scaleDetector.getScaleFactor(), scaleDetector.getFocusX(), scaleDetector.getFocusY());
		return zoomEnabled;
	}

	@Override
	public void onScaleEnd(ScaleGestureDetector scaleDetector) {
	}

	@Override
	public boolean onSingleTapConfirmed(MotionEvent e) {
		return gestureListener != null && gestureListener.onSingleTapConfirmed(e);
	}

	@Override
	public boolean onDoubleTap(MotionEvent e) {
		return gestureListener != null && gestureListener.onDoubleTap(e);
	}

	@Override
	public boolean onDoubleTapEvent(MotionEvent e) {
		return gestureListener != null && gestureListener.onDoubleTapEvent(e);
	}

	private static float constrain(float value, float min, float max) {
		return Math.min(max, Math.max(value, min));
	}

	private class FlingHandler {
		private static final float VELOCITY_FACTOR = 0.5f;
		private static final long FLING_DURATION = 1000L;

		private float transFlingX = 0;
		private float transFlingY = 0;
		private float oldValue = 0;
		private ValueAnimator valueAnimator = ValueAnimator.ofFloat(0, 1);
		private SimpleAnimatorListener animatorListener = new SimpleAnimatorListener() {
			@Override
			public void onAnimationStart(Animator animation) {
				super.onAnimationStart(animation);
				oldValue = 0;
			}
		};
		private ValueAnimator.AnimatorUpdateListener updateListener = new ValueAnimator.AnimatorUpdateListener() {
			@Override
			public void onAnimationUpdate(ValueAnimator valueAnimator) {
				float value = (float) valueAnimator.getAnimatedValue();
				if (!valueAnimator.isRunning() || oldValue == value)
					return;
				translate(transFlingX * (value - oldValue), transFlingY * (value - oldValue));
				oldValue = value;
			}
		};

		public FlingHandler() {
			valueAnimator.addUpdateListener(updateListener);
			valueAnimator.addListener(animatorListener);
			valueAnimator.setInterpolator(new DecelerateInterpolator());
			valueAnimator.setDuration(FLING_DURATION);
		}

		public void fling(float velocityX, float velocityY) {
			transFlingX = -velocityX * VELOCITY_FACTOR;
			transFlingY = -velocityY * VELOCITY_FACTOR;
			valueAnimator.start();
		}

		public void cancel() {
			valueAnimator.cancel();
		}
	}

	public interface ZoomableView {
		void onUpdate(float scale, int scrollX, int scrollY, int extendedX, int extendedY);
	}

	public interface OnScrollListener {
		void onScroll(int contentWidth, int contentHeight, int scrollX, int scrollY, int extendedX, int extendedY);
	}
}
