package com.fulldome.mahabharata.model;

import android.content.Context;
import androidx.annotation.NonNull;

import java.io.File;

public interface BaseState {
	int getLoadedVersion();

	DownloadInfo getDownloadInfo();

	boolean isDownloaded();

	void setDownloaded(boolean downloaded);

	File getSavedFile(@NonNull Context context);
}
