package com.fulldome.mahabharata.view

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.content.Context
import android.util.AttributeSet
import com.fulldome.mahabharata.model.Episode
import com.fulldome.mahabharata.utils.ComicsUtils.getEpisodeStatusText

class EpisodeReadButton @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : ButtonWithProgress(context, attrs, defStyleAttr) {

    private var episode: Episode? = null


    override val progressAnimatorListener: AnimatorListenerAdapter = object : AnimatorListenerAdapter() {
        override fun onAnimationEnd(animation: Animator) {
            super.onAnimationEnd(animation)
            progressAnimator = null
            if (progressBar.progress < 100) return
            progressBar.postDelayed({ updateState() }, 300)
        }
    }


    fun updateState(episode: Episode? = this.episode) {
        if (episode == null) return

        updateState(
            episode.downloadInfo != null,
            episode.downloadInfo?.percent,
            context.getEpisodeStatusText(episode),
            episode.isReadyToRead,
            episode.hasComics()
        )
    }
}