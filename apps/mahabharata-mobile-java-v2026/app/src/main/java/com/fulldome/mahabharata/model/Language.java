package com.fulldome.mahabharata.model;

import androidx.annotation.FontRes;

import com.fulldome.mahabharata.R;

public enum Language {
	EN(R.string.en, R.font.proxima_medium),
	RU(R.string.ru, R.font.proxima_medium);//,
//	HINDI(R.string.hindi, R.font.hindi); TODO return this code

	private int resId;

	@FontRes
	private int font;

	Language(int resId, @FontRes int font) {
		this.resId = resId;
		this.font = font;
	}

	public int getResId() {
		return resId;
	}

	@FontRes
	public int getFont() {
		return font;
	}
}
