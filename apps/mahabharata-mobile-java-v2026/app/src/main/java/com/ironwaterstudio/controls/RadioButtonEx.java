package com.ironwaterstudio.controls;

import android.annotation.SuppressLint;
import android.content.Context;
import androidx.annotation.FontRes;
import androidx.core.content.res.ResourcesCompat;
import androidx.appcompat.widget.AppCompatRadioButton;
import androidx.appcompat.widget.TintTypedArray;
import android.util.AttributeSet;

import com.fulldome.mahabharata.R;

public class RadioButtonEx extends AppCompatRadioButton {
	public RadioButtonEx(Context context) {
		super(context);
		setFont(R.font.proxima_regular);
	}

	public RadioButtonEx(Context context, AttributeSet attrs) {
		this(context, attrs, R.attr.radioButtonStyle);
	}

	@SuppressLint("RestrictedApi, PrivateResource")
	public RadioButtonEx(Context context, AttributeSet attrs, int defStyleAttr) {
		super(context, attrs, defStyleAttr);
		TintTypedArray a = TintTypedArray.obtainStyledAttributes(context, attrs, androidx.appcompat.R.styleable.TextAppearance, defStyleAttr, 0);
		setFont(a.getResourceId(androidx.appcompat.R.styleable.TextAppearance_fontFamily, R.font.proxima_regular));
		a.recycle();
	}

	public void setFont(@FontRes int fontResId) {
		setTypeface(ResourcesCompat.getFont(getContext(), fontResId));
	}
}
