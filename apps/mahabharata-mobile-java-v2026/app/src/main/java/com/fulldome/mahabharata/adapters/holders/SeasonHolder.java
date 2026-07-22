package com.fulldome.mahabharata.adapters.holders;

import static com.fulldome.mahabharata.screens.UiConstants.KEY_SEASON_ID;

import android.content.Intent;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.util.TypedValue;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

import androidx.core.content.ContextCompat;

import com.fulldome.mahabharata.BuildConfig;
import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.model.Episode;
import com.fulldome.mahabharata.model.Season;
import com.fulldome.mahabharata.screens.MenuActivity;
import com.fulldome.mahabharata.utils.ImageCallListener;
import com.ironwaterstudio.adapters.BaseHolder;
import com.ironwaterstudio.controls.ImageViewEx;

import java.util.ArrayList;

public class SeasonHolder extends BaseHolder<Season> {
	private View btnSeason;
	private ImageViewEx ivPoster;
	private TextView tvName;
	private TextView tvCount;
	private Button ctaButton;

	private Uri getEarlyAccessUrl = Uri.parse("https://www.patreon.com/vedaart");
	private Uri donateToSupport = Uri.parse("https://buy.stripe.com/dR67wd9TIeZN9l69AA");

	private View.OnClickListener itemClickListener = new View.OnClickListener() {
		@Override
		public void onClick(View v) {
			showSeason();
		}
	};

	private View.OnClickListener ctaClickListener = new View.OnClickListener() {
		@Override
		public void onClick(View view) {
			handleCtaButtonClick();
		}
	};

	public SeasonHolder(ViewGroup parent) {
        super(R.layout.item_season, parent);
        btnSeason = itemView.findViewById(R.id.btn_season);
        btnSeason.setOnClickListener(itemClickListener);
        ivPoster = itemView.findViewById(R.id.iv_poster);
        tvName = itemView.findViewById(R.id.tv_name);
        tvCount = itemView.findViewById(R.id.tv_count);
        ctaButton = itemView.findViewById(R.id.b_read);
        ctaButton.setOnClickListener(ctaClickListener);
    }

	@Override
	public void update(Season item) {
		super.update(item);
		ivPoster.setImage(item.getImage(), new ImageCallListener(ivPoster));
		tvName.setText(item.getName());
		tvCount.setText(getContext().getResources().getQuantityString(R.plurals.episodes, item.getEpisodes().size(), item.getEpisodes().size()));
		configureCtaButton(item);
		configureCountTextView(item);
	}

	private void configureCtaButton(Season season) {
		switch (season.getId()) {
			case 2:
				ctaButton.setText(R.string.get_early_access);
				ctaButton.setTextColor(
						ContextCompat.getColor(
								ctaButton.getContext(),
								R.color.white
						)
				);
				ctaButton.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10);
				((GradientDrawable)ctaButton.getBackground())
						.setColor(
								ContextCompat.getColor(
										ctaButton.getContext(),
										R.color.dark_green
								)
						);
				break;
			case 3:
				ctaButton.setText(R.string.donate_to_support);
				ctaButton.setTextColor(
						ContextCompat.getColor(
								ctaButton.getContext(),
								R.color.white
						)
				);
				ctaButton.setTextSize(TypedValue.COMPLEX_UNIT_SP, 10);
				((GradientDrawable)ctaButton.getBackground())
						.setColor(
								ContextCompat.getColor(
										ctaButton.getContext(),
										R.color.dark_green
								)
						);
				break;
			default:
				ctaButton.setText(R.string.read_now);
				break;
		}
	}

	private void configureCountTextView(Season season) {
		switch (season.getId()) {
			case 2:
			case 3:
				tvCount.setText(R.string.coming_soon);
				break;
			default:
				tvCount.setText(
						getContext().getResources().getQuantityString(
								R.plurals.episodes,
								season.getEpisodes().size(),
								season.getEpisodes().size()
						)
				);
				break;
		}
	}

	private void handleCtaButtonClick() {
        Season season = getModel();
        switch (season.getId()) {
            case 2:
                presentGetEarlyAccessPage();
                break;
            case 3:
                presentDonateToSupportPage();
                break;
            default:
                showSeason();
                break;
		}
	}

	private void presentGetEarlyAccessPage() {
		getContext().startActivity(
				new Intent(
						Intent.ACTION_VIEW,
						getEarlyAccessUrl
				)
		);
	}

	private void presentDonateToSupportPage() {
		getContext().startActivity(
				new Intent(
						Intent.ACTION_VIEW,
						donateToSupport
				)
		);
	}

	private void showSeason() {
        Season season = getModel();
        ArrayList<Episode> episodes = season.getEpisodes();
        if (episodes == null) {
            return;
        }
        if (episodes.isEmpty()) {
            return;
        }
        Intent intent = new Intent(MenuActivity.ACTION_OPEN_SEASON);
        intent.setPackage(BuildConfig.APPLICATION_ID);
        getContext().sendBroadcast(
        		intent
						.putExtra(
								KEY_SEASON_ID,
								getModel().getId()
						)
		);
	}
}