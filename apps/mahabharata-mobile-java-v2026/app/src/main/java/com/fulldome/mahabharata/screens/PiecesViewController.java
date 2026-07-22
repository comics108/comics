package com.fulldome.mahabharata.screens;

import android.app.Activity;
import android.graphics.Bitmap;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.controls.PieceView;
import com.fulldome.mahabharata.controls.SoundBadge;
import com.fulldome.mahabharata.controls.TileImageView;
import com.fulldome.mahabharata.controls.ZoomFrameLayout;
import com.fulldome.mahabharata.dialogs.PopupDialog;
import com.fulldome.mahabharata.model.Settings;
import com.fulldome.mahabharata.model.puzzle.Piece;
import com.fulldome.mahabharata.model.puzzle.Puzzle;
import com.fulldome.mahabharata.model.puzzle.Puzzles;
import com.fulldome.mahabharata.model.visual.Layer;
import com.fulldome.mahabharata.utils.ComicsUtils;
import com.fulldome.mahabharata.utils.ImageManager;
import com.ironwaterstudio.server.data.ApiResult;

import static com.fulldome.mahabharata.screens.PuzzleActivity.PUZZLE_NUMBER;

public class PiecesViewController {
	private final Activity activity;
	private final ZoomFrameLayout zoomLayout;
	private final SoundBadge soundBadge;
	private final GestureDetector gestureDetector;
	private boolean blockGeneralSingleTap = false;

	private GestureDetector.SimpleOnGestureListener gestureListener = new GestureDetector.SimpleOnGestureListener() {
		@Override
		public boolean onSingleTapConfirmed(MotionEvent e) {
			if (blockGeneralSingleTap) {
				blockGeneralSingleTap = false;
				return false;
			}
			if (Puzzles.getInstance().isEmpty())
				return false;

			Puzzle puzzle = Puzzles.getInstance().get(PUZZLE_NUMBER);
			puzzle.toggleSounds();
			invalidateAll();
			soundBadge.show(Settings.getInstance().isSoundOn());
			return super.onSingleTapConfirmed(e);
		}
	};

	private ComicsUtils.OnHitToLayerListener singleTapHitListener = new ComicsUtils.OnHitToLayerListener() {
		@Override
		public void onHit(PieceView pieceView, TileImageView imageView, Layer layer) {
			if (pieceView != null && pieceView.getPiece().isShowPreview()) {
				pieceView.getPiece().setShowPreview(false);
				Puzzles.getInstance().save(activity);
				pieceView.animateReloadLayers();
				zoomLayout.post(new Runnable() {
					@Override
					public void run() {
						zoomLayout.invalidateAll();
					}
				});
				blockGeneralSingleTap = true;
			}
		}
	};

	private ComicsUtils.OnHitToLayerListener longTapHitListener = new ComicsUtils.OnHitToLayerListener() {
		@Override
		public void onHit(final PieceView pieceView, TileImageView imageView, final Layer layer) {
			Bitmap bitmap = ImageManager.getBitmap(pieceView.getComics().getDescriptor(), layer.getPopup(), 1, new ImageManager.ImageCallListener() {
				@Override
				protected void onSuccess(ApiResult result) {
					super.onSuccess(result);
					PopupDialog.show(activity, ImageManager.buildKey(pieceView.getComics().getDescriptor(), layer.getPopup()));
				}
			});
			if (bitmap != null)
				PopupDialog.show(activity, ImageManager.buildKey(pieceView.getComics().getDescriptor(), layer.getPopup()));
		}
	};

	private GestureDetector.SimpleOnGestureListener transformedGestureListener = new GestureDetector.SimpleOnGestureListener() {
		@Override
		public boolean onSingleTapConfirmed(MotionEvent e) {
			ComicsUtils.checkHit(zoomLayout, e, singleTapHitListener);
			return true;
		}

		@Override
		public void onLongPress(MotionEvent e) {
			ComicsUtils.checkHit(zoomLayout, e, longTapHitListener);
		}
	};

	public PiecesViewController(Activity activity) {
		this.activity = activity;
		this.zoomLayout = activity.findViewById(R.id.zoom_layout);
		this.soundBadge = activity.findViewById(R.id.sound_badge);
		zoomLayout.setGestureListener(gestureListener);
		gestureDetector = new GestureDetector(activity, transformedGestureListener);
		zoomLayout.setOnTouchListener(new View.OnTouchListener() {
			@Override
			public boolean onTouch(View v, MotionEvent event) {
				return gestureDetector.onTouchEvent(event);
			}
		});
	}

	public void updateAllStates() {
		updateState(null);
	}

	public void updateState(Piece piece) {
		for (int i = 0; i < zoomLayout.getChildCount(); i++) {
			View view = zoomLayout.getChildAt(i);
			if (view instanceof PieceView && piece == null) {
				((PieceView) view).updateState();
			} else if (view instanceof PieceView && piece.equals(((PieceView) view).getPiece())) {
				((PieceView) view).updateState();
				break;
			}
		}
		invalidateAll();
	}

	public void updateAllViews() {
		if (Puzzles.getInstance().isEmpty())
			return;
		Puzzle puzzle = Puzzles.getInstance().get(PUZZLE_NUMBER);
		zoomLayout.setContentSize(puzzle.getWidth(), puzzle.getHeight());
		for (int i = 0; i < zoomLayout.getChildCount(); i++) {
			View view = zoomLayout.getChildAt(i);
			if (view instanceof PieceView && !puzzle.contains(((PieceView) view).getPiece().getId()))
				zoomLayout.removeView(view);
		}
		for (Piece piece : puzzle.getPieces()) {
			PieceView view = findPieceView(piece.getId());
			if (view != null)
				updatePieceView(view, piece);
			else
				addNewPieceView(piece);
		}
		invalidateAll();
	}

	public void invalidateAll() {
		zoomLayout.invalidateAll();
	}

	public void postInvalidateAll() {
		zoomLayout.post(new Runnable() {
			@Override
			public void run() {
				invalidateAll();
			}
		});
		zoomLayout.postDelayed(new Runnable() {
			@Override
			public void run() {
				zoomLayout.invalidateAll();
			}
		}, 100);
	}

	private PieceView findPieceView(int id) {
		for (int i = 0; i < zoomLayout.getChildCount(); i++) {
			View view = zoomLayout.getChildAt(i);
			if (view instanceof PieceView && ((PieceView) view).getPiece().getId() == id)
				return (PieceView) view;
		}
		return null;
	}

	private void updatePieceView(PieceView view, Piece piece) {
		view.setPiece(piece);
		FrameLayout.LayoutParams params = (FrameLayout.LayoutParams) view.getLayoutParams();
		params.width = piece.getWidth();
		params.height = piece.getHeight();
		params.leftMargin = piece.getX();
		params.topMargin = piece.getY();
	}

	private void addNewPieceView(Piece piece) {
		FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(piece.getWidth(), piece.getHeight());
		params.leftMargin = piece.getX();
		params.topMargin = piece.getY();
		zoomLayout.addView(new PieceView(zoomLayout.getContext(), piece), params);
	}
}
