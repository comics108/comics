package com.fulldome.mahabharata.model;

public class EpisodeState {
	private int loadedVersion = -1;
	private boolean purchased = false;
	private String savedFile = null;
	private String price = null;
	private DownloadInfo downloadInfo = null;
	private int currentScroll = 0;

	public int getLoadedVersion() {
		return loadedVersion;
	}

	public void setLoadedVersion(int loadedVersion) {
		this.loadedVersion = loadedVersion;
	}

	public boolean isPurchased() {
		return purchased;
	}

	public void setPurchased(boolean purchased) {
		this.purchased = purchased;
	}

	public String getSavedFile() {
		return savedFile;
	}

	public void setSavedFile(String savedFile) {
		this.savedFile = savedFile;
	}

	public String getPrice() {
		return price;
	}

	public void setPrice(String price) {
		this.price = price;
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
}
