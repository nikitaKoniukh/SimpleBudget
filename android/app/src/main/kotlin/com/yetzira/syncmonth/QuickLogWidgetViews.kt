package com.yetzira.syncmonth

import android.app.PendingIntent
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

internal object QuickLogWidgetViews {
  const val KEY_TITLE = "title"
  const val KEY_STATUS = "status"
  const val KEY_READY = "ready"
  const val KEY_LAYOUT_RTL = "layoutRtl"
  const val KEY_HERO_LABEL = "heroLabel"
  const val KEY_HERO_AMOUNT = "heroAmount"
  const val KEY_HERO_AMOUNT_COMPACT = "heroAmountCompact"
  const val KEY_HERO_IS_OVER = "heroIsOver"
  const val KEY_INCOME_LABEL = "incomeLabel"
  const val KEY_INCOME_AMOUNT = "incomeAmount"
  const val KEY_SPENT_LABEL = "spentLabel"
  const val KEY_SPENT_AMOUNT = "spentAmount"
  const val KEY_SAVED_LABEL = "savedLabel"
  const val KEY_SAVED_AMOUNT = "savedAmount"
  const val KEY_BUDGET_LABEL = "budgetLabel"
  const val KEY_BUDGET_AMOUNT = "budgetAmount"
  const val KEY_ACTION = "actionLabel"
  const val KEY_ACTION_SHORT = "actionLabelShort"

  const val QUICK_LOG_SPEND_URI = "syncmonth://quicklog/spend"

  private const val COLOR_TEXT = 0xFF1C2A24.toInt()
  private const val COLOR_PRIMARY = 0xFF3D7A5F.toInt()
  private const val COLOR_OVERSPEND = 0xFFE07A5F.toInt()

