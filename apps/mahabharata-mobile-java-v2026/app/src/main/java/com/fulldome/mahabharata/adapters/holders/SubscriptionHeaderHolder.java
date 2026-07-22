package com.fulldome.mahabharata.adapters.holders;

import android.view.ViewGroup;
import android.widget.TextView;

import com.fulldome.mahabharata.R;
import com.ironwaterstudio.adapters.BaseHolder;

public class SubscriptionHeaderHolder extends BaseHolder<String> {
	private TextView tvHelpfulText;

	public SubscriptionHeaderHolder(ViewGroup parent) {
		super(R.layout.item_subscription_header, parent);
		tvHelpfulText = (TextView) itemView;
	}

	@Override
	public void update(String item) {
		super.update(item);
		tvHelpfulText.setText(item);
	}
}
