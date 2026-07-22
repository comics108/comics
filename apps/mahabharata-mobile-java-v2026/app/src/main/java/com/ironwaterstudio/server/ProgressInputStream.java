package com.ironwaterstudio.server;

import androidx.annotation.NonNull;

import java.io.IOException;
import java.io.InputStream;

public class ProgressInputStream extends InputStream {
	private final ServiceCallTask task;
	private final InputStream is;
	private final int total;
	private float lastProgress = -1;
	private int current = 0;

	private ProgressInputStream(ServiceCallTask task, InputStream is, int total) {
		this.task = task;
		this.is = is;
		this.total = total;
	}

	@Override
	public int read() throws IOException {
		addBytes(1);
		return is.read();
	}

	@Override
	public int read(@NonNull byte[] b) throws IOException {
		addBytes(b.length);
		return is.read(b);
	}

	@Override
	public int read(@NonNull byte[] b, int off, int len) throws IOException {
		addBytes(len);
		return is.read(b, off, len);
	}

	private void addBytes(int bytesCount) {
		current += bytesCount;
		float progress = (float) current / total;
		if (progress - lastProgress >= 0.01f) {
			lastProgress = progress;
			task.setProgress(1f, Math.min(lastProgress, 1f));
		}
	}

	@Override
	public int available() throws IOException {
		return is.available();
	}

	@Override
	public void close() throws IOException {
		is.close();
	}

	@Override
	public void mark(int readlimit) {
		is.mark(readlimit);
	}

	@Override
	public boolean markSupported() {
		return is.markSupported();
	}

	@Override
	public synchronized void reset() throws IOException {
		is.reset();
	}

	@Override
	public long skip(long byteCount) throws IOException {
		return is.skip(byteCount);
	}

	public static InputStream create(ServiceCallTask task, InputStream is, int total, boolean publishProgress) {
		return task == null || total == -1 || !publishProgress ? is : new ProgressInputStream(task, is, total);
	}
}