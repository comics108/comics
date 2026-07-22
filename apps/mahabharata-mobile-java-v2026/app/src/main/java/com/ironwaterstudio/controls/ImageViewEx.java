package com.ironwaterstudio.controls;

import android.animation.ObjectAnimator;
import android.content.Context;
import android.content.res.ColorStateList;
import android.content.res.TypedArray;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.drawable.DrawableCompat;
import androidx.appcompat.widget.AppCompatImageView;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.FrameLayout;
import android.widget.ImageView;

import com.fulldome.mahabharata.R;
import com.ironwaterstudio.server.CacheManager;
import com.ironwaterstudio.server.ServiceCallTask;
import com.ironwaterstudio.server.data.ApiResult;
import com.ironwaterstudio.server.http.HttpImageRequest;
import com.ironwaterstudio.server.listeners.OnCallListener;
import com.ironwaterstudio.server.listeners.SimpleCallListener;

public class ImageViewEx extends FrameLayout {
	public static final int CACHE_NONE = 0x00000000;
	public static final int CACHE_FILE = 0x00000010;
	public static final int CACHE_MEMORY = 0x00000020;

	private static final ImageView.ScaleType[] SCALE_TYPES = {
			ImageView.ScaleType.MATRIX,
			ImageView.ScaleType.FIT_XY,
			ImageView.ScaleType.FIT_START,
			ImageView.ScaleType.FIT_CENTER,
			ImageView.ScaleType.FIT_END,
			ImageView.ScaleType.CENTER,
			ImageView.ScaleType.CENTER_CROP,
			ImageView.ScaleType.CENTER_INSIDE
	};

	private AppCompatImageView ivDefault = null;
	private AppCompatImageView ivMain = null;

	private String cacheKey = null;
	private int cacheMode = CACHE_NONE;
	private int cachePeriod = 3650; // 10 years in days
	private boolean autoSize = false;
	private ColorStateList imageTint = null;
	private ColorStateList imageTintDefault = null;
	private ServiceCallTask task = null;
	private Animation animation = null;

	private boolean isAlreadyModify = false;
	private float borderWidth = 0;
	private int borderColor;
	private float cornerRadius = 0;
	private Drawable mask = null;

	private HttpImageRequest request = null;
	private OnCallListener loadListener = null;
	private boolean reloadImage = false;
	private Runnable reloadRunnable = new Runnable() {
		@Override
		public void run() {
			if (request != null)
				setImage(request, loadListener);
		}
	};

	private final SimpleCallListener defaultCallListener = new SimpleCallListener() {
		@Override
		public void onSuccess(ApiResult result) {
			setImageBitmap(result.getData(Bitmap.class), true);
		}
	};

	private Animation.AnimationListener animationListener = new Animation.AnimationListener() {
		@Override
		public void onAnimationStart(Animation animation) {
			ivDefault.setVisibility(VISIBLE);
			ivMain.setVisibility(VISIBLE);
			ObjectAnimator.ofFloat(ivDefault, "alpha", 1f, 0f).setDuration(animation.getDuration()).start();
		}

		@Override
		public void onAnimationEnd(Animation animation) {
			ivDefault.setVisibility(INVISIBLE);
			ivDefault.setAlpha(1f);
		}

		@Override
		public void onAnimationRepeat(Animation animation) {
		}
	};

