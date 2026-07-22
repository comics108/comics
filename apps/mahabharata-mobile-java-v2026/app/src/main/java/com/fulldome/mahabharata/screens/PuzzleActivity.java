package com.fulldome.mahabharata.screens;

import android.os.Bundle;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.model.InitDescriptorResult;
import com.fulldome.mahabharata.model.puzzle.Puzzle;
import com.fulldome.mahabharata.model.puzzle.Puzzles;
import com.fulldome.mahabharata.server.InitDescriptorRequest;
import com.ironwaterstudio.server.Request;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.listeners.CallListener;

public class PuzzleActivity extends AppCompatActivity {
	public static final int PUZZLE_NUMBER = 0;

	private PiecesViewController piecesViewController = null;

	private CallListener initDescriptorListener = new CallListener(this) {
		@Override
		public void onSuccess(Request request, ApiResult result) {
			super.onSuccess(request, result);
			InitDescriptorResult descriptorResult = result.getData(InitDescriptorResult.class);
			if (descriptorResult == null || descriptorResult.isEmpty())
				return;
			descriptorResult.prepare(getPuzzle());
			piecesViewController.updateAllViews();
			piecesViewController.postInvalidateAll();
		}

		@Override
		protected void onError(ApiResult result) {
			super.onError(result);
			finish();
		}

		@Override
		protected void showError(Request request, ApiResult result) {
		}
	};

	@Override
	protected void onCreate(@Nullable Bundle inState) {
		super.onCreate(inState);
		setContentView(R.layout.activity_puzzle);
		piecesViewController = new PiecesViewController(this);
		initDescriptorListener.register();
		piecesViewController.updateAllViews();
		if (!Puzzles.getInstance().isEmpty() && getPuzzle() != null)
			new InitDescriptorRequest(this, getPuzzle(), getPuzzle().getDownloadedIds()).call(initDescriptorListener);
		else
			finish();
	}

	@Override
	protected void onStart() {
		super.onStart();
		if (!Puzzles.getInstance().isEmpty())
			Puzzles.getInstance().get(PUZZLE_NUMBER).resumeSounds();
	}

	@Override
	protected void onStop() {
		super.onStop();
		Puzzles.getInstance().save(this);
		if (!Puzzles.getInstance().isEmpty())
			Puzzles.getInstance().get(PUZZLE_NUMBER).pauseSounds();
	}

	@Override
	protected void onDestroy() {
		super.onDestroy();
		Puzzles.getInstance().clearDescriptors();
		if (!Puzzles.getInstance().isEmpty())
			Puzzles.getInstance().get(PUZZLE_NUMBER).releaseSounds();
	}

	private Puzzle getPuzzle() {
		return Puzzles.getInstance().get(PUZZLE_NUMBER);
	}
}
