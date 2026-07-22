package com.ironwaterstudio.dialogs;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.app.DialogFragment;
import android.content.DialogInterface;
import android.os.Bundle;
import androidx.annotation.NonNull;
import android.text.TextUtils;
import android.view.KeyEvent;

import com.fulldome.mahabharata.R;
import com.ironwaterstudio.utils.UiHelper;

public class AlertFragment extends DialogFragment {
	private static final String KEY_TITLE = "title";
	private static final String KEY_MESSAGE = "message";
	private static final String KEY_POSITIVE_TEXT = "positiveText";
	private static final String KEY_NEGATIVE_TEXT = "negativeText";
	private static final String KEY_TAG = "tag";
	private static final String KEY_POSITIVE_LISTENER = "positiveListener";
	private static final String KEY_NEGATIVE_LISTENER = "negativeListener";

	private DialogInterface.OnClickListener positiveListener = null;
	private DialogInterface.OnClickListener negativeListener = null;

	public AlertFragment() {
		setArguments(new Bundle());
	}

	@NonNull
	@Override
	public Dialog onCreateDialog(Bundle savedInstanceState) {
		final AlertDialog.Builder builder = new AlertDialog.Builder(getActivity());
		builder.setTitle(TextUtils.isEmpty(getArgument(KEY_TITLE)) ? getString(R.string.app_name) : getArgument(KEY_TITLE));
		builder.setMessage(getArgument(KEY_MESSAGE));
		builder.setPositiveButton(TextUtils.isEmpty(getArgument(KEY_POSITIVE_TEXT)) ? getString(android.R.string.ok) : getArgument(KEY_POSITIVE_TEXT),
				hasPositiveListener() ? new DialogInterface.OnClickListener() {
					@Override
					public void onClick(DialogInterface dialogInterface, int i) {
						if (positiveListener != null)
							positiveListener.onClick(dialogInterface, i);
					}
				} : new DialogInterface.OnClickListener() {
					@Override
					public void onClick(DialogInterface dialog, int which) {
						dismiss();
					}
				});
		if (hasNegativeListener())
			builder.setNegativeButton(TextUtils.isEmpty(getArgument(KEY_NEGATIVE_TEXT)) ? getString(android.R.string.cancel) : getArgument(KEY_NEGATIVE_TEXT), new DialogInterface.OnClickListener() {
				@Override
				public void onClick(DialogInterface dialogInterface, int i) {
					if (negativeListener != null)
						negativeListener.onClick(dialogInterface, i);
				}
			});
		final AlertDialog dlg = builder.create();
		dlg.setCanceledOnTouchOutside(false);
		dlg.setOnKeyListener(new DialogInterface.OnKeyListener() {
			@Override
			public boolean onKey(DialogInterface dialog, int keyCode, KeyEvent event) {
				if (keyCode == KeyEvent.KEYCODE_BACK) {
					if (negativeListener != null)
						negativeListener.onClick(dialog, DialogInterface.BUTTON_NEGATIVE);
					else if (positiveListener != null)
						positiveListener.onClick(dialog, DialogInterface.BUTTON_POSITIVE);
				}
				return false;
			}
		});
		return dlg;
	}

	private boolean hasPositiveListener() {
		return getArguments().getBoolean(KEY_POSITIVE_LISTENER, false);
	}

	private boolean hasNegativeListener() {
		return getArguments().getBoolean(KEY_NEGATIVE_LISTENER, false);
	}

	private CharSequence getArgument(String key) {
		int id = -1;
		Object object = getArguments().get(key);
		if (object instanceof Integer)
			id = (Integer) object;
		return id == -1 ? getArguments().getCharSequence(key) : getString(id);
	}

	public AlertFragment setTitle(CharSequence title) {
		getArguments().putCharSequence(KEY_TITLE, title);
		return this;
	}

	public AlertFragment setTitle(int titleId) {
		getArguments().putInt(KEY_TITLE, titleId);
		return this;
	}

	public AlertFragment setMessage(CharSequence message) {
		getArguments().putCharSequence(KEY_MESSAGE, message);
		return this;
	}

	public AlertFragment setMessage(int messageId) {
		getArguments().putInt(KEY_MESSAGE, messageId);
		return this;
	}

	public AlertFragment setPositiveText(CharSequence positiveText) {
		getArguments().putCharSequence(KEY_POSITIVE_TEXT, positiveText);
		return this;
	}

	public AlertFragment setPositiveText(int positiveTextId) {
		getArguments().putInt(KEY_POSITIVE_TEXT, positiveTextId);
		return this;
	}

	public AlertFragment setNegativeText(CharSequence negativeText) {
		getArguments().putCharSequence(KEY_NEGATIVE_TEXT, negativeText);
		return this;
	}

	public AlertFragment setNegativeText(int negativeTextId) {
		getArguments().putInt(KEY_NEGATIVE_TEXT, negativeTextId);
		return this;
	}

	public AlertFragment setPositiveListener(DialogInterface.OnClickListener listener) {
		positiveListener = listener;
		getArguments().putBoolean(KEY_POSITIVE_LISTENER, true);
		return this;
	}

	public AlertFragment setNegativeListener(DialogInterface.OnClickListener listener) {
		negativeListener = listener;
		getArguments().putBoolean(KEY_NEGATIVE_LISTENER, true);
		return this;
	}

	public AlertFragment setTag(String tag) {
		getArguments().putCharSequence(KEY_TAG, tag);
		return this;
	}

	public void show(Activity activity) {
		CharSequence tag = getArgument(KEY_TAG);
		if (TextUtils.isEmpty(tag))
			UiHelper.showDialog(activity, this);
		else
			UiHelper.showDialog(activity, this, tag.toString());
	}

	public static AlertFragment create() {
		return new AlertFragment();
	}
}