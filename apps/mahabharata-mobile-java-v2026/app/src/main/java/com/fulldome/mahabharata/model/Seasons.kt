package com.fulldome.mahabharata.model

import android.app.DownloadManager
import android.content.Context
import android.text.TextUtils
import androidx.annotation.MainThread
import com.ironwaterstudio.server.serializers.JsonSerializer
import com.ironwaterstudio.server.serializers.Serializer
import com.ironwaterstudio.utils.FileUtils
import java.io.File

// Seasons.FILE_NAME
class Seasons : ArrayList<Season>() {
    @MainThread
    fun update(context: Context, data: Seasons) {
        for (season in this) {
            val dataSeason = data.getSeason(season.id)
            if (dataSeason == null) {
                season.delete(context)
                continue
            }
            for (episode in season.episodes) {
                val dataEpisode = dataSeason.getEpisode(episode.id)
                if (dataEpisode == null) episode.delete(context) else episode.copyStateTo(dataEpisode)
            }
        }
        clear()
        addAll(data)
        save(context)
    }

    operator fun contains(id: Int): Boolean {
        return getSeason(id) != null
    }

    fun findSeasonByEpisodeId(episodeId: Int): Season? = find { it.getEpisode(episodeId) != null }

    fun getSeason(id: Int): Season? = find { it.id == id }

    fun getSeason(sku: String?): Season? = find { TextUtils.equals(it.product, sku) }

    fun getEpisode(id: Int): Episode? {
        for (season in this) {
            val episode = season.getEpisode(id)
            if (episode != null) return episode
        }
        return null
    }

    fun getNextEpisode(id: Int): Episode? {
        for (season in this) {
            for (episode in season.episodes) {
                if (episode.id == id) return episode
            }
        }
        return null
    }

    fun getEpisode(downloadId: Long): Episode? {
        for (season in this) {
            for (episode in season.episodes) {
                val download = episode.downloadInfo
                if (download != null && download.id == downloadId) return episode
            }
        }
        return null
    }

    fun getEpisode(product: String): Episode? = getAllEpisodes().find { product == it.product }

    fun getAllEpisodes(): List<Episode> = flatMap { it.episodes }

    fun getLastEpisodes(): List<Episode> = flatMap { it.episodes }.sortedByDescending { it.date }


    fun productsForPurchase(): ArrayList<String> {
        val products = ArrayList<String>()
        for (season in this) {
            if (!season.isPurchased && !TextUtils.isEmpty(season.product)) products.add(season.product)
            for (episode in season.episodes) {
                if (!episode.isFree && !episode.isPurchased) products.add(episode.product!!)
            }
        }
        return products
    }

    fun processPurchase(productId: String) {
        val episode = getEpisode(productId)
        val season = getSeason(productId)
        if (episode != null) episode.isPurchased = true else if (season != null) season.isPurchased = true
    }


    fun downloadIds(): LongArray {
        val ids = ArrayList<Long>()
        for (season in this) {
            for (episode in season.episodes) {
                if (episode.downloadInfo != null) ids.add(episode.downloadInfo!!.id)
            }
        }
        return ids.toLongArray()
    }

    fun queryDownloads(context: Context): Boolean {
        val downloadIds = downloadIds()
        if (downloadIds.size == 0) return false
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val c = manager.query(DownloadManager.Query().setFilterById(*downloadIds)) ?: return false
        val colId = c.getColumnIndex(DownloadManager.COLUMN_ID)
        val colStatus = c.getColumnIndex(DownloadManager.COLUMN_STATUS)
        val colDownloadedBytes = c.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)
        val colTotalBytes = c.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)
        while (c.moveToNext()) {
            val id = c.getLong(colId)
            val episode = getEpisode(id) ?: continue
            val status = c.getInt(colStatus)
            if (status == DownloadManager.STATUS_SUCCESSFUL && !episode.completeDownload(context) || status == DownloadManager.STATUS_FAILED) {
                episode.isDownloaded = false
            } else if (status == DownloadManager.STATUS_SUCCESSFUL) {
                episode.isDownloaded = true
            } else {
                episode.downloadInfo!!.apply {
                    downloadedBytes = c.getLong(colDownloadedBytes)
                    totalBytes = c.getLong(colTotalBytes)
                }
            }
        }
        c.close()
        return true
    }

    fun save(context: Context) {
        val file = File(context.getExternalFilesDir(null), FILE_NAME)
        FileUtils.writeFile(
            file,
            Serializer.get(JsonSerializer::class.java).write(this)
        )
    }


    companion object {
        private const val FILE_NAME = "seasons.json"

        @JvmStatic
        var instance: Seasons? = null
            private set

        @JvmStatic
        fun init(context: Context) {
            if (instance == null) instance = load(context)
        }

        // Here fetch seasons
        private fun load(context: Context): Seasons {
            val file = File(context.getExternalFilesDir(null), FILE_NAME)
            if (!file.exists()) return Seasons()
            val seasons = Serializer.get(JsonSerializer::class.java).read(FileUtils.readFile(file), Seasons::class.java)
            return seasons ?: Seasons()
        }
    }
}