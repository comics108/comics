package com.ironwaterstudio.utils;

import android.content.Context;
import android.content.Intent;
import androidx.fragment.app.DialogFragment;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.fragment.app.FragmentTransaction;

public class UiHelperCompat {
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
			FragmentTransaction ft = ((FragmentActivity) context).getSupportFragmentManager().beginTransaction();
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
		return (T) ((FragmentActivity) context).getSupportFragmentManager().findFragmentByTag(tag);
	}
}
