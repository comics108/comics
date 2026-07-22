package com.fulldome.mahabharata.dialogs;

import android.app.Dialog;
import android.content.Context;
import android.graphics.Bitmap;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.fragment.app.DialogFragment;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.screens.UiConstants;
import com.ironwaterstudio.server.CacheManager;
import com.ironwaterstudio.utils.UiHelperCompat;

public class PopupDialog extends DialogFragment {
	private View frame;
	private ImageView ivPopup;

	private View.OnClickListener popupClickListener = new View.OnClickListener() {
		@Override
		public void onClick(View v) {
			dismiss();
		}
	};

	@NonNull
	@Override
	public Dialog onCreateDialog(Bundle savedInstanceState) {
		Dialog dialog = new Dialog(getActivity(), R.style.Dialog);
		dialog.getWindow().setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT);
		dialog.setContentView(R.layout.dialog_popup);
		frame = dialog.findViewById(R.id.frame);
		ivPopup = dialog.findViewById(R.id.iv_popup);

		frame.setOnClickListener(popupClickListener);
		ivPopup.setOnClickListener(popupClickListener);
		Bitmap bitmap = CacheManager.getBitmapCache().get(getImage());
		if (bitmap == null)
			dismiss();
		else
			ivPopup.setImageBitmap(bitmap);
		return dialog;
	}

	private String getImage() {
		return getArguments().getString(UiConstants.KEY_IMAGE);
	}

	public static void show(Context context, String image) {
		PopupDialog dialog = new PopupDialog();
		Bundle args = new Bundle();
		args.putString(UiConstants.KEY_IMAGE, image);
		dialog.setArguments(args);
		UiHelperCompat.showDialog(context, dialog);
	}
}
