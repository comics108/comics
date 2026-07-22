package com.fulldome.mahabharata.model.puzzle;

import android.content.Context;

import com.fulldome.mahabharata.model.visual.Comics;

import java.util.ArrayList;

public class Puzzle {
	private int id;
	private String name;
	private int width;
	private int height;
	private int order;
	private ArrayList<Piece> pieces;

	public int getId() {
		return id;
	}

	public String getName() {
		return name;
	}

	public int getWidth() {
		return width;
	}

	public int getHeight() {
		return height;
	}

	public int getOrder() {
		return order;
	}

	public ArrayList<Piece> getPieces() {
		return pieces;
	}

	public ArrayList<Integer> getDownloadedIds() {
		ArrayList<Integer> downloadedIds = new ArrayList<>();
		for (Piece piece : getPieces()) {
			if (piece.isDownloaded() && piece.getComics() == null)
				downloadedIds.add(piece.getId());
		}
		return downloadedIds;
	}

	public boolean hasDownloadInfo() {
		for (Piece piece : getPieces()) {
			if (piece.getDownloadInfo() != null)
				return true;
		}
		return false;
	}

	public void clearDownloadInfo() {
		for (Piece piece : getPieces())
			piece.clearDownloadInfo();
	}

	public Piece getPiece(int id) {
		for (Piece piece : getPieces()) {
			if (piece.getId() == id)
				return piece;
		}
		return null;
	}

	public boolean contains(int id) {
		return getPiece(id) != null;
	}

	public void delete(Context context) {
		for (Piece piece : getPieces())
			piece.delete(context);
	}

	public void toggleSounds() {
		Comics.toggleSoundsSettings();
		for (Piece piece : getPieces()) {
			if (piece.getComics() != null)
				piece.getComics().updateSoundsState();
		}
	}

	public void pauseSounds() {
		for (Piece piece : getPieces()) {
			if (piece.getComics() != null)
				piece.getComics().pauseSounds();
		}
	}

	public void resumeSounds() {
		for (Piece piece : getPieces()) {
			if (piece.getComics() != null)
				piece.getComics().resumeSounds();
		}
	}

	public void releaseSounds() {
		for (Piece piece : getPieces()) {
			if (piece.getComics() != null)
				piece.getComics().release();
		}
	}
}
