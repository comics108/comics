package com.fulldome.mahabharata.model

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.text.TextUtils
import android.webkit.URLUtil
import com.fulldome.mahabharata.BuildConfig
import com.fulldome.mahabharata.R
import com.fulldome.mahabharata.model.Seasons.Companion.instance
import com.fulldome.mahabharata.utils.ComicsUtils
import com.ironwaterstudio.utils.FileUtils
import java.io.File

class Episode : BaseState {
    val id = 0
    val name: String? = null
    val image: String? = null
        get() = ComicsUtils.getImage(field, 944)
    private val file: String? = null
    val version = 0
    val product: String? = null
    val date: Long = 0
    val order = 0

    private var state = EpisodeState()

    // <-- hack to make all episodes free
    val isFree: Boolean
        get() = TextUtils.isEmpty(product) || true // <-- hack to make all episodes free

    val isAvailable: Boolean
        get() {
            val season = instance!!.findSeasonByEpisodeId(id)
            return isFree || isPurchased || Settings.getInstance().isSubscribed || season != null && season.isPurchased
        }

    val isReadyToRead: Boolean
        get() = isAvailable && isDownloaded

    var isPurchased: Boolean
        get() = state.isPurchased
        set(purchased) {
            state.isPurchased = purchased
        }

    var price: String?
        get() = state.price
        set(price) {
            state.price = price
        }

    var currentScroll: Int
        get() = state.currentScroll
        set(currentScroll) {
            state.currentScroll = currentScroll
        }


    fun getFile(): String {
        return BuildConfig.HOST + file
    }

    fun hasComics(): Boolean {
        return !TextUtils.isEmpty(file)
    }


    override fun getLoadedVersion(): Int {
        return state.loadedVersion
    }

    override fun getDownloadInfo(): DownloadInfo? {
        return state.downloadInfo
    }

    override fun isDownloaded(): Boolean {
        return !TextUtils.isEmpty(state.savedFile)
    }

    override fun setDownloaded(downloaded: Boolean) {
        state.loadedVersion = if (downloaded) version else -1
        state.savedFile = if (downloaded) buildSavedFileName() else null
        state.downloadInfo = null
    }

    override fun getSavedFile(context: Context): File {
        return File(getLocation(context), state.savedFile)
    }

    fun buildTempSavedFileName(): String {
        return buildSavedFileName() + TEMP_EXT
    }

    fun buildSavedFileName(): String {
        return URLUtil.guessFileName(getFile(), null, null)
    }

    fun copyStateTo(episode: Episode) {
        episode.state = state
    }

    fun delete(context: Context) {
        if (isDownloaded) {
            FileUtils.deleteFile(getSavedFile(context))
            state.loadedVersion = -1
            state.downloadInfo = null
            state.savedFile = null
        }
    }

    fun download(context: Context) {
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val uri = Uri.parse(getFile())
        val id = manager.enqueue(
            DownloadManager.Request(uri)
                .setTitle(context.getString(R.string.app_name))
                .setDescription(name)
                .setDestinationInExternalFilesDir(context, null, buildTempSavedFileName())
        )
        state.downloadInfo = DownloadInfo(id)
    }

    fun completeDownload(context: Context): Boolean {
        val root = getLocation(context)
        val tmpFile = File(root, buildTempSavedFileName())
        val file = File(root, buildSavedFileName())
        return (!file.exists() || file.delete()) && tmpFile.exists() && tmpFile.renameTo(file)
    }

    fun getStatusText(context: Context): String {
        if (!isAvailable) return if (price.isNullOrBlank()) context.getString(R.string.status_request) else price!!
        if (isDownloaded) return context.getString(R.string.read)
        return if (downloadInfo != null) "" else context.getString(if (isFree) R.string.free else if (Settings.getInstance().isSubscribed) R.string.available else R.string.paid)
    }

    companion object {
        private const val TEMP_EXT = ".tmp"
        fun getLocation(context: Context): File? {
            return context.getExternalFilesDir(null)
        }
    }
}