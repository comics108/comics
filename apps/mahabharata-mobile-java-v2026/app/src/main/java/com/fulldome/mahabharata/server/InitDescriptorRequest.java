package com.fulldome.mahabharata.server;

import android.content.Context;

import com.fulldome.mahabharata.model.InitDescriptorResult;
import com.fulldome.mahabharata.model.puzzle.Puzzle;
import com.fulldome.mahabharata.model.visual.Comics;
import com.ironwaterstudio.server.ActionRequest;
import com.ironwaterstudio.server.data.ApiResult;

import java.util.ArrayList;

public class InitDescriptorRequest extends ActionRequest {
	public InitDescriptorRequest(final Context context, final Puzzle puzzle, final ArrayList<Integer> ids) {
		super(new Runnable() {
			@Override
			public Object run() {
				InitDescriptorResult result = new InitDescriptorResult();
				for (int id : ids)
					result.put(id, Comics.create(context, puzzle.getPiece(id)));
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
