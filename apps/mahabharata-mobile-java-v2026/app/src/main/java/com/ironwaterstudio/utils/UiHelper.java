package com.ironwaterstudio.utils;

import android.app.Activity;
import android.app.DialogFragment;
import android.app.Fragment;
import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.content.Context;
import android.content.Intent;
import android.graphics.drawable.Drawable;
import android.os.Build;
import androidx.annotation.StringRes;
import com.google.android.material.snackbar.Snackbar;
import androidx.fragment.app.FragmentActivity;
import android.text.TextUtils;
import android.view.View;
import android.view.ViewTreeObserver;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.TextView;

import com.fulldome.mahabharata.R;
import com.ironwaterstudio.dialogs.AlertFragment;

public final class UiHelper {
	public static final String ACTION_FINISH = "com.ironwaterstudio.FINISH";

	public static void showActivity(Activity activity, final Class<?> aClass) {
		final Intent intent = new Intent(activity, aClass);
		showActivity(activity, intent);
	}

	public static void showActivity(Activity activity, final Class<?> aClass, final int requestCode) {
		final Intent intent = new Intent(activity, aClass);
		showActivity(activity, intent, requestCode);
	}

	public static void showActivity(Activity activity, final Intent intent) {
		showActivity(activity, intent, -1);
	}

	public static void showActivity(Activity activity, final Intent intent,
									final int requestCode) {
		intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
		activity.startActivityForResult(intent, requestCode);
	}

	public static void showActivity(Fragment fragment, final Class<?> aClass) {
		final Intent intent = new Intent(fragment.getActivity(), aClass);
		showActivity(fragment, intent);
	}

	public static void showActivity(Fragment fragment, final Intent intent) {
		showActivity(fragment, intent, -1);
	}

	public static void showActivity(Fragment fragment, final Intent intent,
									final int requestCode) {
		intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
		fragment.startActivityForResult(intent, requestCode);
	}

	public static void showDialog(Context context, DialogFragment dialog) {
		showDialog(context, dialog, dialog.getClass().getSimpleName());
	}

	public static void showDialog(Context context, DialogFragment dialog, String tag) {
		if (!(context instanceof FragmentActivity))
			return;

		try {
			FragmentTransaction ft = ((FragmentActivity) context).getFragmentManager().beginTransaction();
			ft.add(dialog, tag);
			ft.commitAllowingStateLoss();
		} catch (IllegalStateException ignored) {
		}
	}

	@SuppressWarnings("unchecked")
	public static <T extends DialogFragment> T findDialog(Context context, Class<T> cls) {
		return findDialog(context, cls.getSimpleName());
	}

	@SuppressWarnings("unchecked")
	public static <T extends DialogFragment> T findDialog(Context context, String tag) {
		if (!(context instanceof FragmentActivity))
			return null;
		return (T) ((FragmentActivity) context).getFragmentManager().findFragmentByTag(tag);
	}

	public static void showSnackbar(Activity activity, @StringRes int messageResId) {
		showSnackbar(activity, activity.getString(messageResId));
	}

	public static void showSnackbar(final Activity activity, final String message) {
		if (TextUtils.isEmpty(message))
			return;
		TextView textView = activity.findViewById(com.google.android.material.R.id.snackbar_text);
		if (textView != null && textView.getText().equals(message))
			return;
		View target = activity.findViewById(R.id.coordinator);
		if (target == null)
			target = activity.findViewById(android.R.id.content);
		Snackbar.make(target, message, Snackbar.LENGTH_LONG).setAction(R.string.open, new View.OnClickListener() {
			@Override
			public void onClick(View view) {
				AlertFragment.create().setMessage(message).show(activity);
			}
		}).show();
	}

	public static void finishAll(Context context) {
		final Intent intent = new Intent();
		intent.setAction(ACTION_FINISH);
		context.sendBroadcast(intent);
	}

	public static int dpToPx(Context context, float dp) {
		float scale = context.getResources().getDisplayMetrics().densityDpi;
		return (int) (dp * scale / 160);
	}

	public static float spToPx(Context context, int sp) {
		float scale = context.getResources().getDisplayMetrics().scaledDensity;
		return sp * scale;
	}

	public static void hideKeyboard(Activity activity) {
		if (activity == null)
			return;
		View currentFocus = activity.getCurrentFocus();
		if (currentFocus == null)
			return;

		InputMethodManager im = (InputMethodManager) activity
				.getApplicationContext().getSystemService(
						Context.INPUT_METHOD_SERVICE);
		im.hideSoftInputFromWindow(activity.getCurrentFocus().getWindowToken(),
				InputMethodManager.HIDE_NOT_ALWAYS);
	}

	public static void clearBackStack(FragmentManager fm) {
		while (fm.getBackStackEntryCount() > 0) {
			fm.popBackStackImmediate();
		}
	}

	public static void setBackground(EditText et, int resId) {
		// padding are removed after setBackgroundResource(...), so need to restore it
		int bottom = et.getPaddingBottom();
		int top = et.getPaddingTop();
		int right = et.getPaddingRight();
		int left = et.getPaddingLeft();
		et.setBackgroundResource(resId);
		et.setPadding(left, top, right, bottom);
	}

	public static void setBackground(View view, Drawable drawable) {
		if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.JELLY_BEAN) {
			//noinspection deprecation
			view.setBackgroundDrawable(drawable);
		} else {
			view.setBackground(drawable);
		}
	}

	public static void onGlobalLayout(final View view, final Runnable r) {
		view.getViewTreeObserver().addOnGlobalLayoutListener(
				new ViewTreeObserver.OnGlobalLayoutListener() {
					@SuppressWarnings("deprecation")
					@Override
					public void onGlobalLayout() {
						r.run();
						if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
							view.getViewTreeObserver().removeOnGlobalLayoutListener(this);
						} else {
							view.getViewTreeObserver().removeGlobalOnLayoutListener(this);
						}
					}
				});
	}
}
