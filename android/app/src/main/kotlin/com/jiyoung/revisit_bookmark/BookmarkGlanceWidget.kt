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
        private val SMALL  = DpSize(160.dp, 110.dp)  // 4x2: 1개
        private val MEDIUM = DpSize(160.dp, 240.dp)  // 4x3: 2개
        private val LARGE  = DpSize(160.dp, 360.dp)  // 4x4: 3개
        private val XLARGE = DpSize(160.dp, 490.dp)  // 4x5+: 4개
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
            // 스크린샷이 선택된 경우: 전체 화면을 이미지로 채움
            val screenshotItem = items.find { it.type == "screenshot" }
            when {
                items.isEmpty() ->
                    Box(
                        modifier = GlanceModifier.fillMaxSize()
                            .background(GlanceTheme.colors.surface)
                            .padding(16.dp),
                        contentAlignment = Alignment.TopStart,
                    ) { EmptyContent() }

                screenshotItem != null ->
                    FullScreenshotContent(screenshotItem)

                else ->
                    Box(
                        modifier = GlanceModifier.fillMaxSize()
                            .background(GlanceTheme.colors.surface)
                            .padding(16.dp),
                        contentAlignment = Alignment.TopStart,
                    ) {
                        ItemListContent(items = items, singleItem = maxItems == 1)
                    }
            }
        }
    }

    // 스크린샷: 위젯 전체를 이미지로 꽉 채움
    @Composable
    private fun FullScreenshotContent(item: WidgetItem) {
        val bitmap = try {
            if (item.thumbnailLocalPath.isNotEmpty())
                BitmapFactory.decodeFile(item.thumbnailLocalPath)
            else null
        } catch (e: Exception) { null }

        if (bitmap != null) {
            Image(
                provider = ImageProvider(bitmap),
                contentDescription = null,
                modifier = GlanceModifier
                    .fillMaxSize()
                    .clickable(actionStartActivity<MainActivity>()),
                contentScale = ContentScale.Crop,
            )
        } else {
            Box(
                modifier = GlanceModifier.fillMaxSize()
                    .background(GlanceTheme.colors.surface)
                    .padding(16.dp),
                contentAlignment = Alignment.TopStart,
            ) { EmptyContent() }
        }
    }

    // 루트 Column 자식 수 (4개 아이템 기준):
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
                    ItemContent(item = item, singleItem = singleItem)
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
    // 링크+썸네일: Image + Spacer + typeLabel + Spacer + title + Spacer + subtitle = 7 ✓
    // 링크(썸네일 없음): typeLabel + Spacer + title + Spacer + subtitle = 5 ✓
    // 메모: typeLabel + Spacer + title + Spacer + content = 5 ✓
    @Composable
    private fun ItemContent(item: WidgetItem, singleItem: Boolean) {
        // 링크: 단일 뷰에서 썸네일을 1칸(55dp) 높이로 표시
        if (item.type == "link" && singleItem && item.thumbnailLocalPath.isNotEmpty()) {
            val bitmap = try {
                BitmapFactory.decodeFile(item.thumbnailLocalPath)
            } catch (_) {
                null
            }
            if (bitmap != null) {
                Image(
                    provider = ImageProvider(bitmap),
                    contentDescription = null,
                    modifier = GlanceModifier.fillMaxWidth().height(55.dp),
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

        if (item.type == "memo") {
            // 메모: 내용 전체 표시 (줄임 없음)
            Text(
                text = item.title,
                style = TextStyle(
                    color = GlanceTheme.colors.onSurface,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Medium,
                ),
            )
            if (item.description.isNotEmpty()) {
                Spacer(modifier = GlanceModifier.padding(top = 3.dp))
                Text(
                    text = item.description,
                    style = TextStyle(color = GlanceTheme.colors.secondary, fontSize = 11.sp),
                )
            }
        } else {
            // 링크: 제목 2줄 + 도메인 1줄
            Text(
                text = item.title,
                style = TextStyle(
                    color = GlanceTheme.colors.onSurface,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Medium,
                ),
                maxLines = 2,
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
