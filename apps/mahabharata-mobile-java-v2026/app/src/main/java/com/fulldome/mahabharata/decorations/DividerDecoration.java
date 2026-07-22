package com.fulldome.mahabharata.decorations;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.view.View;

import androidx.annotation.ColorRes;
import androidx.annotation.DimenRes;
import androidx.annotation.IntDef;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.ironwaterstudio.adapters.BaseHolder;
import com.ironwaterstudio.adapters.RecyclerArrayAdapter;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.util.ArrayList;
import java.util.Collections;

public class DividerDecoration extends RecyclerView.ItemDecoration {
	@Retention(RetentionPolicy.SOURCE)
	@IntDef(flag = true, value = {MIDDLE, TOP, BOTTOM, CUSTOM})
	public @interface Params {
	}

	public static final int MIDDLE = 1;
	public static final int TOP = 2;
	public static final int BOTTOM = 4;
	public static final int CUSTOM = 8;

	private final Paint paint;
	private int leftOffset;
	private int params;
	private ArrayList<Integer> exceptions = new ArrayList<>();
	private DrawingRules drawingRules = null;

	public DividerDecoration(Context context, @ColorRes int colorId, @DimenRes int sizeId, int leftOffset, @Params int params) {
		this(ContextCompat.getColor(context, colorId), Math.max(context.getResources().getDimensionPixelOffset(sizeId), 2), leftOffset, params, null);
	}

	public DividerDecoration(Context context, @ColorRes int colorId, @DimenRes int sizeId, int leftOffset, DrawingRules drawingRules) {
		this(ContextCompat.getColor(context, colorId), Math.max(context.getResources().getDimensionPixelOffset(sizeId), 2), leftOffset, CUSTOM, drawingRules);
	}

	public DividerDecoration(int color, int size, int leftOffset, @Params int params, DrawingRules drawingRules) {
		this.leftOffset = leftOffset;
		this.params = params;
		this.drawingRules = drawingRules;
		paint = new Paint();
		paint.setColor(color);
		paint.setStrokeWidth(size);
	}

	public void setColor(int color) {
		paint.setColor(color);
	}

	public void setParams(@Params int params) {
		this.params = params;
	}

	public DividerDecoration addException(Integer... index) {
		Collections.addAll(exceptions, index);
		return this;
	}

	public void setDrawingRules(DrawingRules drawingRules) {
		this.drawingRules = drawingRules;
	}

	@Override
	public void onDraw(Canvas canvas, RecyclerView parent, RecyclerView.State state) {
		RecyclerView.Adapter adapter = parent.getAdapter();
		if (adapter == null || !(adapter instanceof RecyclerArrayAdapter))
			return;
		RecyclerArrayAdapter arrayAdapter = (RecyclerArrayAdapter) adapter;
		int childCount = parent.getChildCount();
		for (int i = 0; i < childCount; i++) {
			View child = parent.getChildAt(i);
			RecyclerView.ViewHolder holder = parent.getChildViewHolder(child);
			if (holder == null || !(holder instanceof BaseHolder) ||
				holder.getAdapterPosition() == RecyclerView.NO_POSITION || isException(holder.getAdapterPosition())) {
				continue;
			}
			BaseHolder baseHolder = (BaseHolder) holder;
			int offset = (int) (paint.getStrokeWidth() / 2f);
			if (needDrawToTop(arrayAdapter, baseHolder.getModel(), baseHolder.getAdapterPosition())) {
				canvas.drawLine(child.getLeft() + leftOffset, child.getTop() - offset, child.getRight(),
					child.getTop() - offset, paint);
			}
			if (needDrawToBottom(arrayAdapter, baseHolder.getModel(), baseHolder.getAdapterPosition())) {
				canvas.drawLine(child.getLeft() + leftOffset, child.getBottom() + offset, child.getRight(),
					child.getBottom() + offset, paint);
			}
		}
	}

	private boolean needDrawToTop(RecyclerArrayAdapter adapter, Object model, int position) {
		boolean isFirstItem = position == 0;
		if (getParam(CUSTOM) && drawingRules != null)
			return drawingRules.needDrawToTop(adapter, model, position)
					&& (isFirstItem || !drawingRules.needDrawToBottom(adapter, adapter.getItem(position - 1), position - 1));
		return getParam(TOP) && isFirstItem;
	}

	private boolean needDrawToBottom(RecyclerArrayAdapter adapter, Object model, int position) {
		if (getParam(CUSTOM) && drawingRules != null)
			return drawingRules.needDrawToBottom(adapter, model, position);
		if (position >= (adapter.getItems().size()))
			return false;
		boolean isLastItem = position == adapter.getItemCount() - 1;
		return getParam(MIDDLE) && !isLastItem || getParam(BOTTOM) && isLastItem;
	}

	private boolean isException(int index) {
		for (Integer exception : exceptions) {
			if (index == exception)
				return true;
		}
		return false;
	}

	private boolean getParam(int type) {
		return (params & type) > 0;
	}

	@Override
	public void getItemOffsets(Rect outRect, View view, RecyclerView parent, RecyclerView.State state) {
		if (params == 0) {
			outRect.setEmpty();
			return;
		}
		RecyclerView.ViewHolder holder = parent.getChildViewHolder(view);
		RecyclerView.Adapter adapter = parent.getAdapter();
		if (adapter == null || !(adapter instanceof RecyclerArrayAdapter) || holder == null ||
			!(holder instanceof BaseHolder) || holder.getAdapterPosition() == RecyclerView.NO_POSITION) {
			outRect.setEmpty();
			return;
		}
		RecyclerArrayAdapter arrayAdapter = (RecyclerArrayAdapter) adapter;
		BaseHolder baseHolder = (BaseHolder) holder;
		outRect.set(0, needDrawToTop(arrayAdapter, baseHolder.getModel(), baseHolder.getAdapterPosition())
				? (int) paint.getStrokeWidth()
				: 0,
			0, needDrawToBottom(arrayAdapter, baseHolder.getModel(), baseHolder.getAdapterPosition())
				? (int) paint.getStrokeWidth()
				: 0);
	}

	public interface DrawingRules {
		boolean needDrawToTop(RecyclerArrayAdapter adapter, Object model, int position);

		boolean needDrawToBottom(RecyclerArrayAdapter adapter, Object model, int position);
	}
}
