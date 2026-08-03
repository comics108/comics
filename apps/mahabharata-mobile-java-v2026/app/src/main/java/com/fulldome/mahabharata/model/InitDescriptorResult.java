package com.fulldome.mahabharata.model;

import net.nativemind.comics.viewer.comics.model.Comics;
import net.nativemind.comics.viewer.puzzle.model.Piece;
import net.nativemind.comics.viewer.puzzle.model.Puzzle;

import java.util.HashMap;

public class InitDescriptorResult extends HashMap<Integer, Comics> {
	public void prepare(Puzzle puzzle) {
		for (Integer key : keySet()) {
			Piece piece = puzzle.getPiece(key);
			Comics comics = get(key);
 			if (piece != null) {
				piece.setComics(comics);
				// comics-viewer-android's Comics defaults soundEnabled=true; sync it to the
				// app's persisted preference right away since the library no longer knows
				// about Settings.
				if (comics != null)
					comics.setSoundEnabled(Settings.getInstance().isSoundOn());
			}
		}
	}
}
