package com.ironwaterstudio.server;

import androidx.annotation.NonNull;

import java.io.IOException;
import java.io.OutputStream;

public class ProgressOutputStream extends OutputStream {
	private final ServiceCallTask task;
	private final OutputStream os;
	private final int total;
	private float lastProgress = -1;
	private int current = 0;

	private ProgressOutputStream(ServiceCallTask task, OutputStream os, int total) {
		this.task = task;
		this.os = os;
		this.total = total;
	}

	@Override
	public void write(int oneByte) throws IOException {
		os.write(oneByte);
		addBytes(1);
	}

	@Override
	public void write(@NonNull byte[] b) throws IOException {
		super.write(b);
		addBytes(b.length);
	}

	@Override
	public void write(@NonNull byte[] b, int off, int len) throws IOException {
		super.write(b, off, len);
		addBytes(len);
	}

	private void addBytes(int bytesCount) {
		current += bytesCount;
		float progress = (float) current / total;
		if (progress - lastProgress >= 0.01f) {
			lastProgress = progress;
			task.setProgress(Math.min(lastProgress, 1f), 0f);
		}
	}

	@Override
	public void close() throws IOException {
		os.close();
	}

	@Override
	public void flush() throws IOException {
		os.flush();
	}

	public static OutputStream create(ServiceCallTask task, OutputStream os, int total, boolean publishProgress) {
		return task == null || total == -1 || !publishProgress ? os : new ProgressOutputStream(task, os, total);
	}
}