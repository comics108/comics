package com.fulldome.mahabharata.fragments;

import android.animation.Animator;
import android.animation.ObjectAnimator;
import android.os.Bundle;
import android.os.Handler;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.LinearInterpolator;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.model.puzzle.Piece;
import com.fulldome.mahabharata.model.puzzle.Puzzle;
import com.fulldome.mahabharata.model.puzzle.Puzzles;
import com.fulldome.mahabharata.screens.PuzzleActivity;
import com.fulldome.mahabharata.server.DataService;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.listeners.CallListener;
import android.animation.AnimatorListenerAdapter;
import com.ironwaterstudio.utils.UiHelper;

public class PuzzlePreviewFragment extends Fragment {
	private static final int QUERY_INTERVAL = 1000;

	private View btnPuzzle;
	private TextView tvPuzzle;
	private ProgressBar progressBar;
	private final Handler handler = new Handler();
	private ObjectAnimator progressAnimator = null;
	private boolean readyToShow = false;

	private CallListener getPuzzlesCallListener = new CallListener(this, false) {
		@Override
		protected void onSuccess(ApiResult result) {
			super.onSuccess(result);
			Puzzles puzzles = result.getData(Puzzles.class);
			if (puzzles.isEmpty())
				return;
			Puzzles.getInstance().update(getActivity(), puzzles);
			updateButtonState();
		}
	};

	private View.OnClickListener puzzleClickListener = new View.OnClickListener() {
		@Override
		public void onClick(View v) {
			if (Puzzles.getInstance().isEmpty())
				return;
			if (readyToShow) {
				UiHelper.showActivity(getActivity(), PuzzleActivity.class);
				return;
			}
			boolean loadStarted = false;
			for (Piece piece : getPuzzle().getPieces()) {
				if (piece.getDownloadInfo() != null)
					continue;
				if (piece.isDownloaded() && piece.getLoadedVersion() < piece.getVersion()) {
					piece.delete(getContext());
					piece.download(getContext(), getPuzzle().getName());
					loadStarted = true;
				}
				if (!piece.isDownloaded()) {
					piece.download(getContext(), getPuzzle().getName());
					loadStarted = true;
				}
			}
			if (loadStarted) {
				Puzzles.getInstance().save(getContext());
				queryDownloads();
			}
		}
	};

	private AnimatorListenerAdapter progressAnimatorListener = new AnimatorListenerAdapter() {
		@Override
		public void onAnimationEnd(Animator animation) {
			super.onAnimationEnd(animation);
			progressAnimator = null;
			if (progressBar.getProgress() < 100)
				return;
			progressBar.postDelayed(new Runnable() {
				@Override
				public void run() {
					updateButtonState();
				}
			}, 300);
		}
	};

	@Nullable
	@Override
	public View onCreateView(LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
		View v = inflater.inflate(R.layout.fragment_puzzle_preview, container, false);
		btnPuzzle = v.findViewById(R.id.btn_puzzle);
		tvPuzzle = v.findViewById(R.id.tv_puzzle);
		progressBar = v.findViewById(R.id.progress_bar);
		return v;
	}

	@Override
	public void onActivityCreated(@Nullable Bundle savedInstanceState) {
		super.onActivityCreated(savedInstanceState);
		getPuzzlesCallListener.register();
		DataService.getPuzzles(getPuzzlesCallListener);
		btnPuzzle.setOnClickListener(puzzleClickListener);
		updateButtonState();
	}

	@Override
	public void onStart() {
		super.onStart();
		queryDownloads();
	}

	@Override
	public void onStop() {
		super.onStop();
		handler.removeCallbacksAndMessages(null);
	}

	private void updateButtonState() {
		if (Puzzles.getInstance().isEmpty()) {
			btnPuzzle.setEnabled(false);
			tvPuzzle.setText(R.string.status_request);
			progressBar.setProgress(0);
			return;
		}
		boolean downloaded = false;
		boolean needUpdate = false;
		for (Piece piece : getPuzzle().getPieces()) {
			if (piece.getDownloadInfo() != null) {
				btnPuzzle.setEnabled(false);
				tvPuzzle.setText("");
				return;
			}
			if (piece.isDownloaded())
				downloaded = true;
			if (!piece.isDownloaded() || piece.getLoadedVersion() < piece.getVersion())
				needUpdate = true;
		}
		readyToShow = downloaded && !needUpdate;
		btnPuzzle.setEnabled(true);
		progressBar.setProgress(0);
		tvPuzzle.setText(!downloaded ? R.string.download : needUpdate ? R.string.update : R.string.puzzle_title);
	}

	private void queryDownloads() {
		handler.removeCallbacksAndMessages(null);
		if (!Puzzles.getInstance().queryDownloads(getContext())) {
			if (!Puzzles.getInstance().isEmpty() && getPuzzle() != null && getPuzzle().hasDownloadInfo()) {
				getPuzzle().clearDownloadInfo();
				animateProgress(100);
			}
			return;
		}

		updateButtonState();
		Puzzles.getInstance().save(getContext());
		updateStep();
		handler.postDelayed(new Runnable() {
			@Override
			public void run() {
				queryDownloads();
			}
		}, QUERY_INTERVAL);
	}

	private void updateStep() {
		int percent = 0;
		int count = 0;
		for (Piece piece : getPuzzle().getPieces()) {
			if (piece.getDownloadInfo() != null) {
				count++;
				percent += piece.getDownloadInfo().getId() == -1 ? 100 : piece.getDownloadInfo().getPercent();
			}
		}
		animateProgress((int) ((percent / (count * 100f)) * 100f));
	}

	private void animateProgress(int percent) {
		if (progressAnimator != null)
			progressAnimator.cancel();
		progressAnimator = ObjectAnimator.ofInt(progressBar, "progress", percent);
		progressAnimator.setInterpolator(new LinearInterpolator());
		progressAnimator.setDuration(200);
		progressAnimator.addListener(progressAnimatorListener);
		progressAnimator.start();
	}

	private static Puzzle getPuzzle() {
		return Puzzles.getInstance().get(PuzzleActivity.PUZZLE_NUMBER);
	}
}
