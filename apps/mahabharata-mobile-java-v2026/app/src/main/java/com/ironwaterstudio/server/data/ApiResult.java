package com.ironwaterstudio.server.data;

import androidx.annotation.Keep;

import com.fulldome.mahabharata.R;
import com.google.gson.JsonElement;
import com.ironwaterstudio.server.ResponseInfo;
import com.ironwaterstudio.server.serializers.JsonSerializer;
import com.ironwaterstudio.server.serializers.Serializer;

@Keep
public class ApiResult {
	public static final int CANCEL_ERROR = 101;
	public static final int CONNECTION_ERROR = 100;
	public static final int SUCCESS = 0;
	public static final int ERROR = 1;
	public static final int INVALID_INPUT_DATA = 2;
	public static final int RECORD_NOT_FOUND = 3;
	public static final int RECORD_ALREADY_EXISTS = 4;
	public static final int NEED_TO_LOGIN = 5;

	private String msg = "";
	private JsonElement data = null;
	private int code = 0;
	private transient Object obj = null;

	public int getErrorStringRes() {
		switch (code) {
			case ERROR:
				return R.string.error_common;
			case CONNECTION_ERROR:
				return R.string.error_connection;
			default:
				return -1;
		}
	}

	public boolean isSuccess() {
		return code == SUCCESS || isFromCache();
	}

	public boolean isFromCache() {
		return code == ResponseInfo.CODE_CACHE;
	}

	public String getMsg() {
		return msg;
	}

	public void setMsg(String msg) {
		this.msg = msg;
	}

	public String getDataString() {
		return data.toString();
	}

	public int getCode() {
		return this.code;
	}

	public void setCode(int code) {
		this.code = code;
	}

	@SuppressWarnings({"unchecked", "ConstantConditions"})
	public <T> T getData(Class<T> cls) {
		if (obj != null && cls.isInstance(obj))
			return (T) obj;
		return data != null ? Serializer.get(JsonSerializer.class).read(data, cls) : null;
	}

	public Object getObject() {
		return obj;
	}

	public void setObject(Object obj) {
		this.obj = obj;
	}

	public static ApiResult create(int code) {
		ApiResult result = new ApiResult();
		result.setCode(code);
		return result;
	}

	public static ApiResult connectionError() {
		return create(CONNECTION_ERROR);
	}

	public static ApiResult createCancel() {
		return create(CANCEL_ERROR);
	}

	public static ApiResult fromObject(Object obj) {
		ApiResult result = create(obj != null ? SUCCESS : CONNECTION_ERROR);
		result.setObject(obj);
		return result;
	}
}
