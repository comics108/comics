package com.ironwaterstudio.server.http;

import com.ironwaterstudio.server.ProgressInputStream;
import com.ironwaterstudio.server.ResponseInfo;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.utils.FileUtils;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.HttpURLConnection;

public class HttpFileRequest extends HttpRequest {
	private OutputStream out = null;

	public HttpFileRequest(String method) {
		super(method);
	}

	public HttpFileRequest setFile(File file) {
		try {
			out = new BufferedOutputStream(new FileOutputStream(file));
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
		return this;
	}

	public HttpFileRequest(HttpFileRequest request) {
		super(request);
		out = request.out;
	}

	public HttpFileRequest setStream(OutputStream out) {
		this.out = new BufferedOutputStream(out);
		return this;
	}

	@Override
	protected ResponseInfo execute() {
		if (out == null)
			return null;

		HttpURLConnection conn = null;
		try {
			conn = HttpHelper.createRequest(HttpHelper.CT_BINARY, HttpHelper.METHOD_GET, getAction(), getHeaders(), getTimeout());
			int responseCode = HttpHelper.getResponseCode(conn);
			if (responseCode >= HttpURLConnection.HTTP_BAD_REQUEST || responseCode == HttpURLConnection.HTTP_NOT_MODIFIED)
				return null;
			if (FileUtils.copyStream(ProgressInputStream.create(getTask(), conn.getInputStream(), conn.getContentLength(), isPublishProgress()), out, false))
				return new ResponseInfo(HttpURLConnection.HTTP_OK, null, HttpHelper.getContentType(conn));
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			try {
				if (conn != null)
					conn.disconnect();
				if (out != null)
					out.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		return null;
	}

	@Override
	public ApiResult parseResponse(ResponseInfo responseInfo) {
		return ApiResult.create(responseInfo.isFromCache() || responseInfo.getCode() == HttpURLConnection.HTTP_OK ?
				ApiResult.SUCCESS : ApiResult.CONNECTION_ERROR);
	}

	@Override
	protected HttpRequest copy() {
		return new HttpFileRequest(this);
	}
}
