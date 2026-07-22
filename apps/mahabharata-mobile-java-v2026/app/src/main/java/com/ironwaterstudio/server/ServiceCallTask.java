package com.ironwaterstudio.server;

import android.os.AsyncTask;

import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.listeners.OnCallListener;

public class ServiceCallTask extends AsyncTask<Void, Float, ApiResult> {
	private final Request request;
	private final OnCallListener listener;

	public ServiceCallTask(Request request, OnCallListener listener) {
		this.request = request;
		this.listener = listener;
	}

	@Override
	protected void onPreExecute() {
		if (listener != null) {
			listener.onStart(request);
		}
	}

	@Override
	protected ApiResult doInBackground(Void... params) {
		ApiResult result = request.call();
		if (listener != null && result.isSuccess() && !isCancelled())
			listener.onPrepare(request, result);
		return result;
	}

	@Override
	protected void onPostExecute(ApiResult result) {
		if (listener == null)
			return;

		if (result.isSuccess())
			listener.onSuccess(request, result);
		else
			listener.onError(request, result);
	}

	@Override
	protected void onProgressUpdate(Float... values) {
		super.onProgressUpdate(values);
		if (listener == null || values == null || values.length < 2)
			return;
		if (values[1] == 0)
			listener.onUploadProgress(request, values[0]);
		else
			listener.onDownloadProgress(request, values[1]);
	}

	public void executeOnExecutor() {
		try {
			executeOnExecutor(THREAD_POOL_EXECUTOR);
		} catch (Exception e) {
			e.printStackTrace();
			onPreExecute();
			onPostExecute(ApiResult.create(ApiResult.ERROR));
		}
	}

	public void setProgress(float upload, float download) {
		if (listener != null)
			publishProgress(upload, download);
	}

	public static ServiceCallTask execute(Request request, OnCallListener listener) {
		ServiceCallTask task = new ServiceCallTask(request, listener);
		task.executeOnExecutor();
		return task;
	}
}
