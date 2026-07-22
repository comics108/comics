package com.fulldome.mahabharata.controls;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ObjectAnimator;
import android.content.Context;
import androidx.core.content.ContextCompat;
import androidx.interpolator.view.animation.FastOutSlowInInterpolator;
import androidx.appcompat.widget.AppCompatImageView;
import android.util.AttributeSet;

import com.fulldome.mahabharata.R;

public class SoundBadge extends AppCompatImageView {
	private ObjectAnimator scaleAnimator = ObjectAnimator.ofFloat(this, "scale", 0f);
	private ObjectAnimator alphaAnimator = ObjectAnimator.ofFloat(this, "alpha", 0f);
	private boolean on = false;
	private boolean needCancel = false;

	private ObjectAnimator.AnimatorListener scaleListener = new AnimatorListenerAdapter() {
		@Override
		public void onAnimationEnd(Animator animation) {
			super.onAnimationEnd(animation);
			if (getScale() == 0) {
				needCancel = false;
				alphaAnimator.cancel();
				show(on);
			} else if (getScale() == 1) {
				alphaAnimator.start();
			}
		}
	};

	private ObjectAnimator.AnimatorListener alphaListener = new AnimatorListenerAdapter() {
		@Override
		public void onAnimationEnd(Animator animation) {
			super.onAnimationEnd(animation);
			needCancel = false;
		}
	};

	public SoundBadge(Context context) {
		this(context, null);
	}

	public SoundBadge(Context context, AttributeSet attrs) {
		super(context, attrs);
		scaleAnimator.setDuration(200);
		scaleAnimator.setInterpolator(new FastOutSlowInInterpolator());
		scaleAnimator.addListener(scaleListener);
		alphaAnimator.setDuration(200);
		alphaAnimator.setInterpolator(new FastOutSlowInInterpolator());
		alphaAnimator.setStartDelay(1000);
		scaleAnimator.addListener(alphaListener);
		setScale(0f);
	}

	public void setScale(float scale) {
		setScaleX(scale);
		setScaleY(scale);
	}

	public float getScale() {
		return getScaleX();
	}

	public void show(boolean on) {
		this.on = on;
		if (!needCancel) {
			setScale(0f);
			setAlpha(1f);
			setImageDrawable(ContextCompat.getDrawable(getContext(), on ? R.drawable.icn_sound_on : R.drawable.icn_sound_off));
		}
		alphaAnimator.cancel();
		scaleAnimator.cancel();
		scaleAnimator.setFloatValues(needCancel ? 0 : 1f);
		scaleAnimator.start();
		needCancel = true;
	}
}
