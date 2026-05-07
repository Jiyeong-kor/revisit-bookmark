package com.jiyoung.revisit_bookmark

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.annotation.VisibleForTesting
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

// ── 데이터 모델 ──────────────────────────────────────────────────────────────

/** 위젯에 표시되는 북마크 아이템. 테스트에서 직접 생성할 수 있도록 internal. */
internal data class WidgetItem(
    val title: String,
    val type: String,
    val description: String,
    val url: String,
    val sourceDomain: String,
    val thumbnailLocalPath: String,
)

// ── 순수 함수 (JVM 단위 테스트 대상) ────────────────────────────────────────

/**
 * JSON 배열 문자열 → WidgetItem 리스트 변환.
 * [maxCount]만큼 잘라서 반환하며, 파싱 실패 시 빈 리스트를 반환한다.
 */
@VisibleForTesting
internal fun parseItems(json: String, maxCount: Int): List<WidgetItem> =
    try {
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

/**
 * 위젯 높이(dp)에 따라 표시할 최대 아이템 수를 반환한다.
 */
@VisibleForTesting
internal fun maxItemsForHeight(heightDp: Float): Int = when {
    heightDp >= 490f -> 4
    heightDp >= 360f -> 3
    heightDp >= 240f -> 2
    else -> 1
}

// ── 비트맵 유틸 ──────────────────────────────────────────────────────────────

/**
 * 위젯 메모리 한도(~15MB) 초과를 막기 위해 [maxWidth]×[maxHeight] 이내로 다운샘플링해 로드.
 * inSampleSize는 2의 거듭제곱으로만 설정 가능하므로 목표 크기보다 약간 클 수 있다.
 */
@VisibleForTesting
internal fun loadScaledBitmap(path: String, maxWidth: Int, maxHeight: Int): android.graphics.Bitmap? {
    if (path.isEmpty()) return null
    return try {
        val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, opts)
        var sampleSize = 1
        while (opts.outWidth / (sampleSize * 2) >= maxWidth ||
               opts.outHeight / (sampleSize * 2) >= maxHeight) {
            sampleSize *= 2
        }
        BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sampleSize })
    } catch (e: Exception) { null }
}

// ── GlanceAppWidget ──────────────────────────────────────────────────────────

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

    @Composable
    private fun WidgetContent() {
        val widgetState = currentState<HomeWidgetGlanceState>()
        val size = LocalSize.current

        val maxItems = maxItemsForHeight(size.height.value)
        val itemsJson = widgetState.preferences.getString("widget_items", "[]") ?: "[]"
        val items = parseItems(itemsJson, maxItems)

        GlanceTheme {
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

    @Composable
    private fun FullScreenshotContent(item: WidgetItem) {
        val bitmap = if (item.thumbnailLocalPath.isNotEmpty())
            loadScaledBitmap(item.thumbnailLocalPath, maxWidth = 1024, maxHeight = 1024)
        else null

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

    // 루트 Column 자식 수 (4개 아이템 기준): 1+2+2+2+1+1 = 9 ✓
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
        if (item.type == "link" && singleItem && item.thumbnailLocalPath.isNotEmpty()) {
            val bitmap = loadScaledBitmap(item.thumbnailLocalPath, maxWidth = 600, maxHeight = 200)
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
