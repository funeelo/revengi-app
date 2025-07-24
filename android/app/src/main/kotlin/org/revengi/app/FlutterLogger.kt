package org.revengi.app

import com.reandroid.apk.APKLogger

class FlutterLogger : APKLogger {
    override fun logMessage(msg: String) {
        MainActivity.sendLog(msg)
    }

    override fun logError(
        msg: String?,
        tr: Throwable?,
    ) {
        if (msg != null) {
            MainActivity.sendLog(msg, "error")
        }
    }

    override fun logVerbose(msg: String?) {
        // We don't wanna log anything
    }
}
