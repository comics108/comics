package com.fulldome.mahabharata.controls;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Point;
import android.graphics.Rect;
import android.graphics.RectF;
import android.view.View;

import com.fulldome.mahabharata.model.ComicsDescriptor;
import com.fulldome.mahabharata.utils.ImageManager;
import com.ironwaterstudio.server.CacheManager;
import com.ironwaterstudio.server.data.ApiResult;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;

public class TileImageView extends View implements ZoomFrameLayout.ZoomableView {
	private static final float[] ZOOM_LEVELS = {1.0f, 0.5f, 0.25f, 0.125f};
	private static final float NO_TILES = -1;
	private static final int TILE_SIZE = 512;

	private final ComicsDescriptor descriptor;
	private final int sampleSize;
	private final String template;
	private final String placeholder;

	private final Rect contentRect = new Rect();
	private float scale = 1f;
	private final HashMap<Float, Set<Tile>> tileLevels = new HashMap<>();
	private final Rect visibleRect = new Rect();
	private final Rect preloadBitmapRect = new Rect();
	private final Paint paint = new Paint();
	private final boolean tileMode;
	private final Point preloadOffset = new Point();
	private final boolean zoomEnabled;

	private ImageManager.ImageCallListener loadedListener = new ImageManager.ImageCallListener() {
		@Override
		protected void onSuccess(ApiResult result) {
			super.onSuccess(result);
			invalidate();
		}
	};

	public TileImageView(Context context, ComicsDescriptor descriptor, int sampleSize, String filePath, boolean zoomEnabled) {
		super(context);
		this.zoomEnabled = zoomEnabled;
		this.descriptor = descriptor;
		this.template = filePath;
		tileMode = filePath.contains("{0}");
		this.sampleSize = sampleSize;
		placeholder = tileMode ? filePath.replace("{0}", "ph").replace("{1}", "0").replace("{2}", "0") : null;
		paint.setAntiAlias(true);
	}

	public void setPreloadOffset(Point preloadOffset) {
		this.preloadOffset.set(preloadOffset.x, preloadOffset.y);
	}

