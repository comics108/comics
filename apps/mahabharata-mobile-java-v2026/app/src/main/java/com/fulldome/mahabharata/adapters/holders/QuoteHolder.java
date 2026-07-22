package com.fulldome.mahabharata.adapters.holders;

import android.app.Activity;
import android.view.View;
import android.view.ViewGroup;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.dialogs.ShareQuoteDialog;
import com.fulldome.mahabharata.fragments.EpisodeFragment;
import com.fulldome.mahabharata.model.QuoteModel;
import com.fulldome.mahabharata.utils.ImageCallListener;
import com.ironwaterstudio.adapters.BaseHolder;
import com.ironwaterstudio.controls.ImageViewEx;

public class QuoteHolder extends BaseHolder<QuoteModel> {
	private ImageViewEx ivQuote;
	private View btnShare;

	private View.OnClickListener shareClickListener = new View.OnClickListener() {
		@Override
		public void onClick(View v) {
            ShareQuoteDialog.show((Activity) getContext(), getModel().getImage());
        }
	};

	public QuoteHolder(ViewGroup parent) {
		super(R.layout.item_quote, parent);
		ivQuote = itemView.findViewById(R.id.iv_quote);
		btnShare = itemView.findViewById(R.id.btn_share);
		btnShare.setOnClickListener(shareClickListener);
		ViewGroup.LayoutParams params = ivQuote.getLayoutParams();
		params.height = getContext().getResources().getDisplayMetrics().widthPixels - getContext().getResources().getDimensionPixelSize(R.dimen.quote_margin) * 2;

		params = btnShare.getLayoutParams();
		params.width = EpisodeFragment.getPosterWidth(getContext());
		btnShare.requestLayout();
	}

	@Override
	public void update(QuoteModel item) {
        super.update(item);
        ivQuote.setImage(getModel().getImage(), new ImageCallListener(ivQuote));
    }
}
