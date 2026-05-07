package com.jiyoung.revisit_bookmark

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalSize
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
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
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import org.json.JSONArray

class BookmarkGlanceWidget : GlanceAppWidget() {

    companion object {
        private val SMALL  = DpSize(160.dp, 110.dp)  // 3x2: 1개
        private val MEDIUM = DpSize(220.dp, 160.dp)  // 4x3: 2개
        private val LARGE  = DpSize(300.dp, 210.dp)  // 5x4+: 3개
    }

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override val sizeMode = SizeMode.Responsive(setOf(SMALL, MEDIUM, LARGE))

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { WidgetContent() }
    }

    private data class WidgetItem(
        val title: String,
        val type: String,
        val description: String,
        val url: String,
        val sourceDomain: String,
    )

    private fun parseItems(json: String, maxCount: Int): List<WidgetItem> {
        return try {
            val array = JSONArray(json)
            (0 until minOf(maxCount, array.length())).map { i ->
                val obj = array.getJSONObject(i)
                WidgetItem(
                    title = obj.optString("title"),
                    type = obj.optString("type"),
                    description = obj.optString("description"),
                    url = obj.optString("url"),
                    sourceDomain = obj.optString("sourceDomain"),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    @androidx.compose.runtime.Composable
    private fun WidgetContent() {
        val widgetState = currentState<HomeWidgetGlanceState>()
        val size = LocalSize.current

        val maxItems = when {
            size.height >= 210.dp -> 3
            size.height >= 160.dp -> 2
            else -> 1
        }

        val itemsJson = widgetState.preferences.getString("widget_items", "[]") ?: "[]"
        val items = parseItems(itemsJson, maxItems)

        GlanceTheme {
            Box(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(GlanceTheme.colors.surface)
                    .padding(16.dp),
                contentAlignment = Alignment.TopStart,
            ) {
                if (items.isEmpty()) {
                    EmptyContent()
                } else {
                    Column(modifier = GlanceModifier.fillMaxSize()) {
                        items.forEachIndexed { index, item ->
                            if (index > 0) {
                                Spacer(modifier = GlanceModifier.padding(top = 8.dp))
                                Box(
                                    modifier = GlanceModifier
                                        .fillMaxWidth()
                                        .height(1.dp)
                                        .background(GlanceTheme.colors.outline),
                                ) {}
                                Spacer(modifier = GlanceModifier.padding(top = 8.dp))
                            }

                            val clickAction = if (item.type == "link" && item.url.isNotEmpty()) {
                                actionStartActivityWithIntent(
                                    Intent(Intent.ACTION_VIEW, Uri.parse(item.url))
                                )
                            } else {
                                actionStartActivity<MainActivity>()
                            }

                            Column(
                                modifier = GlanceModifier
                                    .fillMaxWidth()
                                    .clickable(clickAction),
                            ) {
                                ItemContent(item = item)
                            }
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
        }
    }

    @androidx.compose.runtime.Composable
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

    @androidx.compose.runtime.Composable
    private fun ItemContent(item: WidgetItem) {
        val typeLabel = when (item.type) {
            "link"       -> "🔗 링크"
            "memo"       -> "📝 메모"
            "screenshot" -> "🖼 스크린샷"
            else         -> ""
        }

        if (typeLabel.isNotEmpty()) {
            Text(
                text = typeLabel,
                style = TextStyle(
                    color = GlanceTheme.colors.primary,
                    fontSize = 12.sp,
                ),
            )
            Spacer(modifier = GlanceModifier.padding(top = 4.dp))
        }

        Text(
            text = item.title,
            style = TextStyle(
                color = GlanceTheme.colors.onSurface,
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
            ),
            maxLines = 3,
        )

        val subtitle = item.sourceDomain.ifEmpty { item.description }
        if (subtitle.isNotEmpty()) {
            Spacer(modifier = GlanceModifier.padding(top = 3.dp))
            Text(
                text = subtitle,
                style = TextStyle(
                    color = GlanceTheme.colors.secondary,
                    fontSize = 11.sp,
                ),
                maxLines = 1,
            )
        }
    }
}
