package com.ironwaterstudio.utils;

import android.annotation.SuppressLint;
import android.text.TextUtils;
import android.util.Base64;

import java.security.InvalidKeyException;
import java.security.KeyFactory;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.PublicKey;
import java.security.Signature;
import java.security.SignatureException;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.X509EncodedKeySpec;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public final class CryptoManager {
	private static String TRANSFORMATION = "AES/CBC/PKCS7Padding";
	private static String ALGORITHM = "AES";
	private static String DIGEST = "MD5";
	private static String KEY_FACTORY_ALGORITHM = "RSA";
	private static String SIGNATURE_ALGORITHM = "SHA1withRSA";

	public static final String md5(final String s) {
		try {
			// Create MD5 Hash
			MessageDigest digest = java.security.MessageDigest
					.getInstance(DIGEST);
			digest.update(s.getBytes());
			byte messageDigest[] = digest.digest();

			// Create Hex String
			StringBuffer hexString = new StringBuffer();
			for (int i = 0; i < messageDigest.length; i++) {
				String h = Integer.toHexString(0xFF & messageDigest[i]);
				while (h.length() < 2)
					h = "0" + h;
				hexString.append(h);
			}
			return hexString.toString();

		} catch (NoSuchAlgorithmException e) {
			e.printStackTrace();
		}
		return null;
	}

	@SuppressLint("TrulyRandom")
	public static String encrypt(String value, String key, String iv) {
		try {
			SecretKeySpec keySpec = new SecretKeySpec(key.getBytes(), ALGORITHM);
			IvParameterSpec ivParamSpec = new IvParameterSpec(iv.getBytes());

			Cipher cipher = Cipher.getInstance(TRANSFORMATION);
			cipher.init(Cipher.ENCRYPT_MODE, keySpec, ivParamSpec);
			byte data[] = cipher.doFinal(value.getBytes());
			return Base64.encodeToString(data, Base64.DEFAULT);
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	public static String decrypt(String value, String key, String iv) {
		try {
			SecretKeySpec keySpec = new SecretKeySpec(key.getBytes(), ALGORITHM);
			IvParameterSpec ivParamSpec = new IvParameterSpec(iv.getBytes());

			Cipher cipher = Cipher.getInstance(TRANSFORMATION);
			cipher.init(Cipher.DECRYPT_MODE, keySpec, ivParamSpec);
			byte[] data = Base64.decode(value.getBytes(), Base64.DEFAULT);
			return new String(cipher.doFinal(data));
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	public static boolean verify(String base64PublicKey, String signedData, String signature) {
		if (TextUtils.isEmpty(signedData) || TextUtils.isEmpty(base64PublicKey) ||
				TextUtils.isEmpty(signature)) {
			return false;
		}
		boolean isVerify = false;
		try {
			PublicKey key = generatePublicKey(base64PublicKey);
			isVerify = verify(key, signedData, signature);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return isVerify;
	}

	private static PublicKey generatePublicKey(String encodedPublicKey)
			throws NoSuchAlgorithmException, InvalidKeySpecException {
		byte[] decodedKey = Base64.decode(encodedPublicKey, Base64.DEFAULT);
		KeyFactory keyFactory = KeyFactory.getInstance(KEY_FACTORY_ALGORITHM);
		return keyFactory.generatePublic(new X509EncodedKeySpec(decodedKey));
	}

	private static boolean verify(PublicKey publicKey, String signedData, String signature)
			throws NoSuchAlgorithmException, InvalidKeyException, SignatureException {
		Signature sig = Signature.getInstance(SIGNATURE_ALGORITHM);
		sig.initVerify(publicKey);
		sig.update(signedData.getBytes());
		return sig.verify(Base64.decode(signature, Base64.DEFAULT));
	}
}
