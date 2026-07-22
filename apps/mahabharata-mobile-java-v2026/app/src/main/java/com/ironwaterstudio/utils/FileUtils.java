package com.ironwaterstudio.utils;

import android.content.Context;
import android.graphics.Bitmap;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.ByteArrayOutputStream;
import java.io.Closeable;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.Writer;
import java.util.Arrays;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class FileUtils {
	public static String read(Reader reader) {
		if (reader == null)
			return null;
		BufferedReader br = reader instanceof BufferedReader ? (BufferedReader) reader : new BufferedReader(reader);
		try {
			StringBuilder sb = new StringBuilder();
			String line;
			while ((line = br.readLine()) != null)
				sb.append(line).append('\n');
			return sb.toString();
		} catch (Throwable t) {
			t.printStackTrace();
			return null;
		} finally {
			close(br);
		}
	}

	public static String readStream(InputStream is) {
		return read(reader(is));
	}

	public static byte[] readStreamBytes(InputStream is) {
		try {
			ByteArrayOutputStream baos = new ByteArrayOutputStream();
			copyStream(new BufferedInputStream(is), baos);
			return baos.toByteArray();
		} catch (Throwable t) {
			t.printStackTrace();
			return null;
		}
	}

	public static void write(Writer writer, String content) {
		if (writer == null)
			return;
		BufferedWriter bw = writer instanceof BufferedWriter ? (BufferedWriter) writer : new BufferedWriter(writer);
		try {
			bw.write(content);
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			close(bw);
		}
	}

	public static void writeStream(OutputStream os, String content) {
		write(writer(os), content);
	}

	public static void writeStream(OutputStream os, byte[] content) {
		BufferedOutputStream bos = null;

		try {
			bos = new BufferedOutputStream(os);
			bos.write(content);
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			close(bos);
		}
	}

	public static boolean copyStream(InputStream in, OutputStream out) {
		return copyStream(in, out, true);
	}

	public static boolean copyStream(InputStream in, OutputStream out, boolean closeOut) {
		try {
			byte[] buffer = new byte[1024];
			int read;
			while ((read = in.read(buffer)) != -1) {
				out.write(buffer, 0, read);
			}
			return true;
		} catch (IOException e) {
			e.printStackTrace();
			return false;
		} finally {
			close(in);
			if (closeOut)
				close(out);
		}
	}

	public static String readFile(File file) {
		try {
			return readStream(new FileInputStream(file));
		} catch (FileNotFoundException e) {
			e.printStackTrace();
			return null;
		}
	}

	public static byte[] readFileBytes(File file) {
		try {
			return readStreamBytes(new FileInputStream(file));
		} catch (FileNotFoundException e) {
			e.printStackTrace();
			return null;
		}
	}

	public static void writeFile(File file, String content) {
		try {
			writeStream(new FileOutputStream(file), content);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
	}

	public static void writeFile(File file, Bitmap content) {
		writeFile(file, content, Bitmap.CompressFormat.PNG, 100);
	}

	public static void writeFile(File file, Bitmap content, Bitmap.CompressFormat format, int quality) {
		FileOutputStream out = null;
		try {
			out = new FileOutputStream(file);
			content.compress(format, quality, out);
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			close(out);
		}
	}

	public static void writeFile(File file, byte[] content) {
		try {
			writeStream(new FileOutputStream(file), content);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
	}

	public static BufferedWriter writer(File file) {
		try {
			return writer(new FileOutputStream(file));
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	public static BufferedWriter writer(OutputStream os) {
		try {
			return new BufferedWriter(new OutputStreamWriter(os, "UTF-8"));
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	public static BufferedReader reader(File file) {
		try {
			return reader(new FileInputStream(file));
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	public static BufferedReader reader(InputStream is) {
		try {
			return new BufferedReader(new InputStreamReader(is, "UTF-8"));
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	public static void close(Closeable closeable) {
		try {
			if (closeable != null)
				closeable.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public static boolean copyFile(File src, File dest) {
		try {
			return copyStream(new FileInputStream(src), new FileOutputStream(dest));
		} catch (FileNotFoundException e) {
			e.printStackTrace();
			return false;
		}
	}

	public static boolean deleteFile(File file) {
		if (file.isDirectory()) {
			for (File child : file.listFiles()) {
				if (!deleteFile(child))
					return false;
			}
		}
		return file.delete();
	}

	public static boolean assetFileExist(Context context, String name) {
		return assetFileExist(context, "", name);
	}

	public static boolean assetFileExist(Context context, String path, String name) {
		try {
			return Arrays.asList(context.getAssets().list(path)).contains(name);
		} catch (IOException e) {
			e.printStackTrace();
			return false;
		}
	}

	public static boolean unzip(String zipPath, String folderPath) {
		ZipInputStream in = null;
		try {
			in = new ZipInputStream(new BufferedInputStream(new FileInputStream(zipPath)));
			ZipEntry entry;
			byte[] buffer = new byte[1024];
			int count;
			while ((entry = in.getNextEntry()) != null) {
				if (entry.isDirectory())
					continue;

				File file = new File(folderPath + "/" + entry.getName());
				file.getParentFile().mkdirs();
				FileOutputStream out = new FileOutputStream(file);
				while ((count = in.read(buffer)) != -1) {
					out.write(buffer, 0, count);
				}
				out.close();
				in.closeEntry();
			}
		} catch (IOException e) {
			e.printStackTrace();
			return false;
		} finally {
			close(in);
		}
		return true;
	}
}
