package com.yetzira.syncmonth

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import es.antonborri.home_widget.HomeWidgetProvider

/** Compact home widget: month hero remaining + Log spend. */
class QuickLogCompactWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          try {
            QuickLogWidgetViews.bindCompact(context, widgetData)
          } catch (e: Exception) {
            Log.e(TAG, "bindCompact failed; using fallback", e)
            QuickLogWidgetViews.bindFallback(context, compact = true)
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  companion object {
    private const val TAG = "QuickLogCompactWidget"
  }
}
