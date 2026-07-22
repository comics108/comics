package com.ironwaterstudio.adapters;

import android.content.Context;

import java.util.ArrayList;
import java.util.List;

public abstract class HeaderArrayAdapter<Model, Header> extends RecyclerArrayAdapter<Model> {
	public static final int HEADER_TYPE = -1;
	private Header header = null;
	boolean headerInit = false;

	public HeaderArrayAdapter(Context context, ArrayList<Model> items) {
		super(context, items);
	}

	@Override
	public int toNotifyPosition(int position) {
		return header == null ? position : position + 1;
	}

	@Override
	public int toItemsPosition(int position) {
		return header == null ? position : position - 1;
	}

	@Override
	public int getItemCount() {
		return header == null ? super.getItemCount() : super.getItemCount() + 1;
	}

	@SuppressWarnings("unchecked")
	@Override
	public void onBindViewHolder(BaseHolder holder, int position) {
		if (header != null && position == 0) {
			if (!headerInit)
				((BaseHolder<Header>) holder).update(header);
			headerInit = true;
			return;
		}
		super.onBindViewHolder(holder, position);
	}

	@SuppressWarnings("unchecked")
	@Override
	public void onBindViewHolder(BaseHolder holder, int position, List<Object> payloads) {
		if (header != null && position == 0 && payloads != null && !payloads.isEmpty()) {
			((BaseHolder<Header>) holder).update(header, payloads);
			return;
		}
		super.onBindViewHolder(holder, position, payloads);
	}

	@Override
	public int getItemViewType(int position) {
		return header != null && position == 0 ? HEADER_TYPE : super.getItemViewType(position);
	}

	public Header getHeader() {
		return header;
	}

	public void setHeader(Header header) {
		boolean headerAlreadyExists = this.header != null;
		this.header = header;
		headerInit = false;
		if (headerAlreadyExists && header != null)
			notifyItemChanged(0);
		if (headerAlreadyExists && header == null)
			notifyItemRemoved(0);
		if (!headerAlreadyExists && header != null)
			notifyItemInserted(0);
	}

	public void notifyHeaderChanged() {
		headerInit = false;
		notifyItemChanged(0);
	}

	public void notifyHeaderChanged(Object payload) {
		headerInit = false;
		notifyItemChanged(0, payload);
	}
}
