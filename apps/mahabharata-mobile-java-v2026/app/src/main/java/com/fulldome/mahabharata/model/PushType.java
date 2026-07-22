package com.fulldome.mahabharata.model;

import android.text.TextUtils;

public enum PushType {
	NONE(Menu.COMICS),
	//QUOTE(Menu.QUOTES),
	COMICS(Menu.COMICS),
	PUZZLE(Menu.COMICS);
	//MUSIC(Menu.MUSICS);

	private Menu menu;

	PushType(Menu menu) {
		this.menu = menu;
	}

	public Menu getMenu() {
		return menu;
	}

	public static PushType parse(String number) {
		if (TextUtils.isEmpty(number) || !TextUtils.isDigitsOnly(number))
			return NONE;

		Integer ordinal = Integer.parseInt(number);
		return ordinal >= 0 && ordinal < values().length ? values()[ordinal] : NONE;
	}
}
