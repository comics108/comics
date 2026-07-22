package com.ironwaterstudio.server;

import android.content.Context;
import android.os.AsyncTask;
import androidx.loader.content.Loader;

import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.listeners.CallListener;
import com.ironwaterstudio.server.listeners.OnCallListener;

public class ServiceLoader extends Loader<ApiResult> {
	private Request request;
	private ApiResult data = null;
	private OnCallListener listener = null;

	private ServiceCallTask callTask;

	public ServiceLoader(Context context) {
		super(context);
	}

	public Request getRequest() {
		return request;
	}

	public void setRequest(Request request) {
		this.request = request;
	}

	public ApiResult getData() {
		return data;
	}

	public void setListener(OnCallListener listener) {
		this.listener = listener;
	}

	public ServiceCallTask getCallTask() {
		return callTask;
	}

	@Override
	protected void onStartLoading() {
		super.onStartLoading();
		if (data != null)
			deliverResult(data);
	}

	@Override
	public void forceLoad() {
		super.forceLoad();
		cancelLoad(true);
		callTask = new LoadTask();
		callTask.executeOnExecutor();
	}

	@Override
	public void deliverResult(ApiResult data) {
		this.data = data;
		super.deliverResult(data);
	}

	public boolean cancelLoad(boolean mayInterruptIfRunning) {
		if (callTask == null || callTask.getStatus() != AsyncTask.Status.RUNNING)
			return false;
		deliverResult(ApiResult.createCancel());
		return callTask.cancel(mayInterruptIfRunning);
	}

	public static ServiceCallTask execute(Request request, CallListener listener) {
		int loaderId = request.hashCode();
		Loader<ApiResult> loader = listener.getLoaderManager().getLoader(loaderId);
		if (loader != null && loader.isStarted())
			return ((ServiceLoader) loader).getCallTask();
		loader = listener.getLoaderManager().initLoader(loaderId, null, listener);
		ServiceLoader serviceLoader = (ServiceLoader) loader;
		serviceLoader.setRequest(request);
		serviceLoader.setListener(listener);
		serviceLoader.forceLoad();
		return serviceLoader.getCallTask();
	}

	private class LoadTask extends ServiceCallTask {
		public LoadTask() {
			super(request, listener);
		}

		@Override
		protected void onPostExecute(ApiResult result) {
			deliverResult(result);
		}
	}
}