	public ImageViewEx(Context context, AttributeSet attrs) {
		super(context, attrs);
		ivDefault = new AppCompatImageView(context);
		ivMain = new AppCompatImageView(context);
		ivDefault.setVisibility(VISIBLE);
		ivMain.setVisibility(INVISIBLE);

		TypedArray a = context.obtainStyledAttributes(attrs, R.styleable.ImageViewEx);
		borderWidth = a.getDimension(R.styleable.ImageViewEx_edgeWidth, borderWidth);
		borderColor = a.getColor(R.styleable.ImageViewEx_edgeColor, ContextCompat.getColor(context, android.R.color.white));
		cornerRadius = a.getDimension(R.styleable.ImageViewEx_cornerRadius, cornerRadius);
		mask = a.getDrawable(R.styleable.ImageViewEx_mask);
		cacheMode = a.getInteger(R.styleable.ImageViewEx_cacheMode, cacheMode);
		cachePeriod = a.getInt(R.styleable.ImageViewEx_cachePeriod, cachePeriod);
		autoSize = a.getBoolean(R.styleable.ImageViewEx_autoSize, autoSize);
		imageTint = a.getColorStateList(R.styleable.ImageViewEx_imageTint);
		imageTintDefault = a.getColorStateList(R.styleable.ImageViewEx_imageTintDefault);
		int animId = a.getResourceId(R.styleable.ImageViewEx_animation, -1);
		if (animId != -1)
			setImageAnimation(AnimationUtils.loadAnimation(context, animId));
		setImageDrawableDefault(a.getDrawable(R.styleable.ImageViewEx_srcDefault));
		setImageDrawable(a.getDrawable(R.styleable.ImageViewEx_srcMain), animation != null);
		int indexMain = a.getInt(R.styleable.ImageViewEx_scaleType, 3);
		setScaleType(SCALE_TYPES[indexMain]);
		int indexDefault = a.getInt(R.styleable.ImageViewEx_scaleTypeDefault, -1);
		setScaleTypeDefault(SCALE_TYPES[indexDefault == -1 ? indexMain : indexDefault]);
		if (a.getBoolean(R.styleable.ImageViewEx_showProgress, false))
			showProgress();
		a.recycle();

		ViewGroup.LayoutParams params = new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
		addView(ivDefault, params);
		addView(ivMain, params);
	}

	public Drawable getMask() {
		return mask;
	}

	public void setMask(Drawable mask) {
		this.mask = mask;
	}

	@Override
	protected void onDetachedFromWindow() {
		super.onDetachedFromWindow();
		reloadImage = cancelCurrentTask();
	}

	@Override
	protected void onAttachedToWindow() {
		super.onAttachedToWindow();
		if (reloadImage) {
			post(reloadRunnable);
			reloadImage = false;
		}
	}

	public void setCacheMode(int cacheMode) {
		this.cacheMode = cacheMode;
	}

	public int getCacheMode() {
		return cacheMode;
	}

	public void setCachePeriod(int cachePeriod) {
		this.cachePeriod = cachePeriod;
	}

	public void setAutoSize(boolean autoSize) {
		this.autoSize = autoSize;
	}

	public ColorStateList getImageTint() {
		return imageTint;
	}

	public void setImageTint(ColorStateList imageTint) {
		this.imageTint = imageTint;
		if (ivMain.getDrawable() != null && imageTint != null) {
			Drawable drawable = DrawableCompat.wrap(ivMain.getDrawable()).mutate();
			DrawableCompat.setTintList(drawable, imageTint);
			ivMain.setImageDrawable(drawable);
		}
	}

	public ColorStateList getImageTintDefault() {
		return imageTintDefault;
	}

	public void setImageTintDefault(ColorStateList imageTintDefault) {
		this.imageTintDefault = imageTintDefault;
		if (ivDefault.getDrawable() != null && imageTintDefault != null) {
			Drawable drawable = DrawableCompat.wrap(ivDefault.getDrawable()).mutate();
			DrawableCompat.setTintList(drawable, imageTintDefault);
			ivDefault.setImageDrawable(drawable);
		}
	}

	public void setImageBitmapDefault(Bitmap bitmap) {
		setImageDrawableDefault(new BitmapDrawable(getContext().getResources(), bitmap));
	}

	public void setImageDrawableDefault(Drawable drawable) {
		if (drawable != null && imageTintDefault != null) {
			drawable = DrawableCompat.wrap(drawable).mutate();
			DrawableCompat.setTintList(drawable, imageTintDefault);
		}
		ivDefault.setImageDrawable(drawable);
	}

	public void setImageBitmap(Bitmap bitmap) {
		setImageBitmap(bitmap, false);
	}

	public void setImageBitmap(Bitmap bitmap, boolean animate) {
		setImageDrawable(bitmap == null ? null : new BitmapDrawable(getContext().getResources(), bitmap), animate);
	}

	public void setImageDrawable(Drawable drawable) {
		setImageDrawable(drawable, false);
	}

