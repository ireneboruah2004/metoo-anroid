package app.metoo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

/** The red SOS button on the home screen. Every tap is sent to SosService. */
class SosWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val intent = Intent(context, SosService::class.java).setAction(SosService.ACTION_TAP)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val pi = if (Build.VERSION.SDK_INT >= 26)
            PendingIntent.getForegroundService(context, 0, intent, flags)
        else
            PendingIntent.getService(context, 0, intent, flags)

        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_sos)
            views.setOnClickPendingIntent(R.id.widget_root, pi)
            manager.updateAppWidget(id, views)
        }
    }
}
