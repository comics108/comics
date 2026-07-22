package com.fulldome.mahabharata.adapters;

import android.content.Context;
import android.view.ViewGroup;

import com.fulldome.mahabharata.adapters.holders.QuoteHolder;
import com.fulldome.mahabharata.model.QuoteModel;
import com.ironwaterstudio.adapters.BaseHolder;
import com.ironwaterstudio.adapters.RecyclerArrayAdapter;

import java.util.ArrayList;

public class QuotesAdapter extends RecyclerArrayAdapter<QuoteModel> {
	public QuotesAdapter(Context context, ArrayList<QuoteModel> items) {
		super(context, items);
	}

	@Override
	public BaseHolder onCreateViewHolder(ViewGroup parent, int viewType) {
		return new QuoteHolder(parent);
	}
}
