package com.jiyoung.revisit_bookmark

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionStartActivity as actionStartActivityWithIntent
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition

class BookmarkGlanceWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { WidgetContent() }
    }

    @Composable
    private fun WidgetContent() {
        val widgetState = currentState<HomeWidgetGlanceState>()
        val title = widgetState.preferences.getString("widget_title", "") ?: ""
        val type = widgetState.preferences.getString("widget_type", "") ?: ""
        val description = widgetState.preferences.getString("widget_description", "") ?: ""
        val sourceDomain = widgetState.preferences.getString("widget_source_domain", "") ?: ""
        val url = widgetState.preferences.getString("widget_url", "") ?: ""

        val clickAction = if (type == "link" && url.isNotEmpty()) {
            actionStartActivityWithIntent(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
        } else {
            actionStartActivity<MainActivity>()
        }

        GlanceTheme {
            Box(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(GlanceTheme.colors.surface)
                    .clickable(clickAction)
                    .padding(16.dp),
                contentAlignment = Alignment.TopStart,
            ) {
                if (title.isEmpty()) {
                    EmptyContent()
                } else {
                    BookmarkContent(
                        title = title,
                        type = type,
                        description = description,
                        sourceDomain = sourceDomain,
                    )
                }
            }
        }
    }

    @Composable
    private fun EmptyContent() {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Text(
                text = "Revisit",
                style = TextStyle(
                    color = GlanceTheme.colors.primary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                ),
            )
            Spacer(modifier = GlanceModifier.padding(top = 8.dp))
            Text(
                text = "북마크를 추가하면\n여기에 표시됩니다",
                style = TextStyle(
                    color = GlanceTheme.colors.onSurface,
                    fontSize = 14.sp,
                ),
            )
        }
    }

    @Composable
    private fun BookmarkContent(
        title: String,
        type: String,
        description: String,
        sourceDomain: String,
    ) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            val typeLabel = when (type) {
                "link" -> "🔗 링크"
                "memo" -> "📝 메모"
                "screenshot" -> "🖼 스크린샷"
                else -> ""
            }
            if (typeLabel.isNotEmpty()) {
                Text(
                    text = typeLabel,
                    style = TextStyle(
                        color = GlanceTheme.colors.primary,
                        fontSize = 12.sp,
                    ),
                )
                Spacer(modifier = GlanceModifier.padding(top = 6.dp))
            }

            Text(
                text = title,
                style = TextStyle(
                    color = GlanceTheme.colors.onSurface,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium,
                ),
                maxLines = 4,
            )

            if (description.isNotEmpty()) {
                Spacer(modifier = GlanceModifier.padding(top = 6.dp))
                Text(
                    text = description,
                    style = TextStyle(
                        color = GlanceTheme.colors.secondary,
                        fontSize = 12.sp,
                    ),
                    maxLines = 3,
                )
            }

            if (sourceDomain.isNotEmpty()) {
                Spacer(modifier = GlanceModifier.padding(top = 4.dp))
                Text(
                    text = sourceDomain,
                    style = TextStyle(
                        color = GlanceTheme.colors.outline,
                        fontSize = 11.sp,
                    ),
                    maxLines = 1,
                )
            }

            Spacer(modifier = GlanceModifier.defaultWeight())

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.End,
            ) {
                Text(
                    text = "Revisit",
                    style = TextStyle(
                        color = GlanceTheme.colors.outline,
                        fontSize = 10.sp,
                    ),
                )
            }
        }
    }
}
