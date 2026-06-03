package dev.merdan.wallet

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget that mirrors the app's balance/income/expense and offers
 * two deep-link buttons (large "Add expense", small "+ income").
 *
 * Extends [HomeWidgetProvider] so [onUpdate] receives the `home_widget` shared
 * preferences directly — the same store the Flutter side writes via
 * `WidgetService.sync()`. The buttons never mutate data; they launch
 * MainActivity with a `wallet://add?type=...` URI that the app routes to the
 * add dialog.
 */
class WalletWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.wallet_widget).apply {
                // Values written by WidgetService.sync(); fall back to a dash
                // until the first sync has run.
                val placeholder = "—"
                setTextViewText(R.id.widget_balance, widgetData.getString("balance", placeholder))
                setTextViewText(R.id.widget_income, widgetData.getString("income", placeholder))
                setTextViewText(R.id.widget_expense, widgetData.getString("expense", placeholder))

                // Button label in the app's selected language; fall back to the
                // bundled string until the first sync writes a localized value.
                setTextViewText(
                    R.id.widget_expense_label,
                    widgetData.getString("add_expense", null)
                        ?: context.getString(R.string.widget_add_expense),
                )

                // Tint the balance red when negative.
                val negative = widgetData.getBoolean("balance_negative", false)
                val balanceColor = if (negative) 0xFFE53935.toInt() else 0xFF1B5E20.toInt()
                setTextColor(R.id.widget_balance, balanceColor)

                // Expense button → add expense.
                setOnClickPendingIntent(
                    R.id.widget_expense_button,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("wallet://add?type=expense"),
                    ),
                )

                // Income button (+) → add income.
                setOnClickPendingIntent(
                    R.id.widget_income_button,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("wallet://add?type=income"),
                    ),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
