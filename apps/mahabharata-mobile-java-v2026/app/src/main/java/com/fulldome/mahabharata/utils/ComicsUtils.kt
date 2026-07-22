package com.fulldome.mahabharata.utils

import android.app.Activity
import android.content.Context
import android.text.TextUtils
import android.view.MotionEvent
import android.view.ViewGroup
import androidx.annotation.StringRes
import com.fulldome.mahabharata.BuildConfig
import com.fulldome.mahabharata.R
import com.fulldome.mahabharata.controls.PieceView
import com.fulldome.mahabharata.controls.TileImageView
import com.fulldome.mahabharata.model.Episode
import com.fulldome.mahabharata.model.Settings
import com.fulldome.mahabharata.model.visual.Layer
import com.google.android.material.snackbar.Snackbar
import com.ironwaterstudio.dialogs.AlertFragment
import com.ironwaterstudio.utils.Utils
import java.text.SimpleDateFormat
import java.util.*

object ComicsUtils {
    @JvmField
    val APP_DATE_FORMAT = SimpleDateFormat("dd.MM.yy", Locale.getDefault())


    init {
        APP_DATE_FORMAT.timeZone = Utils.UTC_TIMEZONE
    }


    fun Context.getEpisodeStatusText(episode: Episode): String = when {
        !episode.isAvailable -> {
            if (episode.price.isNullOrBlank()) getString(R.string.status_request)
            else episode.price!!
        }
        episode.isDownloaded -> getString(R.string.read)
        episode.downloadInfo != null -> ""
        episode.isFree -> getString(R.string.free)
        Settings.getInstance().isSubscribed -> getString(R.string.available)
        else -> getString(R.string.paid)
    }


    fun getImage(image: String?, size: Int): String? {
        var image = image
        if (!image.isNullOrBlank()) {
            image = if (size > 0) image.replace("*", size.toString()) else image.replace("*", "")
        }
        return getImage(image)
    }

    @JvmStatic
    fun getImage(image: String?): String? {
        return if (!TextUtils.isEmpty(image)) BuildConfig.HOST + image else null
    }


    fun showMessage(activity: Activity, @StringRes messageResId: Int) {
        showMessage(activity, activity.resources.getString(messageResId))
    }

    fun showMessage(activity: Activity, message: String?) {
        Snackbar.make(activity.findViewById(android.R.id.content), message!!, Snackbar.LENGTH_LONG)
            .setAction(R.string.open) { AlertFragment.create().setMessage(message).show(activity) }
            .show()
    }


    @JvmStatic
    fun checkHit(parent: ViewGroup, e: MotionEvent, listener: OnHitToLayerListener) {
        for (i in parent.childCount - 1 downTo 0) {
            val pieceView = parent.getChildAt(i) as? PieceView ?: continue
            val localX = e.x - pieceView.x
            val localY = e.y - pieceView.y
            for (j in pieceView.childCount - 1 downTo 0) {
                val imageView = pieceView.getChildAt(j)
                if (imageView.tag !is Layer || imageView !is TileImageView) {
                    continue
                }
                val layer = imageView.getTag() as Layer
                if (TextUtils.isEmpty(layer.popup)) {
                    continue
                }
                val point = floatArrayOf(localX, localY)
                layer.inverse.mapPoints(point)
                val hit = imageView.isHit(point)
                if (hit) {
                    listener.onHit(pieceView, imageView, layer)
                    return
                }
            }
        }
    }

    interface OnHitToLayerListener {
        fun onHit(pieceView: PieceView?, imageView: TileImageView?, layer: Layer?)
    }
}