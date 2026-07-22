package com.fulldome.mahabharata.utils;

import android.graphics.Bitmap;

import com.fulldome.mahabharata.R;
import com.ironwaterstudio.controls.ImageViewEx;
import com.ironwaterstudio.controls.ProgressDrawable;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.listeners.SimpleCallListener;

public class ImageCallListener extends SimpleCallListener {
	private final ImageViewEx imageView;

	public ImageCallListener(ImageViewEx imageView) {
		this.imageView = imageView;
	}

	@Override
	protected void onStart() {
		super.onStart();
		if (imageView.getDefaultImageView().getDrawable() instanceof ProgressDrawable)
			((ProgressDrawable) imageView.getDefaultImageView().getDrawable()).stop();
		ProgressDrawable progressDrawable = new ProgressDrawable(imageView);
		progressDrawable.setColorIds(R.color.yellow);
		imageView.setImageDrawableDefault(progressDrawable);
		progressDrawable.start();
	}

	@Override
	protected void onSuccess(ApiResult result) {
		super.onSuccess(result);
		stopProgress();
		imageView.setImageBitmap(result.getData(Bitmap.class));
	}

	@Override
	protected void onError(ApiResult result) {
		super.onError(result);
		stopProgress();
	}

	private void stopProgress() {
		if (imageView.getDefaultImageView().getDrawable() instanceof ProgressDrawable)
			((ProgressDrawable) imageView.getDefaultImageView().getDrawable()).stop();
		imageView.setImageDrawableDefault(null);
	}
}
