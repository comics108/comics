package com.ironwaterstudio.dialogs;

import android.app.Activity;
import android.app.Dialog;
import android.app.DialogFragment;
import android.content.Context;
import android.os.Bundle;
import androidx.annotation.FloatRange;
import androidx.annotation.NonNull;

import com.fulldome.mahabharata.R;
import com.ironwaterstudio.controls.ProgressBar;
import com.ironwaterstudio.utils.UiHelper;

public class ProgressFragment extends DialogFragment {
	private static final String KEY_ANIMATE = "com.ironwaterstudio.dialogs.ProgressFragment.animate";
	private static final String KEY_PROGRESS_COUNT = "progressCount";
	private int progressCount = 0;
	private ProgressBar progressBar = null;

	@NonNull
	@Override
	public Dialog onCreateDialog(Bundle inState) {
		final Dialog dialog = new Dialog(getActivity(), R.style.Dialog_NoShadow);
		progressBar = new ProgressBar(getActivity());
		dialog.setContentView(progressBar);
		dialog.setCanceledOnTouchOutside(false);
		setCancelable(false);
		if (inState != null)
			progressCount = inState.getInt(KEY_PROGRESS_COUNT, progressCount);
		return dialog;
	}

	@Override
	public void onActivityCreated(Bundle inState) {
		super.onActivityCreated(inState);
		if (getArguments() != null && !getArguments().getBoolean(KEY_ANIMATE)) {
			progressBar.getDrawable().setProgress(0);
			return;
		}
		progressBar.getDrawable().start(200);
	}

	@Override
	public void onAttach(Context context) {
		super.onAttach(context);
		if (!(context instanceof Activity))
			return;
		int progressCount = getProgressCount((Activity) context);
		if (progressCount == 0)
			dismiss();
	}

	@Override
	public void onSaveInstanceState(Bundle outState) {
		super.onSaveInstanceState(outState);
		outState.putInt(KEY_PROGRESS_COUNT, progressCount);
	}

	public static boolean isShown(Activity activity) {
		return UiHelper.findDialog(activity, ProgressFragment.class) != null && getProgressCount(activity) > 0;
	}

	public static void setProgress(@NonNull Activity activity, @FloatRange(from = 0f, to = 1f) float progress) {
		ProgressFragment fragment = UiHelper.findDialog(activity, ProgressFragment.class);
		if (fragment != null)
			fragment.progressBar.getDrawable().setProgress(progress);
	}

	public static void show(Activity activity) {
		show(activity, true);
	}

	public static void show(Activity activity, boolean animate) {
		int progressCount = getProgressCount(activity);
		if (progressCount == 0) {
			ProgressFragment dialog = new ProgressFragment();
			Bundle bundle = new Bundle();
			bundle.putBoolean(KEY_ANIMATE, animate);
			dialog.setArguments(bundle);
			UiHelper.showDialog(activity, dialog);
		}
		progressCount++;
		setProgressCount(activity, progressCount);
	}

	public static void dismiss(Activity activity) {
		int progressCount = getProgressCount(activity);
		progressCount--;
		setProgressCount(activity, progressCount);
		if (progressCount == 0) {
			ProgressFragment dialogFragment = UiHelper.findDialog(activity, ProgressFragment.class);
			if (dialogFragment != null)
				dialogFragment.dismissAllowingStateLoss();
		}
	}

	private static int getProgressCount(Activity activity) {
		return activity.getIntent().getIntExtra(KEY_PROGRESS_COUNT, 0);
	}

	private static void setProgressCount(Activity activity, int progressCount) {
		activity.getIntent().putExtra(KEY_PROGRESS_COUNT, progressCount);
	}
}