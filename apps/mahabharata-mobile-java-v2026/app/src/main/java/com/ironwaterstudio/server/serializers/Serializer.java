package com.ironwaterstudio.server.serializers;

import androidx.annotation.NonNull;

import java.io.Reader;
import java.io.Writer;
import java.util.HashMap;
import java.util.Map;

public abstract class Serializer {
	private static final String[] CLASSES = new String[]{"JsonSerializer", "XmlSerializer", "FormSerializer"};
	private static final Map<String, Serializer> serializers = new HashMap<>();

	public static void init() {
		String packageName = Serializer.class.getPackage().getName();
		for (String name : CLASSES) {
			try {
				Serializer serializer = (Serializer) Class.forName(packageName + "." + name).newInstance();
				for (String contentType : serializer.getContentTypes())
					serializers.put(contentType, serializer);
			} catch (Throwable ignored) {
			}
		}
	}

	public abstract String[] getContentTypes();

	public abstract void write(Object obj, Writer writer);

	public abstract <T> T read(Reader reader, Class<T> cls);

	@SuppressWarnings("unchecked")
	public static <T extends Serializer> T get(Class<T> cls) {
		for (Serializer serializer : serializers.values())
			if (cls.isInstance(serializer))
				return (T) serializer;
		return null;
	}

	public static void write(String contentType, Object obj, Writer writer) {
		if (serializers.containsKey(contentType))
			serializers.get(contentType).write(obj, writer);
	}

	public static <T> T read(String contentType, Reader reader, Class<T> cls) {
		return serializers.containsKey(contentType) ? serializers.get(contentType).read(reader, cls) : null;
	}
}
