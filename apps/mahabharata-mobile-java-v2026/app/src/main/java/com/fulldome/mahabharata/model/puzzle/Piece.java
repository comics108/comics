package com.fulldome.mahabharata.model.puzzle;

import android.app.DownloadManager;
import android.content.Context;
import android.net.Uri;
import androidx.annotation.NonNull;
import android.text.TextUtils;
import android.webkit.URLUtil;

import com.fulldome.mahabharata.BuildConfig;
import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.model.BaseState;
import com.fulldome.mahabharata.model.DownloadInfo;
import com.fulldome.mahabharata.model.visual.Comics;
import com.ironwaterstudio.utils.FileUtils;

import java.io.File;

public class Piece implements BaseState {
	private static final String TEMP_EXT = ".tmp";

	private int id;
	private int x;
	private int y;
	private int width;
	private int height;
	private String file;
	private int version;
	private int date;
	private int order;
	private PieceState state = new PieceState();

	private transient Comics comics = null;

	public int getId() {
		return id;
	}

	public int getX() {
		return x;
	}

	public int getY() {
		return y;
	}

	public int getWidth() {
		return width;
	}

	public int getHeight() {
		return height;
	}

	public String getFile() {
		return TextUtils.isEmpty(file) ? null : BuildConfig.HOST + file;
	}

	public int getVersion() {
		return version;
	}

	public int getDate() {
		return date;
	}

	public int getOrder() {
		return order;
	}

	public Comics getComics() {
		return comics;
	}

	public void setComics(Comics comics) {
		this.comics = comics;
	}

	@Override
	public int getLoadedVersion() {
		return state.getLoadedVersion();
	}

	@Override
	public DownloadInfo getDownloadInfo() {
		return state.getDownloadInfo();
	}

	public int getCurrentScroll() {
		return state.getCurrentScroll();
	}

	public void setCurrentScroll(int currentScroll) {
		state.setCurrentScroll(currentScroll);
	}

	public boolean isShowPreview() {
		return state.isShowPreview();
	}

	public void setShowPreview(boolean showPreview) {
		state.setShowPreview(showPreview);
	}

	@Override
	public boolean isDownloaded() {
		return !TextUtils.isEmpty(state.getSavedFile());
	}

	@Override
	public void setDownloaded(boolean downloaded) {
		state.setLoadedVersion(downloaded ? version : -1);
		state.setSavedFile(downloaded ? buildSavedFileName() : null);
		state.getDownloadInfo().setId(-1);
	}

	public void clearDownloadInfo() {
		state.setDownloadInfo(null);
	}

	@Override
	public File getSavedFile(@NonNull Context context) {
		return new File(getLocation(context), state.getSavedFile());
	}

	public String buildTempSavedFileName() {
		return buildSavedFileName() + TEMP_EXT;
	}

	public String buildSavedFileName() {
		return URLUtil.guessFileName(getFile(), null, null);
	}

	public void copyStateTo(@NonNull Piece piece) {
		piece.state = state;
	}

	public void copyComicsTo(@NonNull Piece piece) {
		piece.comics = comics;
	}

	public void delete(@NonNull Context context) {
		if (isDownloaded()) {
			if (getComics() != null)
				getComics().release();
			setComics(null);
			FileUtils.deleteFile(getSavedFile(context));
			state.setLoadedVersion(-1);
			state.setDownloadInfo(null);
			state.setSavedFile(null);
		}
	}

	public void download(@NonNull Context context, String puzzleName) {
		if (TextUtils.isEmpty(getFile()))
			return;
		DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
		Uri uri = Uri.parse(getFile());
		long id = manager.enqueue(new DownloadManager.Request(uri)
				.setTitle(context.getString(R.string.app_name))
				.setDescription(puzzleName)
				.setDestinationInExternalFilesDir(context, null, buildTempSavedFileName()));
		state.setDownloadInfo(new DownloadInfo(id));
	}

	public boolean completeDownload(@NonNull Context context) {
		File root = getLocation(context);
		File tmpFile = new File(root, buildTempSavedFileName());
		File file = new File(root, buildSavedFileName());
		return (!file.exists() || file.delete()) && tmpFile.exists() && tmpFile.renameTo(file);
	}

	public static File getLocation(@NonNull Context context) {
		return context.getExternalFilesDir(null);
	}
}
