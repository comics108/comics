package com.fulldome.mahabharata.model.visual;

import android.text.TextUtils;

import com.fulldome.mahabharata.model.ComicsDescriptor;

public class Image {
	private String file;
	private int width;
	private int height;
	private String popup;

	public String getFile() {
		return file;
	}

	public String getFile(ComicsDescriptor.ImageType type) {
		return type.getName() + getFile();
	}

	public int getWidth() {
		return width;
	}

	public int getHeight() {
		return height;
	}

	public String getPopup() {
		return ComicsDescriptor.ImageType.LAYER.getName() + popup;
	}

	public boolean isEmpty() {
		return TextUtils.isEmpty(getFile());
	}

	public boolean hasPopup() {
		return !TextUtils.isEmpty(getPopup());
	}
}
