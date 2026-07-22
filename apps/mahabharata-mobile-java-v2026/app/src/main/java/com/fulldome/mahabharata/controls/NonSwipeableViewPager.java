package com.fulldome.mahabharata.controls;

import android.content.Context;
import android.util.AttributeSet;
import android.view.MotionEvent;

public class NonSwipeableViewPager extends HackyViewPager {
	public NonSwipeableViewPager(Context context) {
		super(context);
	}

	public NonSwipeableViewPager(Context context, AttributeSet attrs) {
		super(context, attrs);
	}

	@Override
	public boolean onInterceptTouchEvent(MotionEvent arg0) {
		// Never allow swiping to switch between pages
		return false;
	}

	@Override
	public boolean onTouchEvent(MotionEvent event) {
		// Never allow swiping to switch between pages
		return false;
	}
}
