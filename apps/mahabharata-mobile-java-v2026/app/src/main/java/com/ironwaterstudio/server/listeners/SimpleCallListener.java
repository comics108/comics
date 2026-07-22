package com.ironwaterstudio.server.listeners;

import com.ironwaterstudio.server.Request;
import com.ironwaterstudio.server.data.ApiResult;

public class SimpleCallListener implements OnCallListener {
	@Override
	public void onStart(Request request) {
		onStart();
	}

	protected void onStart() {
	}

	@Override
	public void onSuccess(Request request, ApiResult result) {
		onSuccess(result);
	}

	protected void onSuccess(ApiResult result) {
	}

	@Override
	public void onError(Request request, ApiResult result) {
		onError(result);
	}

	protected void onError(ApiResult result) {
	}

	@Override
	public void onPrepare(Request request, ApiResult result) {
		onPrepare(result);
	}

	protected void onPrepare(ApiResult result) {
	}

	@Override
	public void onUploadProgress(Request request, float progress) {
	}

	@Override
	public void onDownloadProgress(Request request, float progress) {
	}
}
