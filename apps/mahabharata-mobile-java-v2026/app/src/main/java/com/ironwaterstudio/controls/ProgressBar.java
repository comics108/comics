package com.ironwaterstudio.controls;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RadialGradient;
import android.graphics.Shader;
import android.graphics.drawable.ShapeDrawable;
import android.graphics.drawable.shapes.OvalShape;
import androidx.core.view.ViewCompat;
import androidx.appcompat.widget.AppCompatImageView;
import android.util.AttributeSet;

import com.ironwaterstudio.utils.UiHelper;

public class ProgressBar extends AppCompatImageView {
	private static final int CIRCLE_BG_LIGHT = 0xFFFAFAFA;
	private static final int SHADOW_RADIUS = 3;
	private static final int CIRCLE_DIAMETER = 40;
	private static final int KEY_SHADOW_COLOR = 0x1E000000;

	private ProgressDrawable progress;

	private final int shadowRadius;
	private final int circleDiameter;
	private int backgroundColor = CIRCLE_BG_LIGHT;

	public ProgressBar(Context context) {
		this(context, null);
	}

	public ProgressBar(Context context, AttributeSet attrs) {
		super(context, attrs);
		setScaleType(ScaleType.CENTER);
		shadowRadius = UiHelper.dpToPx(getContext(), SHADOW_RADIUS);
		circleDiameter = UiHelper.dpToPx(getContext(), CIRCLE_DIAMETER);

		progress = new ProgressDrawable(this).setSize(CIRCLE_DIAMETER * 0.65f).setStrokeWidth(SHADOW_RADIUS * 0.9f);
		setBackgroundColor(backgroundColor);
	}

	public ProgressDrawable getDrawable() {
		return progress;
	}

	public void setBackgroundColor(int backgroundColor) {
		this.backgroundColor = backgroundColor;
		ShapeDrawable circle = new ShapeDrawable(new OvalShadow(shadowRadius, circleDiameter));
		circle.setBounds(0, 0, circleDiameter + shadowRadius, circleDiameter + shadowRadius);
		circle.getPaint().setShadowLayer(shadowRadius, 0, 0, KEY_SHADOW_COLOR);
		circle.getPaint().setColor(backgroundColor);
		setPadding(shadowRadius, shadowRadius, shadowRadius, shadowRadius);
		ViewCompat.setBackground(this, circle);
		setImageDrawable(progress);
	}

	@Override
	protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
		super.onMeasure(MeasureSpec.makeMeasureSpec(circleDiameter + shadowRadius * 2, MeasureSpec.EXACTLY),
				MeasureSpec.makeMeasureSpec(circleDiameter + shadowRadius * 2, MeasureSpec.EXACTLY));
	}

	private class OvalShadow extends OvalShape {
		private static final int COLOR_START = 0x3D000000;

		private RadialGradient radialGradient;
		private Paint shadowPaint;
		private int circleDiameter;
		private int shadowRadius;

		private OvalShadow(int shadowRadius, int circleDiameter) {
			super();
			shadowPaint = new Paint();
			this.shadowRadius = shadowRadius;
			this.circleDiameter = circleDiameter;
			radialGradient = new RadialGradient(this.circleDiameter / 2 + shadowRadius, this.circleDiameter / 2 + shadowRadius,
					this.circleDiameter / 2 + this.shadowRadius, new int[]{COLOR_START, COLOR_START, Color.TRANSPARENT}, null, Shader.TileMode.CLAMP);
			shadowPaint.setShader(radialGradient);
		}

		@Override
		public void draw(Canvas canvas, Paint paint) {
			final int viewWidth = ProgressBar.this.getWidth();
			final int viewHeight = ProgressBar.this.getHeight();
			canvas.drawCircle(viewWidth / 2, viewHeight / 2, circleDiameter / 2 + shadowRadius, shadowPaint);
			canvas.drawCircle(viewWidth / 2, viewHeight / 2, circleDiameter / 2, paint);
		}
	}
}