	@Override
	protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
		super.onLayout(changed, left, top, right, bottom);
		setTotalSize(getWidth(), getHeight());
	}

	@Override
	public void onUpdate(float scale, int scrollX, int scrollY, int extendedX, int extendedY) {
		this.scale = scale;
		loadBitmapIfNeeded();
	}

	@Override
	protected void onDraw(Canvas canvas) {
		super.onDraw(canvas);
		getLocalVisibleRect(visibleRect);
		if (contentRect.width() <= 0 || contentRect.height() <= 0 || visibleRect.isEmpty())
			return;
		Set<Tile> tileLevel = tileLevels.get(selectZoom());
		if (tileLevel == null)
			return;

		if (needDrawPlaceholder(tileLevel)) {
			Bitmap holderBitmap = CacheManager.getBitmapCache().get(ImageManager.buildKey(descriptor, placeholder));
			if (holderBitmap != null)
				canvas.drawBitmap(holderBitmap, null, contentRect, paint);
		}

		for (Tile tile : tileLevel) {
			if (!tile.isVisible())
				continue;
			Bitmap bitmap = CacheManager.getBitmapCache().get(ImageManager.buildKey(descriptor, tile.getFileName()));
			if (bitmap != null)
				canvas.drawBitmap(bitmap, null, tile.getRect(), paint);
		}
	}

	private boolean needDrawPlaceholder(Set<Tile> tileLevel) {
		if (!tileMode)
			return false;
		for (Tile tile : tileLevel) {
			if (tile.isVisible() && CacheManager.getBitmapCache().get(ImageManager.buildKey(descriptor, tile.getFileName())) == null)
				return true;
		}
		return false;
	}

	public boolean isHit(float[] point) {
		if (point[0] < 0 || point[1] < 0 || point[0] > getWidth() || point[1] > getHeight())
			return false;
		float zoomLevel = selectZoom();
		Set<Tile> tileLevel = tileLevels.get(zoomLevel);
		if (tileLevel == null)
			return false;
		Tile hitTile = null;
		for (Tile tile : tileLevel) {
			if (point[0] >= tile.getRect().left && point[1] >= tile.getRect().top && point[0] <= tile.getRect().right && point[1] <= tile.getRect().bottom) {
				hitTile = tile;
				break;
			}
		}
		if (hitTile == null)
			return false;
		Bitmap bitmap = CacheManager.getBitmapCache().get(ImageManager.buildKey(descriptor, hitTile.getFileName()));
		if (bitmap == null)
			return false;
		int localX = Math.min(bitmap.getWidth() - 1, (int) (Math.max(0, (int) point[0] - hitTile.getRect().left) * zoomLevel));
		int localY = Math.min(bitmap.getHeight() - 1, (int) (Math.max(0, (int) point[1] - hitTile.getRect().top) * zoomLevel));
		return Color.alpha(bitmap.getPixel(localX, localY)) > 0;
	}

	public void loadBitmapIfNeeded() {
		getPreloadBitmapRect(preloadBitmapRect);
		Set<Tile> tileLevel = tileLevels.get(selectZoom());
		if (tileLevel == null)
			return;
		if (tileMode) {
			if (!preloadBitmapRect.isEmpty())
				ImageManager.getBitmap(descriptor, placeholder, sampleSize, loadedListener);
			else
				ImageManager.cancel(descriptor, placeholder);
		}

		for (Tile tile : tileLevel) {
			if (!preloadBitmapRect.isEmpty() && tile.isPreloadBitmap())
				ImageManager.getBitmap(descriptor, tile.getFileName(), sampleSize, loadedListener);
			else
				ImageManager.cancel(descriptor, tile.getFileName());
		}
	}

	private void getPreloadBitmapRect(Rect rect) {
		if (rect == null)
			return;
		rect.set(0, 0, getRight() - getLeft(), getBottom() - getTop());
		if (getParent() != null)
			getParent().getChildVisibleRect(this, rect, preloadOffset);
	}

	private void setTotalSize(int width, int height) {
		if (width <= 0 || height <= 0 || contentRect.width() == width && contentRect.height() == height)
			return;
		contentRect.set(0, 0, width, height);
		tileLevels.clear();
		if (!tileMode) {
			Set<Tile> tiles = new HashSet<>();
			tiles.add(new Tile(contentRect));
			tileLevels.put(NO_TILES, tiles);
		} else if (zoomEnabled) {
			for (float level : ZOOM_LEVELS)
				tileLevels.put(level, buildTiles(level));
		} else {
			tileLevels.put(ZOOM_LEVELS[0], buildTiles(ZOOM_LEVELS[0]));
		}
	}

	private Set<Tile> buildTiles(float zoomLevel) {
		Set<Tile> tiles = new HashSet<>();
		int column = 0;
		int realWidth = (int) (contentRect.width() * zoomLevel);
		int realHeight = (int) (contentRect.height() * zoomLevel);
		for (int i = 0; i < realWidth; i += TILE_SIZE) {
			int row = 0;
			for (int j = 0; j < realHeight; j += TILE_SIZE) {
				tiles.add(new Tile(column, row, zoomLevel));
				row++;
			}
			column++;
		}
		return tiles;
	}

	private float selectZoom() {
		if (!tileMode)
			return NO_TILES;
		if (!zoomEnabled)
			return ZOOM_LEVELS[0];
		for (float level : ZOOM_LEVELS) {
			if (scale >= Math.min(level, 0.8f))
				return level;
		}
		return ZOOM_LEVELS[ZOOM_LEVELS.length - 1];
	}

	private class Tile {
		private final Rect rect = new Rect();
		private final String fileName;

		private Tile(int column, int row, float zoomLevel) {
			RectF rect = new RectF(0, 0, computeSize(contentRect.width(), zoomLevel, column), computeSize(contentRect.height(), zoomLevel, row));
			rect.offset(column * TILE_SIZE / zoomLevel, row * TILE_SIZE / zoomLevel);
			rect.round(this.rect);
			fileName = template.replace("{0}", String.valueOf((int) (zoomLevel * 1000))).replace("{1}", String.valueOf(column)).replace("{2}", String.valueOf(row));
		}

		private Tile(Rect rect) {
			this.rect.set(rect);
			fileName = template;
		}

		private boolean isVisible() {
			return Rect.intersects(visibleRect, rect);
		}

		private boolean isPreloadBitmap() {
			return Rect.intersects(preloadBitmapRect, rect);
		}

		private Rect getRect() {
			return rect;
		}

		private String getFileName() {
			return fileName;
		}

		private float computeSize(int contentSize, float zoomLevel, int index) {
			return Math.min(TILE_SIZE, contentSize * zoomLevel - TILE_SIZE * index) / zoomLevel;
		}
	}
}
