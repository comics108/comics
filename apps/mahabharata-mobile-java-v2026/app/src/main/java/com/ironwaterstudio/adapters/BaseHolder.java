package com.ironwaterstudio.adapters;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.LayoutRes;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

public abstract class BaseHolder<Model> extends RecyclerView.ViewHolder {
	private Model model;

	public Context getContext() {
		return itemView.getContext();
	}

	public Model getModel() {
		return model;
	}

	public BaseHolder(@LayoutRes final int resId, @NonNull final ViewGroup parent) {
		this(LayoutInflater.from(parent.getContext()).inflate(resId, parent, false));
	}

	public BaseHolder(@NonNull final View itemView) {
		super(itemView);
	}

	public void update(final Model item) {
		model = item;
	}

	public void update(final Model item, final List<Object> payloads) {
		model = item;
	}

	public void onAttach() {
	}

	public void onDetach() {
	}
}
