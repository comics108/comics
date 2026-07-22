package com.fulldome.mahabharata.model;

import android.content.Context;
import androidx.annotation.StringRes;
import androidx.fragment.app.Fragment;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.fragments.SeasonsFragment;

import java.io.Serializable;

public enum Menu implements Serializable {
	//COMICS(R.string.comics, SeasonsFragment.class),
	//MUSICS(R.string.musics, MusicsFragment.class),
	//PUZZLE(R.string.puzzle, PuzzlePreviewFragment.class),
	//QUOTES(R.string.quotes, QuotesFragment.class);

	COMICS(R.string.comics, SeasonsFragment.class);

	@StringRes
	private int titleId;

	private Class<? extends Fragment> tClass;

	Menu(int titleId, Class<? extends Fragment> tClass) {
		this.titleId = titleId;
		this.tClass = tClass;
	}

	public String getTitle(Context context) {
		return context.getString(titleId);
	}

	public Fragment newInstance() {
		try {
			return tClass.newInstance();
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	public static int indexOf(Class<? extends Fragment> tClass) {
		for (int i = 0; i < values().length; i++) {
			if (values()[i].tClass == tClass)
				return i;
		}
		return -1;
	}
}
