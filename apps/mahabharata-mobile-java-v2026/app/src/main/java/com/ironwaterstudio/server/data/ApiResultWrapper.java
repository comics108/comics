package com.ironwaterstudio.server.data;

import androidx.annotation.Keep;

import com.google.gson.annotations.SerializedName;

@Keep
public class ApiResultWrapper {
	@SerializedName("d")
	private ApiResult result = null;

	public ApiResult getResult() {
		return result;
	}
}
