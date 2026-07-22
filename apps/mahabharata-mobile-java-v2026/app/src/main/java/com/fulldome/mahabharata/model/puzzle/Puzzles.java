package com.fulldome.mahabharata.model.puzzle;

import android.app.DownloadManager;
import android.content.Context;
import android.database.Cursor;
import androidx.annotation.MainThread;

import com.fulldome.mahabharata.model.DownloadInfo;
import com.ironwaterstudio.server.serializers.JsonSerializer;
import com.ironwaterstudio.server.serializers.Serializer;
import com.ironwaterstudio.utils.FileUtils;

import java.io.File;
import java.util.ArrayList;

public class Puzzles extends ArrayList<Puzzle> {
	private static final String FILE_NAME = "puzzles.json";

	private static Puzzles instance = null;

	public static Puzzles getInstance() {
		return instance;
	}

	public static void init(Context context) {
		if (instance == null)
			instance = load(context);
	}

	@MainThread
	public void update(Context context, Puzzles data) {
		for (Puzzle puzzle : this) {
			Puzzle dataPuzzle = data.getPuzzle(puzzle.getId());
			if (dataPuzzle == null) {
				puzzle.delete(context);
				continue;
			}
			for (Piece piece : puzzle.getPieces()) {
				Piece dataPiece = dataPuzzle.getPiece(piece.getId());
				if (dataPiece == null) {
					piece.delete(context);
				} else {
					piece.copyStateTo(dataPiece);
					piece.copyComicsTo(dataPiece);
				}
			}
		}
		clear();
		addAll(data);
		save(context);
	}

	public void clearDescriptors() {
		for (Puzzle puzzle : this) {
			for (Piece piece : puzzle.getPieces())
				piece.setComics(null);
		}
	}

	public boolean contains(int id) {
		return getPuzzle(id) != null;
	}

	public Puzzle getPuzzle(int id) {
		for (Puzzle puzzle : this) {
			if (puzzle.getId() == id)
				return puzzle;
		}
		return null;
	}

	public Piece getPiece(int id) {
		for (Puzzle puzzle : this) {
			Piece piece = puzzle.getPiece(id);
			if (piece != null)
				return piece;
		}
		return null;
	}

	public Piece getPiece(long downloadId) {
		for (Puzzle puzzle : this) {
			for (Piece piece : puzzle.getPieces()) {
				DownloadInfo download = piece.getDownloadInfo();
				if (download != null && download.getId() == downloadId)
					return piece;
			}
		}
		return null;
	}

	public long[] getDownloadIds() {
		ArrayList<Long> ids = new ArrayList<>();
		for (Puzzle puzzle : this) {
			for (Piece piece : puzzle.getPieces()) {
				if (piece.getDownloadInfo() != null && piece.getDownloadInfo().getId() != -1)
					ids.add(piece.getDownloadInfo().getId());
			}
		}
		long[] idsArray = new long[ids.size()];
		for (int i = 0; i < ids.size(); i++)
			idsArray[i] = ids.get(i);
		return idsArray;
	}

	public boolean queryDownloads(Context context) {
		long[] downloadIds = getDownloadIds();
		if (downloadIds.length == 0)
			return false;

		DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
		Cursor c = manager.query(new DownloadManager.Query().setFilterById(downloadIds));
		int colId = c.getColumnIndex(DownloadManager.COLUMN_ID);
		int colStatus = c.getColumnIndex(DownloadManager.COLUMN_STATUS);
		int colDownloadedBytes = c.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR);
		int colTotalBytes = c.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES);
		while (c.moveToNext()) {
			long id = c.getLong(colId);
			Piece piece = getPiece(id);
			if (piece == null)
				continue;

			int status = c.getInt(colStatus);
			if ((status == DownloadManager.STATUS_SUCCESSFUL && !piece.completeDownload(context)) || status == DownloadManager.STATUS_FAILED) {
				piece.setDownloaded(false);
			} else if (status == DownloadManager.STATUS_SUCCESSFUL) {
				piece.setDownloaded(true);
			} else {
				piece.getDownloadInfo().setDownloadedBytes(c.getLong(colDownloadedBytes));
				piece.getDownloadInfo().setTotalBytes(c.getLong(colTotalBytes));
			}
		}
		c.close();
		return true;
	}

	public void save(Context context) {
		File file = new File(context.getExternalFilesDir(null), FILE_NAME);
		FileUtils.writeFile(file, Serializer.get(JsonSerializer.class).write(this));
	}

	public static Puzzles load(Context context) {
		File file = new File(context.getExternalFilesDir(null), FILE_NAME);
		if (!file.exists())
			return new Puzzles();
		return Serializer.get(JsonSerializer.class).read(FileUtils.readFile(file), Puzzles.class);
	}
}
