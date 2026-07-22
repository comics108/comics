package com.fulldome.mahabharata.fragments

import android.os.Bundle
import android.view.View
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.fulldome.mahabharata.R
import com.fulldome.mahabharata.adapters.LastEpisodesAdapter
import com.fulldome.mahabharata.adapters.holders.LastEpisodeHolder
import com.fulldome.mahabharata.model.Episode
import com.fulldome.mahabharata.model.Seasons
import com.fulldome.mahabharata.screens.ComicsActivity
import com.fulldome.mahabharata.screens.EpisodesActivity
import com.fulldome.mahabharata.utils.AnalyticsEvents
import com.fulldome.mahabharata.utils.Constants
import com.ironwaterstudio.utils.FbUtils
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext

class LastEpisodesFragment : Fragment(R.layout.fragment_last_episodes) {

    private lateinit var episodesAdapter: LastEpisodesAdapter
    private lateinit var episodesRecycler: RecyclerView


    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        episodesRecycler = view.findViewById<RecyclerView>(R.id.rv_episodes).apply {
            layoutManager = LinearLayoutManager(requireContext(), LinearLayoutManager.HORIZONTAL, false)
            adapter = LastEpisodesAdapter(
                { episode -> ComicsActivity.show(activity, episode.id, EpisodesActivity.REQ_COMICS) },
                ::downloadEpisode,
                requireContext(),
                arrayListOf()
            ).also { episodesAdapter = it }
        }
        updateLastEpisodes()
    }

    private fun downloadEpisode(episode: Episode) {
        if (episode.downloadInfo != null) return

        FbUtils.logEvent(AnalyticsEvents.CATEGORY_EPISODE, AnalyticsEvents.ACTION_DOWNLOAD + " " + episode.name)
        episode.download(requireContext())
        Seasons.instance!!.save(requireContext())

        if (!Seasons.instance!!.queryDownloads(requireContext())) return
        startWatchingDownloadProgress(episode)
    }

    private fun startWatchingDownloadProgress(episode: Episode) {
        lifecycleScope.launchWhenResumed {
            withContext(Dispatchers.IO) {
                while (episode.downloadInfo != null) {
                    if (!Seasons.instance!!.queryDownloads(requireContext())) break

                    Seasons.instance!!.save(requireContext())
                    updateDownloadProgress(episode)
                    delay(Constants.QUERY_INTERVAL)
                }

                updateDownloadProgress(episode)
            }
        }
    }

    private suspend fun updateDownloadProgress(episode: Episode) = withContext(Dispatchers.Main) {
        (episodesRecycler.findViewHolderForAdapterPosition(episodesAdapter.indexOf(episode)) as? LastEpisodeHolder)
            ?.update(episode)
    }


    fun updateLastEpisodes() {
        val lastEpisodes = Seasons.instance!!.getLastEpisodes()
        episodesAdapter.items = lastEpisodes
        lastEpisodes.forEach(::startWatchingDownloadProgress)
    }
}