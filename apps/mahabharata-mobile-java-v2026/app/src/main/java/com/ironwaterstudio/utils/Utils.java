package com.ironwaterstudio.utils;

import android.annotation.TargetApi;
import android.content.ClipData;
import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.content.res.TypedArray;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import androidx.annotation.Nullable;
import androidx.core.content.FileProvider;
import android.text.TextUtils;
import android.util.Base64;
import android.util.Log;
import android.util.Patterns;
import android.webkit.MimeTypeMap;
import android.widget.ArrayAdapter;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.UnsupportedEncodingException;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;

public final class Utils {
	private static final String URL_STATIC_MAP = "http://maps.google.com/maps/api/staticmap?center=%f,%f&zoom=%d&size=%dx%d&maptype=roadmap&sensor=false&language=ru";
	private static final String RATE_URL_TEMPLATE = "market://details?id=%s";
	public static final int MIN_YEAR = 1900;
	public static final TimeZone UTC_TIMEZONE = TimeZone.getTimeZone("GMT");
	public static final DateFormat DATE_FORMAT = new SimpleDateFormat(
			"dd.MM.yyyy", Locale.getDefault());

	static {
		DATE_FORMAT.setTimeZone(UTC_TIMEZONE);
	}

	public static Calendar nowDate() {
		return nowDate(false);
	}

	public static Calendar nowDate(boolean utc) {
		Calendar c = Calendar.getInstance();
		if (utc)
			c.setTimeZone(UTC_TIMEZONE);
		c.set(Calendar.HOUR_OF_DAY, 0);
		c.set(Calendar.MINUTE, 0);
		c.set(Calendar.SECOND, 0);
		c.set(Calendar.MILLISECOND, 0);
		return c;
	}

	public static Date utcDate(int year, int month, int day) {
		Calendar cal = new GregorianCalendar(UTC_TIMEZONE);
		cal.set(year + MIN_YEAR, month, day, 0, 0, 0);
		cal.set(Calendar.MILLISECOND, 0);
		return cal.getTime();
	}

	public static Date fromUnixTimeStamp(long seconds) {
		return new Date(seconds * 1000);
	}

	public static long toUnixTimeStamp(Date date) {
		return date.getTime() / 1000;
	}

	@SuppressWarnings("deprecation")
	public static int getAge(Date birthDate) {
		Date currentDate = new Date();
		if (birthDate == null)
			return -1;

		int age = currentDate.getYear() - birthDate.getYear();
		currentDate.setYear(currentDate.getYear() - age);

		if (birthDate.getTime() > currentDate.getTime())
			age--;

		return age;
	}

	public final static boolean isValidEmail(String email) {
		return !TextUtils.isEmpty(email)
				&& Patterns.EMAIL_ADDRESS.matcher(email).matches();
	}

	public static boolean isEmulator() {
		return "google_sdk".equals(Build.PRODUCT);
	}

	public static boolean isUrl(String path) {
		return path.startsWith("https://") || path.startsWith("http://");
	}

	public static String encodeToBase64(Bitmap image) {
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		image.compress(Bitmap.CompressFormat.JPEG, 50, baos);
		return Base64.encodeToString(baos.toByteArray(), Base64.DEFAULT);
	}

	@Nullable
	public static String base64(String text) {
		byte[] data;
		try {
			data = text.getBytes("UTF-8");
		} catch (UnsupportedEncodingException e) {
			e.printStackTrace();
			return null;
		}
		return Base64.encodeToString(data, Base64.DEFAULT);
	}

