package com.fulldome.mahabharata.model;

import com.fulldome.mahabharata.model.puzzle.Piece;
import com.fulldome.mahabharata.model.puzzle.Puzzle;
import com.fulldome.mahabharata.model.visual.Comics;

import java.util.HashMap;

public class InitDescriptorResult extends HashMap<Integer, Comics> {
	public void prepare(Puzzle puzzle) {
		for (Integer key : keySet()) {
			Piece piece = puzzle.getPiece(key);
 			if (piece != null)
				piece.setComics(get(key));
		}
	}
}
