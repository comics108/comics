package com.ironwaterstudio.controls;

import android.content.Context;
import android.graphics.Paint;
import android.graphics.Typeface;
import androidx.annotation.ColorRes;
import androidx.annotation.FontRes;
import androidx.annotation.StringRes;
import androidx.core.content.ContextCompat;
import androidx.core.content.res.ResourcesCompat;
import android.text.Spannable;
import android.text.SpannableString;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.TextPaint;
import android.text.style.TypefaceSpan;

import com.ironwaterstudio.utils.UiHelper;

public class TypefaceSpanEx extends TypefaceSpan {
	private final Typeface typeface;
	private final float size;
	private final int color;

	public TypefaceSpanEx(TypefaceSpanEx span) {
		super("");
		typeface = span.typeface;
		size = span.size;
		color = span.color;
	}

	public TypefaceSpanEx(Context context, @FontRes int fontId, int sizeSp, @ColorRes int colorId) {
		this(context, fontId, UiHelper.spToPx(context, sizeSp), colorId);
	}

	public TypefaceSpanEx(Context context, @FontRes int fontId, float sizePx, @ColorRes int colorId) {
		this(context, fontId, sizePx, (Integer) ContextCompat.getColor(context, colorId));
	}

	public TypefaceSpanEx(Context context, @FontRes int fontId, int sizeSp, Integer color) {
		this(context, fontId, UiHelper.spToPx(context, sizeSp), color);
	}

	public TypefaceSpanEx(Context context, @FontRes int fontId, float sizePx, Integer color) {
		super("");
		this.typeface = ResourcesCompat.getFont(context, fontId);
		this.size = sizePx;
		this.color = color;
	}

	public Typeface getTypeface() {
		return typeface;
	}

	public float getSize() {
		return size;
	}

	public int getColor() {
		return color;
	}

	@Override
	public void updateDrawState(TextPaint ds) {
		applyStyle(ds, typeface, size, color);
	}

	@Override
	public void updateMeasureState(TextPaint paint) {
		applyStyle(paint, typeface, size, color);
	}

	public TypefaceSpanEx copy() {
		return new TypefaceSpanEx(this);
	}

	private static void applyStyle(Paint paint, Typeface tf, float size, int color) {
		paint.setTypeface(tf);
		paint.setTextSize(size);
		paint.setColor(color);
	}

	public static CharSequence getString(Context context, @StringRes int textResId, @FontRes int fontId, int sizeSp, @ColorRes int colorId) {
		SpannableString text = new SpannableString(context.getString(textResId));
		text.setSpan(new TypefaceSpanEx(context, fontId, sizeSp, colorId), 0, text.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
		return text;
	}

	public static CharSequence getString(Context context, @StringRes int textResId, @FontRes int fontId, float sizePx, @ColorRes int colorId) {
		SpannableString text = new SpannableString(context.getString(textResId));
		text.setSpan(new TypefaceSpanEx(context, fontId, sizePx, colorId), 0, text.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
		return text;
	}

	public static void append(Context context, SpannableStringBuilder builder, @FontRes int fontId, int sizeSp, @ColorRes int colorId, String text) {
		append(context, builder, fontId, UiHelper.spToPx(context, sizeSp), colorId, text);
	}

	public static void append(Context context, SpannableStringBuilder builder, @FontRes int fontId, float sizePx, @ColorRes int colorId, String text) {
		SpannableString spannable = new SpannableString(text);
		spannable.setSpan(new TypefaceSpanEx(context, fontId, sizePx, colorId), 0, spannable.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
		builder.append(spannable);
	}
}
