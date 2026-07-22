package com.fulldome.mahabharata.adapters.holders

import android.view.ViewGroup
import android.widget.TextView
import com.fulldome.mahabharata.R
import com.fulldome.mahabharata.adapters.EpisodeInteractionListener
import com.fulldome.mahabharata.model.Episode
import com.fulldome.mahabharata.utils.ImageCallListener
import com.fulldome.mahabharata.view.EpisodeReadButton
import com.ironwaterstudio.adapters.BaseHolder
import com.ironwaterstudio.controls.ImageViewEx

class LastEpisodeHolder(
    private val openEpisode: EpisodeInteractionListener,
    private val downloadEpisode: EpisodeInteractionListener,
    parent: ViewGroup
) : BaseHolder<Episode>(R.layout.item_last_episode, parent) {
    private val title: TextView
    private val poster: ImageViewEx
    private val readButton: EpisodeReadButton

    init {
        title = itemView.findViewById(R.id.tv_name)
        poster = itemView.findViewById(R.id.iv_poster)
        readButton = itemView.findViewById(R.id.erb_read)
    }


    override fun update(item: Episode) {
        super.update(item)
        title.text = item.name
        poster.setImage(item.image, ImageCallListener(poster))

        readButton.updateState(item)
        if (item.isDownloaded) {
            readButton.setOnClickListener { openEpisode(item) }
        } else if (!item.isDownloaded) {
            readButton.setOnClickListener { downloadEpisode(item) }
        }
    }
}