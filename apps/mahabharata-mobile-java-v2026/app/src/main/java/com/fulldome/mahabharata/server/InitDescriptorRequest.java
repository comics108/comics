package com.fulldome.mahabharata.server;

import android.content.Context;

import com.fulldome.mahabharata.model.InitDescriptorResult;
import com.ironwaterstudio.server.ActionRequest;
import com.ironwaterstudio.server.data.ApiResult;

import net.nativemind.comics.viewer.comics.util.ComicsUtils;
import net.nativemind.comics.viewer.puzzle.model.Piece;
import net.nativemind.comics.viewer.puzzle.model.Puzzle;

import java.io.File;
import java.util.ArrayList;

public class InitDescriptorRequest extends ActionRequest {
	public InitDescriptorRequest(final Context context, final Puzzle puzzle, final ArrayList<Integer> ids) {
		super(new Runnable() {
			@Override
			public Object run() {
				InitDescriptorResult result = new InitDescriptorResult();
				for (int id : ids) {
					Piece piece = puzzle.getPiece(id);
					File file = piece != null && piece.isDownloaded() ? piece.getSavedFile(context) : null;
					result.put(id, ComicsUtils.INSTANCE.create(context, file));
				}
				return ApiResult.fromObject(result);
			}
		});
	}

	public InitDescriptorRequest(InitDescriptorRequest request) {
		super(request);
	}

	@Override
	protected InitDescriptorRequest copy() {
		return new InitDescriptorRequest(this);
	}
}
