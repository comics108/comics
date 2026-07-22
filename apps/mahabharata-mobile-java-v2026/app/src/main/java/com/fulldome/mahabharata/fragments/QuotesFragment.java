package com.fulldome.mahabharata.fragments;

import android.os.Bundle;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.adapters.QuotesAdapter;
import com.fulldome.mahabharata.decorations.StartEndPaddingDecorations;
import com.fulldome.mahabharata.model.QuoteModel;
import com.fulldome.mahabharata.model.Quotes;
import com.fulldome.mahabharata.server.DataService;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.listeners.CallListener;
import com.ironwaterstudio.utils.UiHelper;

import java.util.ArrayList;

public class QuotesFragment extends Fragment {
	private RecyclerView rvQuotes;
	private QuotesAdapter adapter;

	private CallListener getQuotesCallListener = new CallListener(this, false) {
		@Override
		protected void onSuccess(ApiResult result) {
			super.onSuccess(result);
			adapter.animateTo(result.getData(Quotes.class));
		}
	};

	@Nullable
	@Override
	public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
		View v = inflater.inflate(R.layout.fragment_quotes, container, false);
		rvQuotes = v.findViewById(R.id.rv_quotes);
		return v;
	}

	@Override
	public void onActivityCreated(@Nullable Bundle inState) {
		super.onActivityCreated(inState);
		adapter = new QuotesAdapter(getContext(), new ArrayList<QuoteModel>());
		rvQuotes.setAdapter(adapter);
		rvQuotes.addItemDecoration(new StartEndPaddingDecorations(UiHelper.dpToPx(getContext(), 8)));
		getQuotesCallListener.register();
		DataService.getQuotes(getQuotesCallListener);
	}
}
