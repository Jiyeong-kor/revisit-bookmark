package com.jiyoung.revisit_bookmark

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
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
import androidx.glance.layout.ContentScale
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
        // 4x2: 1개, 4x3: 2개, 4x4: 3개, 4x5+: 4개
        private val SMALL  = DpSize(160.dp, 110.dp)
        private val MEDIUM = DpSize(160.dp, 240.dp)
        private val LARGE  = DpSize(160.dp, 360.dp)
        private val XLARGE = DpSize(160.dp, 490.dp)
    }

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override val sizeMode = SizeMode.Responsive(setOf(SMALL, MEDIUM, LARGE, XLARGE))

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { WidgetContent() }
    }

    private data class WidgetItem(
        val title: String,
        val type: String,
        val description: String,
        val url: String,
        val sourceDomain: String,
        val thumbnailLocalPath: String,
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
                    thumbnailLocalPath = obj.optString("thumbnailLocalPath"),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    @Composable
    private fun WidgetContent() {
        val widgetState = currentState<HomeWidgetGlanceState>()
        val size = LocalSize.current

        val maxItems = when {
            size.height >= 490.dp -> 4
            size.height >= 360.dp -> 3
            size.height >= 240.dp -> 2
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
                    ItemListContent(items = items, singleItem = maxItems == 1)
                }
            }
        }
    }

    // 루트 Column 자식 수 계산 (4개 아이템 기준):
    // index=0: Column(item) = 1
    // index=1: Box(divider) + Column(item) = 2  → 누계 3
    // index=2: Box(divider) + Column(item) = 2  → 누계 5
    // index=3: Box(divider) + Column(item) = 2  → 누계 7
    // Spacer = 1 → 누계 8
    // Row   = 1 → 누계 9  ✓ (10개 제한 안)
    @Composable
    private fun ItemListContent(items: List<WidgetItem>, singleItem: Boolean) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            items.forEachIndexed { index, item ->
                if (index > 0) {
                    Box(
                        modifier = GlanceModifier
                            .fillMaxWidth()
                            .height(1.dp)
                            .background(GlanceTheme.colors.outline),
                    ) {}
                }

                val clickAction = if (item.type == "link" && item.url.isNotEmpty()) {
                    actionStartActivityWithIntent(Intent(Intent.ACTION_VIEW, Uri.parse(item.url)))
                } else {
                    actionStartActivity<MainActivity>()
                }

                Column(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .padding(
                            top = if (index > 0) 8.dp else 0.dp,
                            bottom = if (index < items.size - 1) 8.dp else 0.dp,
                        )
                        .clickable(clickAction),
                ) {
                    ItemContent(item = item, showThumbnail = singleItem)
                }
            }

            Spacer(modifier = GlanceModifier.defaultWeight())

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.End,
            ) {
                Text(
                    text = "Revisit",
                    style = TextStyle(color = GlanceTheme.colors.outline, fontSize = 10.sp),
                )
            }
        }
    }

    // ItemContent Column 자식 수 (최대):
    // Image + Spacer + typeLabel + Spacer + title + Spacer + subtitle = 7 ✓
    @Composable
    private fun ItemContent(item: WidgetItem, showThumbnail: Boolean) {
        if (showThumbnail && item.thumbnailLocalPath.isNotEmpty()) {
            val bitmap = try {
                BitmapFactory.decodeFile(item.thumbnailLocalPath)
            } catch (_) {
                null
            }
            if (bitmap != null) {
                Image(
                    provider = ImageProvider(bitmap),
                    contentDescription = null,
                    modifier = GlanceModifier.fillMaxWidth().height(110.dp),
                    contentScale = ContentScale.Crop,
                )
                Spacer(modifier = GlanceModifier.padding(top = 8.dp))
            }
        }

        val typeLabel = when (item.type) {
            "link"       -> "🔗 링크"
            "memo"       -> "📝 메모"
            "screenshot" -> "🖼 스크린샷"
            else         -> ""
        }
        if (typeLabel.isNotEmpty()) {
            Text(
                text = typeLabel,
                style = TextStyle(color = GlanceTheme.colors.primary, fontSize = 12.sp),
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
            maxLines = if (showThumbnail && item.thumbnailLocalPath.isNotEmpty()) 2 else 3,
        )

        val subtitle = item.sourceDomain.ifEmpty { item.description }
        if (subtitle.isNotEmpty()) {
            Spacer(modifier = GlanceModifier.padding(top = 3.dp))
            Text(
                text = subtitle,
                style = TextStyle(color = GlanceTheme.colors.secondary, fontSize = 11.sp),
                maxLines = 1,
            )
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
                style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 14.sp),
            )
        }
    }
}
