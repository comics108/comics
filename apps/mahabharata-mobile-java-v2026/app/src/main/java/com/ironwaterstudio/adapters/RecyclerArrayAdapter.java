package com.ironwaterstudio.adapters;

import android.content.Context;

import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

public abstract class RecyclerArrayAdapter<Model> extends RecyclerView.Adapter<BaseHolder> {
    private final Context context;
    private final List<Model> items;
    private OnScrollToLastItemListener onScrollToLastItemListener;

    public RecyclerArrayAdapter(final Context context, final List<Model> items) {
        this.context = context;
        this.items = items;
    }

    public Context getContext() {
        return context;
    }

    public OnScrollToLastItemListener getOnScrollToLastItemListener() {
        return onScrollToLastItemListener;
    }

    public void setOnScrollToLastItemListener(final OnScrollToLastItemListener onScrollToLastItemListener) {
        this.onScrollToLastItemListener = onScrollToLastItemListener;
    }

    public List<Model> getItems() {
        return items;
    }

    public Model getItem(final int position) {
        return items.get(position);
    }

    public Model removeItem(final int position) {
        final Model model = items.remove(position);
        notifyItemRemoved(toNotifyPosition(position));
        return model;
    }

    public int indexOf(final Model item) {
        for (int i = 0; i < getItems().size(); i++) {
            if (getItem(i).equals(item)) {
                return i;
            }
        }
        return -1;
    }

    public void clear() {
        final int size = items.size();
        items.clear();
        notifyItemRangeRemoved(0, size);
    }

    public void addItem(final Model model) {
        addItem(getItems().size(), model);
    }

    public void addItem(final int position, final Model model) {
        items.add(position, model);
        notifyItemInserted(toNotifyPosition(position));
    }

    public void addAll(final List<Model> models) {
        addAll(getItems().size(), models);
    }

    public void addAll(int position, final List<Model> models) {
        for (int i = 0; i < models.size(); i++) {
            addItem(position++, models.get(i));
        }
    }

    public void moveItem(final int fromPosition, final int toPosition) {
        final Model model = items.remove(fromPosition);
        items.add(toPosition, model);
        notifyItemMoved(toNotifyPosition(fromPosition), toNotifyPosition(toPosition));
    }

    @SuppressWarnings("unchecked")
    @Override
    public void onBindViewHolder(final BaseHolder holder, final int position) {
        holder.update(getItem(toItemsPosition(position)));
    }

    @SuppressWarnings("unchecked")
    @Override
    public void onBindViewHolder(final BaseHolder holder, final int position, final List<Object> payloads) {
        if (payloads != null && !payloads.isEmpty()) {
            holder.update(getItem(toItemsPosition(position)), payloads);
        } else {
            super.onBindViewHolder(holder, position, payloads);
        }
    }

    public int toNotifyPosition(final int position) {
        return position;
    }

    public int toItemsPosition(final int position) {
        return position;
    }

    @Override
    public int getItemCount() {
        return items.size();
    }

    public boolean isEmpty() {
        return getItemCount() <= 0;
    }

    @Override
    public void onViewAttachedToWindow(final BaseHolder holder) {
        super.onViewAttachedToWindow(holder);
        holder.onAttach();
        if (onScrollToLastItemListener != null && holder.getAdapterPosition() == getItemCount() - 1) {
            onScrollToLastItemListener.onScrollToLastItem(holder);
        }
    }

    @Override
    public void onViewDetachedFromWindow(final BaseHolder holder) {
        super.onViewDetachedFromWindow(holder);
        holder.onDetach();
    }

    public void animateTo(final List<Model> models) {
        applyAndAnimateRemovals(models);
        applyAndAnimateAdditions(models);
        applyAndAnimateMovedItems(models);
    }

    private void applyAndAnimateRemovals(final List<Model> newModels) {
        for (int i = items.size() - 1; i >= 0; i--) {
            final Model model = items.get(i);
            if (!newModels.contains(model)) {
                removeItem(i);
            }
        }
    }

    private void applyAndAnimateAdditions(final List<Model> newModels) {
        for (int i = 0, count = newModels.size(); i < count; i++) {
            final Model model = newModels.get(i);
            if (!items.contains(model)) {
                addItem(i, model);
            }
        }
    }

    private void applyAndAnimateMovedItems(final List<Model> newModels) {
        for (int toPosition = newModels.size() - 1; toPosition >= 0; toPosition--) {
            final Model model = newModels.get(toPosition);
            final int fromPosition = items.indexOf(model);
            if (fromPosition >= 0 && fromPosition != toPosition) {
                moveItem(fromPosition, toPosition);
            }
        }
    }

    public interface OnScrollToLastItemListener {
        void onScrollToLastItem(RecyclerView.ViewHolder holder);
    }
}

