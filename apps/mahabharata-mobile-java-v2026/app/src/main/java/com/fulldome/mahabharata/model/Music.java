package com.fulldome.mahabharata.model;

import android.app.DownloadManager;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import androidx.annotation.NonNull;
import android.webkit.URLUtil;

import com.fulldome.mahabharata.BuildConfig;
import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.screens.UiConstants;
import com.ironwaterstudio.utils.FileUtils;

import java.io.File;
import java.io.Serializable;

public class Music implements Serializable {
	private static final String TEMP_EXT = ".tmp";

	public enum ActionType implements Serializable {PLAY, LOAD, DELETE}

	public enum FileActionType implements Serializable {COMPLETE_DOWNLOAD, DELETE}

	private int id;
	private String name;
	private String author;
	private String file;

	public int getId() {
		return id;
	}

	public String getName() {
		return name;
	}

	public String getAuthor() {
		return author;
	}

	public String getFile() {
		return BuildConfig.HOST + file;
	}

	@Override
	public boolean equals(Object o) {
		if (this == o) return true;
		if (!(o instanceof Music)) return false;

		Music music = (Music) o;

		if (id != music.id) return false;
		if (name != null ? !name.equals(music.name) : music.name != null) return false;
		if (author != null ? !author.equals(music.author) : music.author != null) return false;
		return file != null ? file.equals(music.file) : music.file == null;
	}

	@Override
	public int hashCode() {
		int result = id;
		result = 31 * result + (name != null ? name.hashCode() : 0);
		result = 31 * result + (author != null ? author.hashCode() : 0);
		result = 31 * result + (file != null ? file.hashCode() : 0);
		return result;
	}

	public File getSavedFile(@NonNull Context context) {
		return new File(getLocation(context), buildSavedFileName());
	}

	public String getPreferSavedFilePath(@NonNull Context context) {
		if (isDownloaded(context))
			return getSavedFile(context).getPath();
		return getFile();
	}

	public boolean isDownloaded(Context context) {
		return getSavedFile(context).exists();
	}

	public void delete(@NonNull Context context) {
		if (!isDownloaded(context))
			return;

		context.sendBroadcast(new Intent(UiConstants.ACTION_FILE).putExtra(UiConstants.KEY_ACTION, FileActionType.DELETE).putExtra(UiConstants.KEY_DATA, this));
		FileUtils.deleteFile(getSavedFile(context));
		Settings.getInstance().getMusicDownloadInfos().remove(getId());
		Settings.getInstance().save();
	}

	public void download(Context context) {
		if (Settings.getInstance().getMusicDownloadInfos().containsKey(getId()))
			return;

		DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
		Uri uri = Uri.parse(getFile());
		long id = manager.enqueue(new DownloadManager.Request(uri)
				.setTitle(context.getString(R.string.app_name))
				.setDescription(getName())
				.setDestinationInExternalFilesDir(context, null, buildTempSavedFileName()));
		Settings.getInstance().getMusicDownloadInfos().put(getId(), new DownloadInfo(id));
		Settings.getInstance().save();
	}

	public void completeDownload(@NonNull Context context) {
		File root = getLocation(context);
		File tmpFile = new File(root, buildTempSavedFileName());
		File file = new File(root, buildSavedFileName());
		Settings.getInstance().getMusicDownloadInfos().remove(getId());
		Settings.getInstance().save();
		if ((!file.exists() || file.delete()) && tmpFile.exists() && tmpFile.renameTo(file))
			context.sendBroadcast(new Intent(UiConstants.ACTION_FILE).putExtra(UiConstants.KEY_ACTION, FileActionType.COMPLETE_DOWNLOAD).putExtra(UiConstants.KEY_DATA, this));
	}

	public String buildTempSavedFileName() {
		return buildSavedFileName() + TEMP_EXT;
	}

	public String buildSavedFileName() {
		return URLUtil.guessFileName(getFile(), null, null);
	}

	public static File getLocation(@NonNull Context context) {
		return context.getExternalFilesDir(null);
	}
}
