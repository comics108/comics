package com.ironwaterstudio.server.listeners;

import android.os.Handler;
import androidx.annotation.CallSuper;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;

import com.ironwaterstudio.dialogs.ProgressFragment;
import com.ironwaterstudio.server.Request;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.utils.UiHelper;

public class ProgressCallListener extends SimpleCallListener {
	private FragmentActivity activity = null;
	private final Fragment fragment;
	private boolean withProgress = false;
	protected final Handler handler = new Handler();

	public ProgressCallListener(FragmentActivity activity) {
		this(activity, true);
	}

	public ProgressCallListener(FragmentActivity activity, boolean withProgress) {
		this.activity = activity;
		this.fragment = null;
		this.withProgress = withProgress;
	}

	public ProgressCallListener(Fragment fragment) {
		this(fragment, true);
	}

	public ProgressCallListener(Fragment fragment, boolean withProgress) {
		this.fragment = fragment;
		this.withProgress = withProgress;
	}

	public FragmentActivity getActivity() {
		return activity;
	}

	public Fragment getFragment() {
		return fragment;
	}

	public void setWithProgress(boolean withProgress) {
		this.withProgress = withProgress;
	}

	public boolean isWithProgress(Request request) {
		return withProgress && (request == null || !request.hasCacheMode(Request.CACHE_SMART));
	}

	@Override
	@CallSuper
	public void onStart(Request request) {
		super.onStart(request);
		if (isWithProgress(request))
			ProgressFragment.show(activity, request == null || !request.isPublishProgress());
	}

	@Override
	public void onDownloadProgress(Request request, float progress) {
		super.onDownloadProgress(request, progress);
		ProgressFragment.setProgress(activity, progress);
	}

	@Override
	@CallSuper
	public void onSuccess(Request request, ApiResult result) {
		super.onSuccess(request, result);
		if (isWithProgress(request))
			handler.post(new Runnable() {
				@Override
				public void run() {
					ProgressFragment.dismiss(activity);
				}
			});
	}

	@Override
	@CallSuper
	public void onError(Request request, ApiResult result) {
		super.onError(request, result);
		if (isWithProgress(request))
			ProgressFragment.dismiss(activity);
		if ((fragment == null || fragment.getActivity() != null) && !activity.isFinishing())
			showError(request, result);
	}

	@CallSuper
	public void register() {
		if (fragment != null)
			activity = fragment.getActivity();
	}

	protected void showError(Request request, ApiResult result) {
		UiHelper.showSnackbar(activity, result.getErrorStringRes() > 0 ? activity.getString(result.getErrorStringRes()) : null);
	}
}
