package com.yetzira.syncmonth

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import es.antonborri.home_widget.HomeWidgetProvider

/** Extended home widget: month overview stats + Log spend. */
class QuickLogExtendedWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          try {
            QuickLogWidgetViews.bindExtended(context, widgetData)
          } catch (e: Exception) {
            Log.e(TAG, "bindExtended failed; using fallback", e)
            QuickLogWidgetViews.bindFallback(context, compact = false)
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  companion object {
    private const val TAG = "QuickLogExtendedWidget"
  }
}
