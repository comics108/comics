package com.fulldome.mahabharata.model.puzzle;

import com.fulldome.mahabharata.model.DownloadInfo;

public class PieceState {
	private int loadedVersion = -1;
	private String savedFile = null;
	private DownloadInfo downloadInfo = null;
	private int currentScroll = 0;
	private boolean showPreview = true;

	public int getLoadedVersion() {
		return loadedVersion;
	}

	public void setLoadedVersion(int loadedVersion) {
		this.loadedVersion = loadedVersion;
	}

	public String getSavedFile() {
		return savedFile;
	}

	public void setSavedFile(String savedFile) {
		this.savedFile = savedFile;
	}

	public DownloadInfo getDownloadInfo() {
		return downloadInfo;
	}

	public void setDownloadInfo(DownloadInfo downloadInfo) {
		this.downloadInfo = downloadInfo;
	}

	public int getCurrentScroll() {
		return currentScroll;
	}

	public void setCurrentScroll(int currentScroll) {
		this.currentScroll = currentScroll;
	}

	public boolean isShowPreview() {
		return showPreview;
	}

	public void setShowPreview(boolean showPreview) {
		this.showPreview = showPreview;
	}
}
