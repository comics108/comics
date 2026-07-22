package com.fulldome.mahabharata.dialogs;

import android.app.Activity;
import android.app.Dialog;
import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.fragment.app.DialogFragment;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.TextView;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.screens.UiConstants;
import com.fulldome.mahabharata.utils.AnalyticsEvents;
import com.ironwaterstudio.controls.ImageViewEx;
import com.ironwaterstudio.dialogs.ProgressFragment;
import com.ironwaterstudio.server.CacheManager;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.listeners.CallListener;
import com.ironwaterstudio.utils.FbUtils;
import com.ironwaterstudio.utils.UiHelperCompat;
import com.ironwaterstudio.utils.Utils;

public class ShareQuoteDialog extends DialogFragment {
	private static final String KEY_SHARE_IMAGE = "shareImage";
	private static final long SHARE_IMAGE_CACHE_PERIOD = 1000 * 60 * 60 * 2;

	private EditText etComment;
	private ImageViewEx ivQuote;
	private TextView btnCancel;
	private TextView btnShare;

	private boolean inProgress = false;

	private final CallListener imageCallListener = new CallListener(this, false) {
		@Override
		protected void onStart() {
			super.onStart();
			inProgress = true;
		}

		@Override
		public void onSuccess(ApiResult result) {
			super.onSuccess(result);
			inProgress = false;
			Bitmap bitmap = result.getData(Bitmap.class);

			ivQuote.setImageBitmap(bitmap);
			if (!ProgressFragment.isShown(getActivity()))
				return;
			ProgressFragment.dismiss(getActivity());
			btnShare.post(new Runnable() {
				@Override
				public void run() {
					shareClickListener.onClick(btnShare);
				}
			});
		}

		@Override
		protected void onError(ApiResult result) {
			super.onError(result);
			inProgress = false;
			if (ProgressFragment.isShown(getActivity()))
				ProgressFragment.dismiss(getActivity());
		}
	};

	private final View.OnClickListener cancelClickListener = new View.OnClickListener() {
		@Override
		public void onClick(View view) {
			dismiss();
		}
	};

	private final View.OnClickListener shareClickListener = new View.OnClickListener() {
		@Override
		public void onClick(View view) {
			if (ivQuote.getMainImageView().getDrawable() == null) {
				if (!inProgress)
					ivQuote.setImage(getImage(), imageCallListener);
				ProgressFragment.show(getActivity());
				return;
			}
			FbUtils.logEvent(AnalyticsEvents.CATEGORY_EPISODE, AnalyticsEvents.ACTION_SHARE + " quote");
			Bitmap shareImage = ((BitmapDrawable) ivQuote.getMainImageView().getDrawable()).getBitmap();
			CacheManager.getInstance().setBitmap(KEY_SHARE_IMAGE, shareImage, SHARE_IMAGE_CACHE_PERIOD, Bitmap.CompressFormat.JPEG, 100);
			Utils.share(getContext(), CacheManager.getInstance().getFile(KEY_SHARE_IMAGE), etComment.getText().toString(), getString(R.string.share));
			dismiss();
		}
	};

	@NonNull
	@Override
	public Dialog onCreateDialog(Bundle savedInstanceState) {
		Dialog dialog = new Dialog(getActivity(), R.style.Dialog);
		dialog.setContentView(R.layout.dialog_share_quote);

		etComment = dialog.findViewById(R.id.et_comment);
		ivQuote = dialog.findViewById(R.id.iv_quote);
		btnCancel = dialog.findViewById(R.id.btn_cancel);
		btnShare = dialog.findViewById(R.id.btn_share);

		btnCancel.setOnClickListener(cancelClickListener);
		btnShare.setOnClickListener(shareClickListener);
		FbUtils.logEvent(AnalyticsEvents.CATEGORY_EPISODE, AnalyticsEvents.ACTION_START_SHARE + " quote");
		etComment.setText(getString(R.string.share_quote_default_text) + " http://play.google.com/store/apps/details?id=" + getContext().getPackageName());
		return dialog;
	}

	@Override
	public void onActivityCreated(Bundle inState) {
		super.onActivityCreated(inState);
		if (inState != null)
			inProgress = inState.getBoolean(UiConstants.KEY_IN_PROGRESS);
		imageCallListener.register();
		ivQuote.post(new Runnable() {
			@Override
			public void run() {
				ViewGroup.LayoutParams params = ivQuote.getLayoutParams();
				params.height = ivQuote.getWidth();
				ivQuote.requestLayout();
				ivQuote.post(new Runnable() {
					@Override
					public void run() {
						ivQuote.setImage(getImage(), imageCallListener);
					}
				});
			}
		});
	}

	@Override
	public void onSaveInstanceState(Bundle outState) {
		super.onSaveInstanceState(outState);
		outState.putBoolean(UiConstants.KEY_IN_PROGRESS, inProgress);
	}

	private String getImage() {
		return getArguments().getString(UiConstants.KEY_IMAGE);
	}

	public static void show(Activity activity, String image) {
		Bundle args = new Bundle();
		args.putString(UiConstants.KEY_IMAGE, image);
		ShareQuoteDialog dialog = new ShareQuoteDialog();
		dialog.setArguments(args);
		UiHelperCompat.showDialog(activity, dialog);
	}
}
