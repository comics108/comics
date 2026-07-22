package com.fulldome.mahabharata.adapters;

import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentPagerAdapter;

import com.fulldome.mahabharata.model.Menu;

public class MenuPagerAdapter extends FragmentPagerAdapter {
	public MenuPagerAdapter(FragmentManager fm) {
		super(fm);
	}

	@Override
	public Fragment getItem(int position) {
		return Menu.values()[position].newInstance();
	}

	@Override
	public int getCount() {
		return Menu.values().length;
	}

	@Override
	@SuppressWarnings("unchecked")
	public int getItemPosition(Object object) {
		int index = Menu.indexOf((Class<? extends Fragment>) object.getClass());
		return index != -1 ? index : POSITION_NONE;
	}

	@Override
	public long getItemId(int position) {
		return Menu.values()[position].ordinal();
	}
}
