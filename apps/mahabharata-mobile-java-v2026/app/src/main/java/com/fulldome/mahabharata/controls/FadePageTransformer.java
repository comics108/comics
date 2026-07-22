package com.fulldome.mahabharata.controls;

import androidx.viewpager.widget.ViewPager;
import android.view.View;

public class FadePageTransformer implements ViewPager.PageTransformer {
	public void transformPage(View view, float position) {
		float fraction = Math.max(Math.min(Math.abs(position), 1f), 0f);
		float value = Math.max(Math.min(position, 1f), -1f);
		view.setTranslationX(position != 1 && position != -1 ? -view.getWidth() * value : 0);
		view.setAlpha(1f - fraction);
	}
}