	public void setImageDrawable(Drawable drawable, final boolean animate) {
		cancelCurrentTask();
		if (drawable != null && imageTint != null) {
			drawable = DrawableCompat.wrap(drawable).mutate();
			DrawableCompat.setTintList(drawable, imageTint);
		}
		ivMain.clearAnimation();
		ivMain.setImageDrawable(drawable);
		if (drawable == null) {
			ivDefault.setVisibility(VISIBLE);
			ivMain.setVisibility(INVISIBLE);
			return;
		}
		if (needModification()) {
			isAlreadyModify = true;
			if (getWidth() > 0) {
				modifyImage(animate);
			} else {
				post(new Runnable() {
					@Override
					public void run() {
						modifyImage(animate);
					}
				});
			}
			return;
		}
		if ((cacheMode & CACHE_MEMORY) > 0 && !TextUtils.isEmpty(cacheKey) && drawable instanceof BitmapDrawable) {
			CacheManager.getBitmapCache().put(cacheKey, ((BitmapDrawable) drawable).getBitmap());
			cacheKey = null;
		}
		if (animation != null && animate) {
			ivMain.startAnimation(animation);
		} else {
			ivDefault.setVisibility(INVISIBLE);
			ivMain.setVisibility(VISIBLE);
		}
	}

	private boolean needModification() {
		return (cornerRadius > 0 || borderWidth > 0 || mask != null) && !isAlreadyModify;
	}

	public void setScaleTypeDefault(ImageView.ScaleType scaleTypeDefault) {
		ivDefault.setScaleType(scaleTypeDefault);
	}

	public void setScaleType(ImageView.ScaleType scaleTypeDefault) {
		ivMain.setScaleType(scaleTypeDefault);
	}

	public void setImageAnimation(Animation animation) {
		ivMain.clearAnimation();
		animation.setAnimationListener(animationListener);
		this.animation = animation;
	}

	public ImageView getMainImageView() {
		return ivMain;
	}

	public ImageView getDefaultImageView() {
		return ivDefault;
	}

	private void startTask() {
		if (request == null || fromCache(request.getAction()))
			return;

		cancelCurrentTask();
		long period = (cacheMode & CACHE_FILE) > 0 ? cachePeriod * 86400000L : 0;
		if (autoSize && !request.isScaled() && getWidth() > 0 && getHeight() > 0)
			request.setSize(getWidth(), getHeight());
		if (request.getCachePeriod() <= 0 && period > 0)
			request.setCache(HttpImageRequest.CACHE_STATIC, period);
		task = request.call(loadListener != null ? loadListener : defaultCallListener);
	}

	private boolean cancelCurrentTask() {
		reloadImage = false;
		removeCallbacks(reloadRunnable);
		boolean result = task != null && task.cancel(true);
		task = null;
		return result;
	}

	private String buildKey(String url) {
		return url + (autoSize ? ";" + getWidth() + "x" + getHeight() : "");
	}

	public void setImage(String uri) {
		setImage(uri, true);
	}

	public void setImage(String uri, boolean refresh) {
		setImage(uri, null, refresh);
	}

	public void setImage(final String uri, final OnCallListener listener) {
		setImage(uri, listener, true);
	}

	public void setImage(final String uri, final OnCallListener listener, boolean refresh) {
		setImage(!TextUtils.isEmpty(uri) ? new HttpImageRequest(uri) : null, listener, refresh);
	}

	public void setImage(int resId) {
		setImage(resId, null);
	}

	public void setImage(final int resId, final OnCallListener listener) {
		setImage(resId > 0 ? new HttpImageRequest(getContext(), resId) : null, listener);
	}

	public void setImage(HttpImageRequest request) {
		setImage(request, null);
	}

	public void setImage(HttpImageRequest request, final OnCallListener listener) {
		setImage(request, listener, true);
	}

