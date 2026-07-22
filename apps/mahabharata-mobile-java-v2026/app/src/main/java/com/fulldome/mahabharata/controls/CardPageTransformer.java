package com.fulldome.mahabharata.controls;

import android.content.Context;
import android.content.res.Resources;
import androidx.annotation.NonNull;
import androidx.viewpager.widget.ViewPager;
import androidx.cardview.widget.CardView;
import android.view.View;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.fragments.EpisodeFragment;

public class CardPageTransformer implements ViewPager.PageTransformer {
	public void transformPage(@NonNull View view, float position) {
		CardView cvPoster = view.findViewById(R.id.cv_poster);
		Resources resources = view.getResources();
		float fraction = Math.max(Math.min(Math.abs(position), 1f), 0f);
		float value = Math.max(Math.min(position, 1f), -1f);
		float scale = (1f - fraction) + fraction * 0.7f;
		int verticalOffset = (view.getHeight() - EpisodeFragment.getPosterHeight(view.getContext())) / 4;
		view.setTranslationY((-verticalOffset * (1f - fraction) + verticalOffset * fraction * 0.5f) / scale);
		int horizontalOffset = (view.getWidth() - EpisodeFragment.getPosterWidth(view.getContext())) / 2 + getCardOffset(view.getContext());
		view.setTranslationX((-horizontalOffset * value) / scale);
		view.setScaleX(scale);
		view.setScaleY(scale);
		int minElevation = resources.getDimensionPixelOffset(R.dimen.card_min_elevation);
		int maxElevation = resources.getDimensionPixelOffset(R.dimen.card_max_elevation);
		cvPoster.setCardElevation(maxElevation * (1f - fraction) + minElevation * fraction);
	}

	private static int getCardOffset(Context context) {
		return (int) (EpisodeFragment.getPosterWidth(context) * 0.161f);
	}
}
