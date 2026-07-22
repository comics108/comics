package com.ironwaterstudio.server;

import com.ironwaterstudio.server.data.ApiResult;

public class ActionRequest extends Request {
	private final Runnable runnable;

	public ActionRequest(Runnable runnable) {
		super("");
		this.runnable = runnable;
	}

	public ActionRequest(ActionRequest request) {
		super(request);
		runnable = request.runnable;
	}

	@Override
	protected ResponseInfo execute() {
		return null;
	}

	@Override
	protected Request copy() {
		return new ActionRequest(this);
	}

	@Override
	public ApiResult call() {
		try {
			Object runnableResult = runnable.run();
			if (runnableResult instanceof ApiResult)
				return (ApiResult) runnableResult;
			ApiResult result = ApiResult.create(ApiResult.SUCCESS);
			result.setObject(runnableResult);
			return result;
		} catch (Throwable t) {
			t.printStackTrace();
			return ApiResult.create(ApiResult.ERROR);
		}
	}

	/**
	 * Method sets the request task to task of parent action request.
	 * This is required for properly progress handling in the inner request.
	 */
	public <T extends Request> T bindTo(T request) {
		if (request != null)
			request.setTask(getTask());
		return request;
	}

	public interface Runnable {
		Object run();
	}
}
