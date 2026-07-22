package com.ironwaterstudio.server.serializers;

import androidx.annotation.Keep;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonElement;
import com.ironwaterstudio.server.http.HttpHelper;
import com.ironwaterstudio.utils.FileUtils;

import java.io.Reader;
import java.io.Writer;

@Keep
public final class JsonSerializer extends Serializer {
	private static final String[] CONTENT_TYPES = new String[]{HttpHelper.CT_JSON};
	private Gson gson = new GsonBuilder()
			.addSerializationExclusionStrategy(new GsonExclusionStrategy(true))
			.addDeserializationExclusionStrategy(new GsonExclusionStrategy(false)).create();

	public void setGson(Gson gson) {
		this.gson = gson;
	}

	@Override
	public String[] getContentTypes() {
		return CONTENT_TYPES;
	}

	@Override
	public void write(Object obj, Writer writer) {
		try {
			if (writer != null)
				gson.toJson(obj, writer);
		} catch (Throwable t) {
			t.printStackTrace();
		} finally {
			FileUtils.close(writer);
		}
	}

	@Override
	public <T> T read(Reader reader, Class<T> cls) {
		try {
			return reader != null ? gson.fromJson(reader, cls) : null;
		} catch (Throwable t) {
			t.printStackTrace();
			return null;
		} finally {
			FileUtils.close(reader);
		}
	}

	public <T> T read(JsonElement json, Class<T> cls) {
		try {
			return gson.fromJson(json, cls);
		} catch (Throwable t) {
			t.printStackTrace();
			return null;
		}
	}

	public String write(Object obj) {
		return gson.toJson(obj);
	}

	public <T> T read(String json, Class<T> cls) {
		try {
			return gson.fromJson(json, cls);
		} catch (Throwable t) {
			t.printStackTrace();
			return null;
		}
	}
}