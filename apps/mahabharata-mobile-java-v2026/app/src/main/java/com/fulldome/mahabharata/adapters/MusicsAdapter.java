package com.fulldome.mahabharata.adapters;

import android.content.Context;
import android.view.ViewGroup;

import com.fulldome.mahabharata.adapters.holders.MusicHolder;
import com.fulldome.mahabharata.fragments.MusicsFragment;
import com.fulldome.mahabharata.model.Music;
import com.ironwaterstudio.adapters.BaseHolder;
import com.ironwaterstudio.adapters.RecyclerArrayAdapter;

import java.util.ArrayList;

public class MusicsAdapter extends RecyclerArrayAdapter<Music> {
	private final MusicsFragment.GlobalInfo globalInfo;

	public MusicsAdapter(Context context, MusicsFragment.GlobalInfo globalInfo) {
		super(context, new ArrayList<Music>());
		this.globalInfo = globalInfo;
	}

	@Override
	public BaseHolder onCreateViewHolder(ViewGroup parent, int viewType) {
		return new MusicHolder(parent, globalInfo);
	}

	public int indexOf(int id) {
		for (int i = 0; i < getItems().size(); i++) {
			if (getItem(i).getId() == id)
				return i;
		}
		return -1;
	}
}
