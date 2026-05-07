package com.jiyoung.revisit_bookmark

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
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
import androidx.glance.layout.width
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle

class BookmarkGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { WidgetContent() }
    }

    @Composable
    private fun WidgetContent() {
        val prefs = currentState<Preferences>()
        val title = prefs[stringPreferencesKey("widget_title")] ?: ""
        val type = prefs[stringPreferencesKey("widget_type")] ?: ""
        val description = prefs[stringPreferencesKey("widget_description")] ?: ""
        val sourceDomain = prefs[stringPreferencesKey("widget_source_domain")] ?: ""

        GlanceTheme {
            Box(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(GlanceTheme.colors.surface)
                    .clickable(actionStartActivity<MainActivity>())
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
            // 타입 배지
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
                        fontSize = 11.sp,
                    ),
                )
                Spacer(modifier = GlanceModifier.padding(top = 4.dp))
            }

            // 제목
            Text(
                text = title,
                style = TextStyle(
                    color = GlanceTheme.colors.onSurface,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Medium,
                ),
                maxLines = 3,
            )

            // 설명 or 출처
            val subtitle = sourceDomain.ifEmpty { description }
            if (subtitle.isNotEmpty()) {
                Spacer(modifier = GlanceModifier.padding(top = 4.dp))
                Text(
                    text = subtitle,
                    style = TextStyle(
                        color = GlanceTheme.colors.secondary,
                        fontSize = 11.sp,
                    ),
                    maxLines = 1,
                )
            }

            Spacer(modifier = GlanceModifier.defaultWeight())

            // 앱 이름
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
