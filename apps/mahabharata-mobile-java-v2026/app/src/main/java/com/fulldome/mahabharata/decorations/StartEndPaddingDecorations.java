package com.fulldome.mahabharata.decorations;

import android.graphics.Rect;
import androidx.recyclerview.widget.RecyclerView;
import android.view.View;

public class StartEndPaddingDecorations extends RecyclerView.ItemDecoration {
	private final int padding;

	public StartEndPaddingDecorations(int padding) {
		this.padding = padding;
	}

	@Override
	public void getItemOffsets(Rect outRect, View view, RecyclerView parent, RecyclerView.State state) {
		super.getItemOffsets(outRect, view, parent, state);
		RecyclerView.ViewHolder holder = parent.getChildViewHolder(view);
		outRect.top = holder != null && holder.getAdapterPosition() == 0 ? padding : 0;
		outRect.bottom = holder != null && parent.getAdapter() != null && holder.getAdapterPosition() == parent.getAdapter().getItemCount() - 1 ? padding : 0;
	}
}
