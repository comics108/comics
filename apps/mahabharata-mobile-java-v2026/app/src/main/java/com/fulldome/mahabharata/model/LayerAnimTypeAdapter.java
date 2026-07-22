package com.fulldome.mahabharata.model;

import com.fulldome.mahabharata.model.visual.animation.AlphaAnim;
import com.fulldome.mahabharata.model.visual.animation.LayerAnim;
import com.fulldome.mahabharata.model.visual.animation.AnimType;
import com.fulldome.mahabharata.model.visual.animation.RotateAnim;
import com.fulldome.mahabharata.model.visual.animation.ScaleAnim;
import com.fulldome.mahabharata.model.visual.animation.TranslateAnim;
import com.google.gson.JsonDeserializationContext;
import com.google.gson.JsonDeserializer;
import com.google.gson.JsonElement;
import com.google.gson.JsonParseException;

import java.lang.reflect.Type;
import java.util.Map;
import java.util.TreeMap;

public class LayerAnimTypeAdapter implements JsonDeserializer<LayerAnim> {
	private static Map<AnimType, Class> TYPES = new TreeMap<>();

	static {
		TYPES.put(AnimType.TRANSLATE, TranslateAnim.class);
		TYPES.put(AnimType.ROTATE, RotateAnim.class);
		TYPES.put(AnimType.SCALE, ScaleAnim.class);
		TYPES.put(AnimType.ALPHA, AlphaAnim.class);
	}

	@Override
	public LayerAnim deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context) throws JsonParseException {
		JsonElement element = json.getAsJsonObject().get("type");
		AnimType type = AnimType.values()[element != null ? element.getAsInt() : 0];
		Class c = TYPES.get(type);
		if (c == null)
			throw new RuntimeException("Unknown class: " + type);
		return context.deserialize(json, c);
	}
}