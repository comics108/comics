package com.fulldome.mahabharata.adapters;

import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentPagerAdapter;
import androidx.viewpager.widget.ViewPager;

import com.fulldome.mahabharata.fragments.EpisodeFragment;
import com.fulldome.mahabharata.model.Episode;

import java.util.ArrayList;

public class EpisodesPagerAdapter extends FragmentPagerAdapter {
	private final ArrayList<Episode> episodes;

	public EpisodesPagerAdapter(FragmentManager fm, ArrayList<Episode> episodes) {
		super(fm);
		this.episodes = episodes;
	}

	public ArrayList<Episode> getEpisodes() {
		return episodes;
	}

	@Override
	public Fragment getItem(int position) {
		return EpisodeFragment.newInstance(episodes.get(position).getId());
	}

	@Override
	public int getCount() {
		return episodes.size();
	}

	@Override
	public int getItemPosition(Object object) {
		return indexOf(((EpisodeFragment) object).getEpisodeId());
	}

	@Override
	public long getItemId(int position) {
		return episodes.get(position).getId();
	}

	public int indexOf(int episodeId) {
		for (int i = 0; i < episodes.size(); i++) {
			if (episodes.get(i).getId() == episodeId)
				return i;
		}
		return POSITION_NONE;
	}

	public void updateData(ViewPager viewPager, FragmentManager manager) {
		for (int i = 0; i < getCount(); i++) {
			Fragment fragment = manager.findFragmentByTag(getFragmentTag(viewPager, i));
			if (fragment != null && fragment instanceof EpisodeFragment)
				((EpisodeFragment) fragment).updateViews();
		}
	}

	public void updateStates(ViewPager viewPager, FragmentManager manager) {
		for (int i = 0; i < getCount(); i++) {
			Fragment fragment = manager.findFragmentByTag(getFragmentTag(viewPager, i));
			if (fragment != null && fragment instanceof EpisodeFragment)
				((EpisodeFragment) fragment).updateState();
		}
	}

	private String getFragmentTag(ViewPager viewPager, int position) {
		return "android:switcher:" + viewPager.getId() + ":" + getItemId(position);
	}
}