	public void setImage(HttpImageRequest request, final OnCallListener listener, boolean refresh) {
		this.request = request;
		this.loadListener = listener;
		if (refresh) {
			ivDefault.setVisibility(VISIBLE);
			ivMain.setVisibility(INVISIBLE);
			ivMain.setImageDrawable(null);
		}
		if (request == null) {
			cancelCurrentTask();
			return;
		}
		if (!autoSize || getWidth() > 0 && getHeight() > 0) {
			startTask();
		} else {
			post(new Runnable() {
				@Override
				public void run() {
					startTask();
				}
			});
		}
	}

	private boolean fromCache(String image) {
		cacheKey = buildKey(image);
		Bitmap bitmap = CacheManager.getBitmapCache().get(cacheKey);
		if ((cacheMode & CACHE_MEMORY) > 0 && bitmap != null) {
			cancelCurrentTask();
			isAlreadyModify = true;
			OnCallListener listener = loadListener != null ? loadListener : defaultCallListener;
			listener.onStart(null);
			listener.onSuccess(null, ApiResult.fromObject(bitmap));
			return true;
		}
		isAlreadyModify = false;
		return false;
	}

	private void modifyImage(boolean animate) {
		ivMain.setDrawingCacheEnabled(true);
		Bitmap newBmp = getModifyImage(ivMain.getDrawingCache(true));
		ivMain.setDrawingCacheEnabled(false);
		if (newBmp != null)
			setImageBitmap(newBmp, animate);
		isAlreadyModify = false;
	}

	private Bitmap getModifyImage(Bitmap bitmap) {
		try {
			return mask != null ? getMaskedBitmap(bitmap, mask) : getRoundedCornerBitmap(bitmap, cornerRadius, borderWidth, borderColor);
		} catch (Throwable t) {
			t.printStackTrace();
			return null;
		}
	}

	public void showProgress() {
		setImageDrawableDefault(new ProgressDrawable(this));
	}

	private static Bitmap getRoundedCornerBitmap(Bitmap bitmap, float cornerRadius, float borderWidth, int color) {
		if (bitmap == null)
			return null;

		Bitmap output = Bitmap.createBitmap(bitmap.getWidth(), bitmap.getHeight(), Bitmap.Config.ARGB_8888);
		Canvas canvas = new Canvas(output);
		final Paint paint = new Paint();
		paint.setAntiAlias(true);

		final Rect rect = new Rect(0, 0, bitmap.getWidth(), bitmap.getHeight());
		canvas.drawRoundRect(new RectF(rect), cornerRadius, cornerRadius, paint);

		paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.SRC_IN));

		canvas.drawBitmap(bitmap, rect, rect, paint);
		if (borderWidth > 0)
			addRoundedBorderToCanvas(canvas, rect, cornerRadius, borderWidth, color);
		return output;
	}

	private static void addRoundedBorderToCanvas(Canvas canvas, final Rect rect, float cornerRadius, float borderWidth, int color) {
		float offset = borderWidth / 3;
		RectF rectf = new RectF(rect.left + offset, rect.top + offset, rect.right - offset, rect.bottom - offset);
		final Paint paint = new Paint();
		paint.setAntiAlias(true);
		paint.setColor(color);
		paint.setStrokeWidth(borderWidth);
		paint.setStyle(Paint.Style.STROKE);
		canvas.drawRoundRect(rectf, cornerRadius, cornerRadius, paint);
	}

	private static Bitmap getMaskedBitmap(Bitmap bitmap, Drawable mask) {
		if (bitmap == null)
			return null;

		Bitmap output = Bitmap.createBitmap(bitmap.getWidth(), bitmap.getHeight(), Bitmap.Config.ARGB_8888);
		Canvas canvas = new Canvas(output);
		final Paint paint = new Paint();
		paint.setAntiAlias(true);
		final Rect rect = new Rect(0, 0, bitmap.getWidth(), bitmap.getHeight());
		canvas.drawBitmap(bitmap, rect, rect, paint);
		paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.MULTIPLY));

		if (mask != null)
			canvas.drawBitmap(drawableToBitmap(mask, bitmap.getWidth(), bitmap.getHeight()), rect, rect, paint);
		return output;
	}

	private static Bitmap drawableToBitmap(Drawable drawable, int width, int height) {
		Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
		Canvas canvas = new Canvas(bitmap);
		drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
		drawable.draw(canvas);
		return bitmap;
	}
}