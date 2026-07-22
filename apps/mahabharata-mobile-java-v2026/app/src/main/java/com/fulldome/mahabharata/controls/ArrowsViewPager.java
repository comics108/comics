package com.fulldome.mahabharata.controls;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.view.MotionEvent;

import com.fulldome.mahabharata.R;
import com.ironwaterstudio.utils.UiHelper;

public class ArrowsViewPager extends HackyViewPager {
	private final Bitmap leftArrow;
	private final Bitmap rightArrow;
	private final Paint paint = new Paint();
	private final Matrix matrix = new Matrix();
	private final int arrowMargin;
	private final int arrowTopMargin;
	private final int arrowButtonWidth;
	private float rawX = -1;

	public ArrowsViewPager(Context context) {
		this(context, null);
	}

	public ArrowsViewPager(Context context, AttributeSet attrs) {
		super(context, attrs);
		leftArrow = BitmapFactory.decodeResource(getResources(), R.drawable.icn_left);
		rightArrow = BitmapFactory.decodeResource(getResources(), R.drawable.icn_right);
		paint.setAntiAlias(true);
		arrowMargin = UiHelper.dpToPx(getContext(), 26);
		arrowTopMargin = UiHelper.dpToPx(getContext(), 100);
		arrowButtonWidth = arrowMargin + Math.max(leftArrow.getWidth(), rightArrow.getWidth());
	}

	@Override
	public boolean onInterceptTouchEvent(MotionEvent ev) {
		return isHitToButton(ev.getRawX()) || super.onInterceptTouchEvent(ev);
	}

	@Override
	public boolean onTouchEvent(MotionEvent ev) {
		switch (ev.getAction()) {
			case MotionEvent.ACTION_DOWN:
				if (isHitToButton(ev.getRawX()))
					rawX = ev.getRawX();
				break;
			case MotionEvent.ACTION_MOVE:
				if (Math.abs(rawX - ev.getRawX()) > 30)
					rawX = -1;
				break;
			case MotionEvent.ACTION_UP:
				if (rawX == -1)
					break;
				if (isHitToLeftArrow(ev.getRawX()))
					setCurrentItem(getCurrentItem() - 1, true);
				if (isHitToRightArrow(ev.getRawX()))
					setCurrentItem(getCurrentItem() + 1, true);
				rawX = -1;
				break;
		}
		return super.onTouchEvent(ev) || isHitToButton(ev.getRawX());
	}

	@Override
	protected void onLayout(boolean changed, int l, int t, int r, int b) {
		super.onLayout(changed, l, t, r, b);
		matrix.setTranslate(0, getResources().getDisplayMetrics().heightPixels - getHeight());
	}

	@Override
	public void draw(Canvas canvas) {
		super.draw(canvas);
		if (matrix.isIdentity())
			return;
		if (getCurrentItem() > 0)
			canvas.drawBitmap(leftArrow, arrowMargin + getScrollX(), arrowTopMargin, paint);
		if (getAdapter() != null && getCurrentItem() < getAdapter().getCount() - 1)
			canvas.drawBitmap(rightArrow, getWidth() - arrowMargin - rightArrow.getWidth() + getScrollX(), arrowTopMargin, paint);
	}

	private boolean isHitToLeftArrow(float x) {
		return x <= arrowButtonWidth;
	}

	private boolean isHitToRightArrow(float x) {
		return x >= getWidth() - arrowButtonWidth;
	}

	private boolean isHitToButton(float x) {
		return isHitToLeftArrow(x) || isHitToRightArrow(x);
	}
}
