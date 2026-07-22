package com.fulldome.mahabharata.model;

import android.content.res.AssetFileDescriptor;

import com.android.vending.expansion.zipfile.ZipResourceFile;

import java.io.File;
import java.io.InputStream;

public class ComicsDescriptor {
	private final ZipResourceFile zipFile;
	private final String name;

	public enum ImageType {
		LAYER("layers/");

		private String name;

		ImageType(String name) {
			this.name = name;
		}

		public String getName() {
			return name;
		}
	}

	public ComicsDescriptor(ZipResourceFile zipFile, String name) {
		this.zipFile = zipFile;
		this.name = name;
	}

	public ZipResourceFile getZipFile() {
		return zipFile;
	}

	public String getName() {
		return name;
	}

	public InputStream getData() {
		try {
			return zipFile.getInputStream("data.json");
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	public AssetFileDescriptor getSound(String track) {
		return zipFile.getAssetFileDescriptor("sounds/" + track);
	}

	public InputStream getImage(String fileName) {
		try {
			return zipFile.getInputStream(fileName);
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	public static ComicsDescriptor create(File file) {
		if (file == null)
			return null;
		try {
			return new ComicsDescriptor(new ZipResourceFile(file.getAbsolutePath()), file.getName());
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}
}
