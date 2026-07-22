package com.fulldome.mahabharata.model;

import android.app.DownloadManager;
import android.content.Context;
import android.database.Cursor;

import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class Musics extends ArrayList<Music> {
	private static long[] getDownloadIds() {
		ArrayList<Long> ids = new ArrayList<>();
		HashMap<Integer, DownloadInfo> infos = Settings.getInstance().getMusicDownloadInfos();
		for (Integer musicId : infos.keySet())
			ids.add(infos.get(musicId).getId());
		long[] idsArray = new long[ids.size()];
		for (int i = 0; i < ids.size(); i++)
			idsArray[i] = ids.get(i);
		return idsArray;
	}

	private static int getMusicId(long downloadId) {
		HashMap<Integer, DownloadInfo> infos = Settings.getInstance().getMusicDownloadInfos();
		for (Integer musicId : infos.keySet()) {
			if (infos.get(musicId).getId() == downloadId)
				return musicId;
		}
		return -1;
	}

	@Nullable
	private static Music findMusic(List<Music> musics, int id) {
		for (final Music music : musics) {
			if (music.getId() == id) {
				return music;
			}
		}
		return null;
	}

	public static boolean queryDownloads(final Context context, final List<Music> musics) {
		if (musics.isEmpty()) {
			return false;
		}

		long[] downloadIds = getDownloadIds();
		if (downloadIds.length == 0) {
			return false;
		}

		DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
		Cursor c = manager.query(new DownloadManager.Query().setFilterById(downloadIds));
		if (c == null)
			return false;

		int colId = c.getColumnIndex(DownloadManager.COLUMN_ID);
		int colStatus = c.getColumnIndex(DownloadManager.COLUMN_STATUS);
		int colDownloadedBytes = c.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR);
		int colTotalBytes = c.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES);

		while (c.moveToNext()) {
			long id = c.getLong(colId);
			int musicId = getMusicId(id);
			DownloadInfo info = Settings.getInstance().getMusicDownloadInfos().get(getMusicId(id));
			Music music = findMusic(musics, musicId);
			if (info == null || music == null)
				continue;

			int status = c.getInt(colStatus);
			if ((status != DownloadManager.STATUS_SUCCESSFUL && status != DownloadManager.STATUS_FAILED)) {
				info.setDownloadedBytes(c.getLong(colDownloadedBytes));
				info.setTotalBytes(c.getLong(colTotalBytes));
			} else if (status == DownloadManager.STATUS_SUCCESSFUL) {
				music.completeDownload(context);
			}
		}
		c.close();
		Settings.getInstance().save();
		return true;
	}
}