	public static void openUrl(Context context, String url) {
		try {
			Intent intent = new Intent(Intent.ACTION_VIEW);
			intent.setData(Uri.parse(url));
			context.startActivity(intent);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public static void openApp(Context context) {
		openApp(context, context.getPackageName());
	}

	public static void openApp(Context context, String packageName) {
		String url = String.format(RATE_URL_TEMPLATE, packageName);
		Utils.openUrl(context, url);
	}

	public static String getAppVersion(Context context) {
		try {
			return context.getPackageManager().getPackageInfo(context.getPackageName(), 0).versionName;
		} catch (Exception e) {
			e.printStackTrace();
			return "unknown";
		}
	}

	public static void dial(Context context, String phone) {
		try {
			Intent intent = new Intent(Intent.ACTION_DIAL);
			intent.setData(Uri.parse("tel:" + phone));
			context.startActivity(intent);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public static void sms(Context context, String phone, String text) {
		try {
			Intent intent = new Intent(Intent.ACTION_SENDTO);
			intent.setData(Uri.parse("smsto:" + phone));
			intent.putExtra("sms_body", text);
			context.startActivity(intent);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public static void email(Context context, String email, String subject, CharSequence body, String attachmentPath, String chooserTitle) {
		Intent emailIntent = new Intent(Intent.ACTION_SENDTO, Uri.fromParts("mailto", email, null));
		emailIntent.putExtra(Intent.EXTRA_SUBJECT, subject);
		emailIntent.putExtra(Intent.EXTRA_TEXT, body);

		if (!TextUtils.isEmpty(attachmentPath)) {
			File file = new File(attachmentPath);
			emailIntent.putExtra(Intent.EXTRA_STREAM, Uri.fromFile(file));
		}
		context.startActivity(Intent.createChooser(emailIntent, chooserTitle));
	}

	public static void share(Context context, String text, String chooserTitle) {
		share(context, null, text, chooserTitle);
	}

	public static void share(Context context, File image, String chooserTitle) {
		share(context, image, null, chooserTitle);
	}

	public static void share(Context context, File file, String text, String chooserTitle) {
		if ((file == null || !file.exists()) && TextUtils.isEmpty(text)) {
			Log.w(Utils.class.getSimpleName(), "No data found for sharing.");
			return;
		}
		final Intent shareIntent = new Intent();
		shareIntent.setAction(Intent.ACTION_SEND);
		shareIntent.setType(file != null && file.exists() ? MimeTypeMap.getSingleton().getMimeTypeFromExtension(MimeTypeMap.getFileExtensionFromUrl(file.getName())) : "text/plain");
		if (file != null && file.exists()) {
			Uri uri = uriFromFile(context, file);
			shareIntent.putExtra(Intent.EXTRA_STREAM, uri);
			shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
		}
		if (!TextUtils.isEmpty(text))
			shareIntent.putExtra(Intent.EXTRA_TEXT, text);
		context.startActivity(Intent.createChooser(shareIntent, chooserTitle));
	}

	public static Uri uriFromFile(Context context, File file) {
		if (context.getResources().getIdentifier("provider_paths", "xml", context.getPackageName()) <= 0)
			throw new RuntimeException("To use files share you need to declare FileProvider in your AndroidManifest.xml");
		return FileProvider.getUriForFile(context, context.getApplicationContext().getPackageName() + ".provider", file);
	}

	/**
	 * @deprecated use {@link androidx.core.content.res.TypedArrayUtils} instead.
	 */
	@Deprecated()
	public static int getResourceId(TypedArray a, int index, int defValue) {
		return index < a.length() ? a.getResourceId(index, defValue) : defValue;
	}

	/**
	 * @deprecated use {@link androidx.core.content.res.TypedArrayUtils} instead.
	 */
	@Deprecated()
	public static int getAttr(Context context, int attrId) {
		TypedArray a = context.obtainStyledAttributes(new int[]{attrId});
		int value = a.getInt(0, 0);
		a.recycle();
		return value;
	}

	public static int getDrawableId(Context context, String name) {
		int index = name.lastIndexOf('.');
		if (index > 0)
			name = name.substring(0, index);
		return context.getResources().getIdentifier(name, "drawable", context.getPackageName());
	}

	public static boolean parseBoolean(String value, boolean defValue) {
		if (TextUtils.isEmpty(value))
			return defValue;
		try {
			return Boolean.parseBoolean(value);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return defValue;
	}

	public static int parseInt(String value, int defValue) {
		if (TextUtils.isEmpty(value))
			return defValue;
		try {
			return Integer.parseInt(value);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return defValue;
	}

	public static long parseLong(String value, long defValue) {
		if (TextUtils.isEmpty(value))
			return defValue;
		try {
			return Long.parseLong(value);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return defValue;
	}

	public static float parseFloat(String value, float defValue) {
		if (TextUtils.isEmpty(value))
			return defValue;
		try {
			return Float.parseFloat(value);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return defValue;
	}

	public static Date parseDate(String value, Date defValue) {
		if (TextUtils.isEmpty(value))
			return defValue;
		try {
			return DATE_FORMAT.parse(value);
		} catch (ParseException e) {
			return defValue;
		}
	}

	public static void setLocale(Context context, List<String> languages) {
		if (languages == null || languages.isEmpty())
			return;

		Locale locale = new Locale(languages.get(0));
		Resources res = context.getResources();
		Configuration config = res.getConfiguration();

		if (!languages.contains(Locale.getDefault().getLanguage()))
			Locale.setDefault(locale);

		if (!languages.contains(config.locale.getLanguage())) {
			config.locale = locale;
			res.updateConfiguration(config, res.getDisplayMetrics());
		}
	}

	@TargetApi(Build.VERSION_CODES.HONEYCOMB)
	public static <T> void addAll(ArrayAdapter<T> adapter, ArrayList<T> items) {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
			adapter.addAll(items);
		} else {
			for (T item : items)
				adapter.add(item);
		}
	}

	@SuppressWarnings("deprecation")
	public static void copyToClipboard(Context context, String text) {
		if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.HONEYCOMB) {
			android.text.ClipboardManager clipboard = (android.text.ClipboardManager) context.getSystemService(Context.CLIPBOARD_SERVICE);
			clipboard.setText(text);
		} else {
			android.content.ClipboardManager clipboard = (android.content.ClipboardManager) context.getSystemService(Context.CLIPBOARD_SERVICE);
			ClipData clip = ClipData.newPlainText(text, text);
			clipboard.setPrimaryClip(clip);
		}
	}

	public static void exportLog(Context context) {
		try {
			File file = new File(context.getExternalCacheDir(), "log.txt");
			Process process = Runtime.getRuntime().exec("logcat -d -v long");
			if (FileUtils.copyStream(process.getInputStream(), new FileOutputStream(file)))
				email(context, "", context.getPackageName() + " log file", "", file.getAbsolutePath(), "Email...");
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public static void showRoute(Context context, double lat, double lng) {
		Intent intent = new Intent(android.content.Intent.ACTION_VIEW,
				Uri.parse(String.format(Locale.ENGLISH, "http://maps.google.com/maps?daddr=%f,%f", lat, lng)));
		context.startActivity(intent);
	}

	public static String getStaticMapUrl(double lat, double lng, int zoom, int width, int height) {
		return String.format(URL_STATIC_MAP, lat, lng, zoom, width, height);
	}
}
