package com.fulldome.mahabharata.fragments;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.viewpager.widget.ViewPager;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.adapters.EpisodesPagerAdapter;
import com.fulldome.mahabharata.controls.CardPageTransformer;
import com.fulldome.mahabharata.model.Season;
import com.fulldome.mahabharata.model.Seasons;
import com.fulldome.mahabharata.screens.UiConstants;

import java.util.ArrayList;

public class SeasonFragment extends Fragment {
	private ViewPager vpEpisodes;
	private EpisodesPagerAdapter adapter;
	private CardPageTransformer transformer = new CardPageTransformer();

	@Nullable
	@Override
	public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
		View v = inflater.inflate(R.layout.fragment_season, container, false);
		vpEpisodes = v.findViewById(R.id.vp_episodes);
		return v;
	}

	@Override
	public void onActivityCreated(@Nullable Bundle savedInstanceState) {
		super.onActivityCreated(savedInstanceState);
		adapter = new EpisodesPagerAdapter(getChildFragmentManager(), new ArrayList<>());
		vpEpisodes.setAdapter(adapter);
		vpEpisodes.setOffscreenPageLimit(5);
		vpEpisodes.setPageTransformer(true, transformer);
		updateViews();
	}

	public void updateViews() {
		if (adapter == null) {
			return;
		}
		adapter.getEpisodes().clear();
		adapter.getEpisodes().addAll(getSeason().getEpisodes());
		adapter.notifyDataSetChanged();
		adapter.updateData(vpEpisodes, getChildFragmentManager());
		vpEpisodes.post(this::updateTransform);
	}

	private void updateTransform() {
		for (int i = 0; i < vpEpisodes.getChildCount(); i++) {
			final View child = vpEpisodes.getChildAt(i);
			final ViewPager.LayoutParams lp = (ViewPager.LayoutParams) child.getLayoutParams();
			if (lp.isDecor) continue;
			final float transformPos = (float) (child.getLeft() - vpEpisodes.getScrollX())
					/ (vpEpisodes.getMeasuredWidth() - vpEpisodes.getPaddingLeft() - vpEpisodes.getPaddingRight());
			transformer.transformPage(child, transformPos);
		}
	}

	public void updateStates() {
		if (getActivity() != null && !getActivity().isFinishing())
			adapter.updateStates(vpEpisodes, getChildFragmentManager());
	}

	public boolean goToNextEpisode() {
		int current = vpEpisodes.getCurrentItem();
		vpEpisodes.setCurrentItem(current + 1);
		return current < adapter.getCount() - 1;
	}

	private Season getSeason() {
		return Seasons.getInstance().getSeason(getSeasonId());
	}

	public int getSeasonId() {
		return getArguments().getInt(UiConstants.KEY_SEASON_ID);
	}

	public static SeasonFragment newInstance(int seasonId) {
		Bundle bundle = new Bundle();
		bundle.putInt(UiConstants.KEY_SEASON_ID, seasonId);
		SeasonFragment fragment = new SeasonFragment();
		fragment.setArguments(bundle);
		return fragment;
	}
}
