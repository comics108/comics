package com.fulldome.mahabharata.model

data class DownloadInfo @JvmOverloads constructor(var id: Long = 0) {
    var downloadedBytes: Long = 0
    var totalBytes: Long = 0
        set(totalBytes) {
            field = if (totalBytes < 0) 0 else totalBytes
        }

    val percent: Int
        get() = if (totalBytes > 0) (downloadedBytes * 100 / totalBytes).toInt() else 0
}