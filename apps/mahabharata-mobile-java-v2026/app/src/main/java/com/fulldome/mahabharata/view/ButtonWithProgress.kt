package com.fulldome.mahabharata.view

import android.animation.AnimatorListenerAdapter
import android.animation.ObjectAnimator
import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.animation.LinearInterpolator
import android.widget.FrameLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.core.view.isGone
import androidx.core.view.isVisible
import com.fulldome.mahabharata.R

private const val PROGRESS_PROPERTY = "progress"

abstract class ButtonWithProgress @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet?,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    init {
        LayoutInflater.from(context).inflate(R.layout.view_button_with_progress, this, true)
    }

    protected val progressBar: ProgressBar = findViewById<ProgressBar>(R.id.progress_bar).apply {
        progressDrawable = ContextCompat.getDrawable(getContext(), R.drawable.yellow_rect)!!.mutate()
    }
    protected val stateText: TextView = findViewById(R.id.tv_state)

    protected var progressAnimator: ObjectAnimator? = null

    protected abstract val progressAnimatorListener: AnimatorListenerAdapter


    fun updateState(isDownloading: Boolean, percent: Int?, status: String, isReady: Boolean, hasContent: Boolean) {
        if (isCompleteAnimationNeeded() || isDownloading) {
            val nonNullPercent = percent ?: 100
            animateProgress(nonNullPercent)
            progressBar.isVisible = hasContent

            stateText.apply {
                setText("${nonNullPercent}%")
                setTextColor(ContextCompat.getColor(context, R.color.white))
                textSize = 12f
                background = null
                alpha = 1f
            }
        } else {
            progressBar.progress = 0
            progressBar.isGone = !hasContent || isReady

            stateText.apply {
                setText(status)
                setTextColor(ContextCompat.getColor(context, if (isReady) R.color.maroon_dark else R.color.yellow))
                setTextSize(10f)
                setBackground(
                    if (isReady) ContextCompat.getDrawable(context, R.drawable.solid_yellow_rect)
                    else null
                )
                setAlpha(if (isReady) 0.8f else 1f)
            }
        }
    }

    private fun animateProgress(percent: Int) {
        progressAnimator?.cancel()

        progressAnimator = ObjectAnimator.ofInt(progressBar, PROGRESS_PROPERTY, percent).apply {
            setInterpolator(LinearInterpolator())
            setDuration(200)
            addListener(progressAnimatorListener)
            start()
        }
    }

    fun isCompleteAnimationNeeded(): Boolean = progressBar.progress in 1..99
}