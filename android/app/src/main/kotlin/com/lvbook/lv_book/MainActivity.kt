package com.lvbook.lv_book

import android.content.res.Configuration
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

/**
 * Draws edge-to-edge (behind the status and navigation bars) on every Android
 * version, not only on Android 15+ where targetSdk 35 enforces it.
 *
 * FlutterActivity is not a ComponentActivity, so androidx.activity's
 * enableEdgeToEdge() is unavailable; this mirrors what it does. Flutter
 * receives the bar sizes as MediaQuery padding and the UI insets itself
 * (SafeArea / Scaffold). Dart additionally calls
 * SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge) and sets the bar
 * icon brightness per theme.
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyEdgeToEdge()
    }

    // uiMode is in android:configChanges, so a light/dark switch does not
    // recreate the activity; refresh the bar scrims for the new mode.
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        applyEdgeToEdge()
    }

    private fun applyEdgeToEdge() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val night = (resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        WindowCompat.getInsetsController(window, window.decorView).apply {
            isAppearanceLightStatusBars = !night
            isAppearanceLightNavigationBars = !night && Build.VERSION.SDK_INT >= 26
        }
        // Android 15+: edge-to-edge is enforced and bar colours are ignored.
        if (Build.VERSION.SDK_INT >= 35) return

        @Suppress("DEPRECATION")
        window.statusBarColor = Color.TRANSPARENT
        @Suppress("DEPRECATION")
        window.navigationBarColor = when {
            // The system draws its own contrast scrim behind 3-button
            // navigation; the gesture bar stays fully transparent.
            Build.VERSION.SDK_INT >= 29 -> Color.TRANSPARENT
            // Light nav-bar icons exist from API 26; use a translucent scrim.
            Build.VERSION.SDK_INT >= 26 -> if (night) DARK_SCRIM else LIGHT_SCRIM
            else -> DARK_SCRIM
        }
        if (Build.VERSION.SDK_INT >= 29) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = true
        }
    }

    private companion object {
        // Same scrims as androidx.activity.EdgeToEdge.
        val LIGHT_SCRIM = Color.argb(0xe6, 0xFF, 0xFF, 0xFF)
        val DARK_SCRIM = Color.argb(0x80, 0x1b, 0x1b, 0x1b)
    }
}
