package com.fulldome.mahabharata.fragments;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.cardview.widget.CardView;
import androidx.fragment.app.Fragment;

import com.fulldome.mahabharata.R;
import com.fulldome.mahabharata.model.Episode;
import com.fulldome.mahabharata.model.Seasons;
import com.fulldome.mahabharata.screens.EpisodesActivity;
import com.fulldome.mahabharata.screens.UiConstants;
import com.fulldome.mahabharata.utils.ComicsUtils;
import com.fulldome.mahabharata.utils.ImageCallListener;
import com.fulldome.mahabharata.utils.YoutubeLinksContainer;
import com.fulldome.mahabharata.view.EpisodeReadButton;
import com.ironwaterstudio.controls.ImageViewEx;
import com.ironwaterstudio.utils.Utils;

public class EpisodeFragment extends Fragment {
    private CardView cvPoster;
    private ImageViewEx ivPoster;
    private TextView tvChapter;
    private TextView tvDate;
    private View btnShare;
    private TextView tvName;
    private TextView tvSoon;
    private View btnUpdate;
    private View btnDelete;
    private Button btnWatch;

    private EpisodeReadButton episodeReadButton;

    private YoutubeLinksContainer youtubeLinksContainer = new YoutubeLinksContainer();

    private final View.OnClickListener clickListener = view -> {
        if (!(view.getTag() instanceof EpisodesActivity.Action)) {
            return;
        }

        EpisodesActivity.Action action = (EpisodesActivity.Action) view.getTag();
        Boolean hasComics = getEpisode().hasComics();
        Boolean shareAction = action == EpisodesActivity.Action.SHARE;
        if ((hasComics || shareAction)) {
            EpisodesActivity.emitComicsEvent(requireContext(), getEpisode().getId(), action);
        }
    };

    private final View.OnClickListener watchListener = view -> {
        Integer episodeId = getEpisode().getId();
        if (!youtubeLinksContainer.exists(episodeId)) { return; }
        String link = youtubeLinksContainer.link(episodeId);
        Uri uri = Uri.parse(link);
        getContext().startActivity(
                new Intent(
                        Intent.ACTION_VIEW,
                        uri
                )
        );
    };

    @Nullable
    @Override
    public View onCreateView(final LayoutInflater inflater, @Nullable final ViewGroup container,
                             @Nullable final Bundle savedInstanceState) {
        final View v = inflater.inflate(R.layout.fragment_episode, container, false);
        cvPoster = v.findViewById(R.id.cv_poster);
        ivPoster = v.findViewById(R.id.iv_poster);
        tvChapter = v.findViewById(R.id.tv_chapter);
        tvDate = v.findViewById(R.id.tv_date);
        btnShare = v.findViewById(R.id.btn_share);
        tvName = v.findViewById(R.id.tv_name);
        episodeReadButton = v.findViewById(R.id.erb_read);
        tvSoon = v.findViewById(R.id.tv_soon);
        btnUpdate = v.findViewById(R.id.btn_update);
        btnDelete = v.findViewById(R.id.btn_delete);
        btnWatch = v.findViewById(R.id.btn_watch_on_youtube);
        return v;
    }

    @Override
    public void onActivityCreated(@Nullable final Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        initPosterSize();
        cvPoster.setOnClickListener(clickListener);
        cvPoster.setTag(EpisodesActivity.Action.OPEN);
        btnShare.setOnClickListener(clickListener);
        btnShare.setTag(EpisodesActivity.Action.SHARE);
        btnUpdate.setOnClickListener(clickListener);
        btnUpdate.setTag(EpisodesActivity.Action.UPDATE);
        btnDelete.setOnClickListener(clickListener);
        btnDelete.setTag(EpisodesActivity.Action.DELETE);
        btnWatch.setOnClickListener(watchListener);
        updateViews();
    }

    @Override
    public void onResume() {
        super.onResume();
        updateState();
    }

    private void initPosterSize() {
        final ViewGroup.LayoutParams params = cvPoster.getLayoutParams();
        params.width = getPosterWidth(getContext());
        params.height = getPosterHeight(getContext());
        cvPoster.requestLayout();
        cvPoster.setRadius(getCardRadius(getContext()));
    }

    public void updateViews() {
        if (ivPoster == null) {
            return;
        }
        final Episode episode = getEpisode();

        ivPoster.setImage(episode.getImage(), new ImageCallListener(ivPoster));
        tvChapter.setText(getString(R.string.episode_template, getEpisode().getOrder()));
        tvName.setText(episode.getName());
        tvDate.setText(episode.getDate() != 0
            ? ComicsUtils.APP_DATE_FORMAT.format(Utils.fromUnixTimeStamp(episode.getDate()))
            : "");
        tvSoon.setVisibility(episode.hasComics() ? View.GONE : View.VISIBLE);
        updateWatchButton(episode);
        updateState();
    }

    private void updateWatchButton(Episode episode) {
        btnWatch.setText(R.string.watch);
        final Boolean isShown = youtubeLinksContainer.exists(episode.getId());
        final Integer visibilityId = isShown ? View.VISIBLE : View.GONE;
        btnWatch.setVisibility(visibilityId);
    }

    public void updateState() {
        final Episode episode = getEpisode();
        if (episode == null || getView() == null || getContext() == null) {
            return;
        }

        if (episodeReadButton.isCompleteAnimationNeeded() || episode.getDownloadInfo() != null) {
            btnUpdate.setVisibility(View.GONE);
            btnDelete.setVisibility(View.GONE);
        } else {
            btnUpdate.setVisibility(episode.isDownloaded() && episode.getVersion() > episode.getLoadedVersion()
                ? View.VISIBLE
                : View.GONE);
            btnDelete.setVisibility(episode.isDownloaded() ? View.VISIBLE : View.GONE);
        }
        episodeReadButton.updateState(episode);
    }

    private Episode getEpisode() {
        return Seasons.getInstance().getEpisode(getArguments().getInt(UiConstants.KEY_EPISODE_ID));
    }

    public int getEpisodeId() {
        return getArguments().getInt(UiConstants.KEY_EPISODE_ID);
    }

    public static EpisodeFragment newInstance(final int episodeId) {
        final Bundle bundle = new Bundle();
        bundle.putInt(UiConstants.KEY_EPISODE_ID, episodeId);
        final EpisodeFragment fragment = new EpisodeFragment();
        fragment.setArguments(bundle);
        return fragment;
    }

    public static int getPosterWidth(final Context context) {
        return (int) (context.getResources().getDisplayMetrics().widthPixels * 0.6f);
    }

    public static int getPosterHeight(final Context context) {
        return (int) (getPosterWidth(context) * 1.458f);
    }

    public static int getCardRadius(final Context context) {
        return getPosterWidth(context) / 59;
    }
}
