package com.ironwaterstudio.server.listeners;

import com.ironwaterstudio.server.Request;
import com.ironwaterstudio.server.data.ApiResult;

public interface OnCallListener {
	void onStart(Request request);

	void onPrepare(Request request, ApiResult result);

	void onSuccess(Request request, ApiResult result);

	void onError(Request request, ApiResult result);

	void onUploadProgress(Request request, float progress);

	void onDownloadProgress(Request request, float progress);
}
