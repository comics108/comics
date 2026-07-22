package com.ironwaterstudio.utils;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

public class ReflectionUtils {
	private static final Map<Integer, Map<String, Field>> fieldsMap = new HashMap<>();

	private static Map<String, Field> buildFieldsMap(Class<?> cls, FieldsStrategy strategy) {
		Map<String, Field> fields = new HashMap<>();
		Class<?> current = cls;
		do {
			for (Field field : current.getDeclaredFields()) {
				if (Modifier.isStatic(field.getModifiers()) || strategy.isIgnore(field))
					continue;
				fields.put(strategy.getName(field), field);
			}
			current = current.getSuperclass();
		} while (current != null && current.getSuperclass() != null);
		return fields;
	}

	public static Map<String, Field> getFields(Class<?> cls, FieldsStrategy strategy) {
		int key = String.valueOf(cls.hashCode() + ";" + (strategy != null ? strategy.hashCode() : 0)).hashCode();
		Map<String, Field> fields = fieldsMap.get(key);
		if (fields != null)
			return fields;

		synchronized (fieldsMap) {
			fields = fieldsMap.get(key);
			if (fields != null)
				return fields;
			fields = buildFieldsMap(cls, strategy != null ? strategy : new FieldsStrategy());
			fieldsMap.put(key, fields);
		}
		return fields;
	}

	@SuppressWarnings("unchecked")
	public static Map<String, Object> buildMap(Object obj, FieldsStrategy strategy) {
		if (obj == null)
			return null;

		if (obj instanceof Map)
			return (Map<String, Object>) obj;
		if (isElement(obj.getClass()) || isCollection(obj.getClass()))
			return null;

		Map<String, Field> fields = getFields(obj.getClass(), strategy);
		Map<String, Object> result = new HashMap<>();
		for (String name : fields.keySet())
			result.put(name, ReflectionUtils.get(fields.get(name), obj));
		return result;
	}

	public static boolean isElement(Class<?> cls) {
		return cls.isPrimitive() || cls.equals(String.class) || cls.equals(Boolean.class) || Number.class.isAssignableFrom(cls);
	}

	public static boolean isCollection(Class<?> cls) {
		return cls.isArray() || Collection.class.isAssignableFrom(cls);
	}

	public static void set(Field field, Object object, Object value) {
		try {
			field.setAccessible(true);
			field.set(object, value);
			field.setAccessible(false);
		} catch (IllegalAccessException e) {
			e.printStackTrace();
		}
	}

	public static Object get(Field field, Object object) {
		Object value = null;
		try {
			field.setAccessible(true);
			value = field.get(object);
			field.setAccessible(false);
		} catch (IllegalAccessException e) {
			e.printStackTrace();
		}
		return value;
	}

	public static class FieldsStrategy {
		public String getName(Field field) {
			return field.getName();
		}

		public boolean isIgnore(Field field) {
			return false;
		}
	}
}
