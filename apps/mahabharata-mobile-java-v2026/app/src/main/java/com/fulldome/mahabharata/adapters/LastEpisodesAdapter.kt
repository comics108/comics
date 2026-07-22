package com.fulldome.mahabharata.adapters

import android.content.Context
import android.view.ViewGroup
import com.fulldome.mahabharata.adapters.holders.LastEpisodeHolder
import com.fulldome.mahabharata.model.Episode
import com.ironwaterstudio.adapters.BaseHolder
import com.ironwaterstudio.adapters.RecyclerArrayAdapter

typealias EpisodeInteractionListener = (Episode) -> Unit

class LastEpisodesAdapter(
    private val openEpisode: EpisodeInteractionListener,
    private val downloadEpisode: EpisodeInteractionListener,
    context: Context, items: MutableList<Episode>
) : RecyclerArrayAdapter<Episode>(context, items) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): BaseHolder<*> =
        LastEpisodeHolder(openEpisode, downloadEpisode, parent)

    fun setItems(items: List<Episode>) {
        clear()
        addAll(items)
    }
}