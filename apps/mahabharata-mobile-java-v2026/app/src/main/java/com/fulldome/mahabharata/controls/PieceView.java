package com.fulldome.mahabharata.controls;

import android.annotation.SuppressLint;
import android.content.Context;
import androidx.annotation.NonNull;
import android.view.View;

import com.fulldome.mahabharata.model.puzzle.Piece;

@SuppressLint("ViewConstructor")
public class PieceView extends LayersView {
	private Piece piece;

	public PieceView(@NonNull Context context, Piece piece) {
		super(context, piece.getComics());
		this.piece = piece;
		updateState();
	}

	public Piece getPiece() {
		return piece;
	}

	public void setPiece(Piece piece) {
		this.piece = piece;
		updateState();
		setComics(piece.getComics());
	}

	@Override
	public void onUpdate(float scale, int scrollX, int scrollY, int extendedX, int extendedY) {
		int scrollArea = extendedX + getWidth();
		int scroll = (int) (scrollX + extendedX - getX());
		float percent = (float) scroll / (float) scrollArea;
		int finalScroll = (int) (getWidth() * percent);
		if (getComics() != null)
			getComics().process(finalScroll);
		for (int i = 0; i < getChildCount(); i++) {
			View view = getChildAt(i);
			if (view instanceof ZoomFrameLayout.ZoomableView)
				((ZoomFrameLayout.ZoomableView) view).onUpdate(scale, (int) (scrollX - getX()), (int) (scrollY - getY()), getWidth(), getHeight());
			view.invalidate();
		}
	}

	@Override
	protected boolean needShowPreview() {
		return getComics().hasPreview() && piece.isShowPreview();
	}

	@Override
	public void initLayers() {
		if (piece != null && piece.isDownloaded())
			super.initLayers();
		else
			removeLayers();
	}

	public void updateState() {
		initLayers();
	}
}
