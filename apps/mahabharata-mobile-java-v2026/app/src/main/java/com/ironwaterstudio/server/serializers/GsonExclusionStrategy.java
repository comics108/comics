package com.ironwaterstudio.server.serializers;

import com.google.gson.ExclusionStrategy;
import com.google.gson.FieldAttributes;

public class GsonExclusionStrategy implements ExclusionStrategy {
	private final boolean serialization;

	public GsonExclusionStrategy(boolean serialization) {
		this.serialization = serialization;
	}

	@Override
	public boolean shouldSkipField(FieldAttributes f) {
		return shouldSkip(f.getAnnotation(Ignore.class));
	}

	@Override
	public boolean shouldSkipClass(Class<?> clazz) {
		return shouldSkip(clazz.getAnnotation(Ignore.class));
	}

	private boolean shouldSkip(Ignore ignore) {
		return ignore != null && (serialization ? ignore.serialize() : ignore.deserialize());
	}
}
