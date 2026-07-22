package com.fulldome.mahabharata.screens

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.text.TextUtils
import androidx.appcompat.app.AppCompatActivity
import com.fulldome.mahabharata.BuildConfig
import com.fulldome.mahabharata.R
import com.fulldome.mahabharata.model.Settings
import com.fulldome.mahabharata.model.TokenModel
import com.fulldome.mahabharata.server.DataService
import com.fulldome.mahabharata.utils.AnalyticsEvents
import com.ironwaterstudio.server.Request
import com.ironwaterstudio.server.data.ApiResult
import com.ironwaterstudio.server.listeners.CallListener
import com.ironwaterstudio.utils.FbUtils
import com.ironwaterstudio.utils.UiHelper

class SplashActivity : AppCompatActivity() {
    private val updateDeviceListener: CallListener = object : CallListener(this, false) {
        override fun onSuccess(result: ApiResult) {
            val tokenModel = result.getData(TokenModel::class.java)
            Settings.getInstance().deviceToken = tokenModel.token
            Settings.getInstance().save()

            if (!isFinishing) {
                showMenuActivityDelayed()
            }
        }

        override fun showError(request: Request, result: ApiResult) {
            if (TextUtils.isEmpty(Settings.getInstance().deviceToken)) {
                UiHelper.showSnackbar(activity,
                    getString(if (result.errorStringRes > 0) result.errorStringRes else R.string.error_common))
                backEnabled = true
            } else if (BuildConfig.DEBUG) {
                UiHelper.showSnackbar(activity,
                    getString(if (result.errorStringRes > 0) result.errorStringRes else R.string.error_common))
            }
        }
    }

    private var startTime: Long = 0
    private var backEnabled = false


    @SuppressLint("HardwareIds")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_splash)

        startTime = System.currentTimeMillis()

        updateDeviceListener.register()
        DataService.updateDevice(this, updateDeviceListener)
        FbUtils.logEvent(AnalyticsEvents.CATEGORY_APP, AnalyticsEvents.ACTION_OPEN)
    }

    override fun onBackPressed() {
        if (backEnabled) {
            super.onBackPressed()
        }
    }

    private fun showMenuActivityDelayed() {
        Handler().postDelayed({
            startActivity(Intent(this@SplashActivity, MenuActivity::class.java)
                .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK))
            overridePendingTransition(R.anim.fade_in, 0)
        }, Math.max(0, WAIT_DELAY - (System.currentTimeMillis() - startTime)))
    }


    companion object {
        private const val WAIT_DELAY = 1000
    }
}