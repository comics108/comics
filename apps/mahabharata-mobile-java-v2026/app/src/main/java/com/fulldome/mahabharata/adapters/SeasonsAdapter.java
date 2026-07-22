package com.fulldome.mahabharata.adapters;

import android.content.Context;
import android.view.ViewGroup;

import com.fulldome.mahabharata.adapters.holders.SeasonHolder;
import com.fulldome.mahabharata.model.Season;
import com.ironwaterstudio.adapters.BaseHolder;
import com.ironwaterstudio.adapters.RecyclerArrayAdapter;

import java.util.ArrayList;

public class SeasonsAdapter extends RecyclerArrayAdapter<Season> {
	public SeasonsAdapter(Context context, ArrayList<Season> items) {
		super(context, items);
	}

	@Override
	public BaseHolder onCreateViewHolder(ViewGroup parent, int viewType) {
		return new SeasonHolder(parent);
	}
}