  fun launchIntent(context: Context): PendingIntent {
    return HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse(QUICK_LOG_SPEND_URI),
    )
  }

  fun bindCompact(context: Context, widgetData: SharedPreferences): RemoteViews {
    return RemoteViews(context.packageName, R.layout.quick_log_widget_compact).apply {
      bindCommon(context, widgetData, includeStats = false, compact = true)
    }
  }

  fun bindExtended(context: Context, widgetData: SharedPreferences): RemoteViews {
    return RemoteViews(context.packageName, R.layout.quick_log_widget_extended).apply {
      bindCommon(context, widgetData, includeStats = true, compact = false)
    }
  }

  /** Minimal safe layout used if the full bind fails (prevents "Couldn't add widget"). */
  fun bindFallback(context: Context, compact: Boolean): RemoteViews {
    val layout =
        if (compact) R.layout.quick_log_widget_compact else R.layout.quick_log_widget_extended
    return RemoteViews(context.packageName, layout).apply {
      setTextViewText(R.id.widget_title, "SyncMonth")
      setTextViewText(R.id.widget_status, context.getString(R.string.widget_open_app_to_refresh))
      setTextViewText(
          R.id.widget_action,
          if (compact) {
            context.getString(R.string.widget_log_spend_short)
          } else {
            context.getString(R.string.widget_log_spend)
          },
      )
      setViewVisibility(R.id.widget_status, View.VISIBLE)
      setViewVisibility(R.id.widget_hero_label, View.GONE)
      setViewVisibility(R.id.widget_hero_amount, View.GONE)
      if (!compact) {
        setViewVisibility(R.id.widget_stats, View.GONE)
      }
      val launchIntent = launchIntent(context)
      setOnClickPendingIntent(R.id.widget_root, launchIntent)
      setOnClickPendingIntent(R.id.widget_action, launchIntent)
    }
  }

  private fun RemoteViews.bindCommon(
      context: Context,
      widgetData: SharedPreferences,
      includeStats: Boolean,
      compact: Boolean,
  ) {
    val ready = widgetData.getString(KEY_READY, "0") == "1"
    // Layout direction + textAlignment come from XML (gravity/textAlignment=start).
    // Amount strings are formatted in the app locale so LTR/RTL stay consistent.

    val title = widgetData.getString(KEY_TITLE, null) ?: "SyncMonth"
    val status =
        widgetData.getString(KEY_STATUS, null)
            ?: context.getString(R.string.widget_sign_in_to_log)
    val action =
        if (compact) {
          widgetData.getString(KEY_ACTION_SHORT, null)
              ?: context.getString(R.string.widget_log_spend_short)
        } else {
          widgetData.getString(KEY_ACTION, null)
              ?: context.getString(R.string.widget_log_spend)
        }
    val heroLabel =
        widgetData.getString(KEY_HERO_LABEL, null)
            ?: context.getString(R.string.widget_remaining)
    val heroAmount =
        if (compact) {
          widgetData.getString(KEY_HERO_AMOUNT_COMPACT, null)
              ?: widgetData.getString(KEY_HERO_AMOUNT, null)
              ?: "—"
        } else {
          widgetData.getString(KEY_HERO_AMOUNT, null) ?: "—"
        }
    val heroIsOver = widgetData.getString(KEY_HERO_IS_OVER, "0") == "1"

    setTextViewText(R.id.widget_title, title)
    setTextViewText(R.id.widget_status, status)
    setTextViewText(R.id.widget_action, action)
    setTextViewText(R.id.widget_hero_label, heroLabel)
    setTextViewText(R.id.widget_hero_amount, heroAmount)
    setTextColor(
        R.id.widget_hero_amount,
        if (heroIsOver) COLOR_OVERSPEND else COLOR_PRIMARY,
    )

    if (ready) {
      setViewVisibility(R.id.widget_status, View.GONE)
      setViewVisibility(R.id.widget_hero_label, View.VISIBLE)
      setViewVisibility(R.id.widget_hero_amount, View.VISIBLE)
      if (includeStats) {
        setViewVisibility(R.id.widget_stats, View.VISIBLE)
        setTextViewText(
            R.id.widget_income_label,
            widgetData.getString(KEY_INCOME_LABEL, null)
                ?: context.getString(R.string.widget_income),
        )
        setTextViewText(
            R.id.widget_income_amount,
            widgetData.getString(KEY_INCOME_AMOUNT, null) ?: "—",
        )
        setTextViewText(
            R.id.widget_spent_label,
            widgetData.getString(KEY_SPENT_LABEL, null)
                ?: context.getString(R.string.widget_spent),
        )
        setTextViewText(
            R.id.widget_spent_amount,
            widgetData.getString(KEY_SPENT_AMOUNT, null) ?: "—",
        )
        setTextViewText(
            R.id.widget_saved_label,
            widgetData.getString(KEY_SAVED_LABEL, null)
                ?: context.getString(R.string.widget_saved),
        )
        setTextViewText(
            R.id.widget_saved_amount,
            widgetData.getString(KEY_SAVED_AMOUNT, null) ?: "—",
        )
        setTextViewText(
            R.id.widget_budget_label,
            widgetData.getString(KEY_BUDGET_LABEL, null)
                ?: context.getString(R.string.widget_budget),
        )
        setTextViewText(
            R.id.widget_budget_amount,
            widgetData.getString(KEY_BUDGET_AMOUNT, null) ?: "—",
        )
        setTextColor(R.id.widget_income_amount, COLOR_TEXT)
        setTextColor(R.id.widget_spent_amount, COLOR_TEXT)
        setTextColor(R.id.widget_saved_amount, COLOR_TEXT)
        setTextColor(R.id.widget_budget_amount, COLOR_TEXT)
      }
    } else {
      setViewVisibility(R.id.widget_status, View.VISIBLE)
      setViewVisibility(R.id.widget_hero_label, View.GONE)
      setViewVisibility(R.id.widget_hero_amount, View.GONE)
      if (includeStats) {
        setViewVisibility(R.id.widget_stats, View.GONE)
      }
    }

    val launchIntent = launchIntent(context)
    setOnClickPendingIntent(R.id.widget_root, launchIntent)
    setOnClickPendingIntent(R.id.widget_action, launchIntent)
  }
}
