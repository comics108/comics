package com.ironwaterstudio.server.http;

import android.os.Parcel;
import android.os.Parcelable;
import androidx.annotation.Keep;

import java.net.HttpCookie;
import java.util.Locale;

@Keep
public class HttpCookieParcelable implements Parcelable {
	private HttpCookie cookie;
	private long whenCreated;

	public HttpCookieParcelable(HttpCookie cookie) {
		this.cookie = cookie;
		whenCreated = System.currentTimeMillis();
	}

	public HttpCookieParcelable(Parcel source) {
		String name = source.readString();
		String value = source.readString();
		cookie = new HttpCookie(name, value);
		cookie.setComment(source.readString());
		cookie.setCommentURL(source.readString());
		cookie.setDiscard(source.readByte() != 0);
		cookie.setDomain(source.readString());
		cookie.setMaxAge(source.readLong());
		cookie.setPath(source.readString());
		cookie.setPortlist(source.readString());
		cookie.setSecure(source.readByte() != 0);
		cookie.setVersion(source.readInt());
		whenCreated = source.readLong();
		if (whenCreated == 0)
			whenCreated = System.currentTimeMillis();
	}

	public HttpCookie getCookie() {
		return cookie;
	}

	public boolean hasExpired() {
		long maxAge = cookie.getMaxAge();
		if (maxAge == -1L)
			return false;

		long deltaSecond = (System.currentTimeMillis() - whenCreated) / 1000;
		return deltaSecond > maxAge;
	}

	@Override
	public int describeContents() {
		return 0;
	}

	@Override
	public void writeToParcel(Parcel dest, int flags) {
		dest.writeString(cookie.getName());
		dest.writeString(cookie.getValue());
		dest.writeString(cookie.getComment());
		dest.writeString(cookie.getCommentURL());
		dest.writeByte((byte) (cookie.getDiscard() ? 1 : 0));
		dest.writeString(cookie.getDomain());
		dest.writeLong(cookie.getMaxAge());
		dest.writeString(cookie.getPath());
		dest.writeString(cookie.getPortlist());
		dest.writeByte((byte) (cookie.getSecure() ? 1 : 0));
		dest.writeInt(cookie.getVersion());
		dest.writeLong(whenCreated);
	}

	@Override
	public boolean equals(Object obj) {
		return obj instanceof HttpCookieParcelable && getCookie().equals(((HttpCookieParcelable) obj).getCookie());
	}

	@Override
	public int hashCode() {
		return getCookie().hashCode();
	}

	@Override
	public String toString() {
		return getCookie().toString();
	}

	public String encode() {
		final Parcel p = Parcel.obtain();
		try {
			p.writeValue(this);
			return byteArrayToHexString(p.marshall());
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		} finally {
			p.recycle();
		}
	}

	public static HttpCookieParcelable decode(String cookieString) {
		final Parcel p = Parcel.obtain();
		try {
			byte[] bytes = hexStringToByteArray(cookieString);
			p.unmarshall(bytes, 0, bytes.length);
			p.setDataPosition(0);
			return (HttpCookieParcelable) p.readValue(HttpCookieParcelable.class.getClassLoader());
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		} finally {
			p.recycle();
		}
	}

	private static String byteArrayToHexString(byte[] bytes) {
		StringBuilder sb = new StringBuilder(bytes.length * 2);
		for (byte element : bytes) {
			int v = element & 0xff;
			if (v < 16) {
				sb.append('0');
			}
			sb.append(Integer.toHexString(v));
		}
		return sb.toString().toUpperCase(Locale.getDefault());
	}

	private static byte[] hexStringToByteArray(String hexString) {
		int len = hexString.length();
		byte[] data = new byte[len / 2];
		for (int i = 0; i < len; i += 2) {
			data[i / 2] = (byte) ((Character.digit(hexString.charAt(i), 16) << 4) + Character
					.digit(hexString.charAt(i + 1), 16));
		}
		return data;
	}

	public static final Parcelable.Creator<HttpCookieParcelable> CREATOR =
			new Creator<HttpCookieParcelable>() {
				@Override
				public HttpCookieParcelable[] newArray(int size) {
					return new HttpCookieParcelable[size];
				}

				@Override
				public HttpCookieParcelable createFromParcel(Parcel source) {
					return new HttpCookieParcelable(source);
				}
			};
}