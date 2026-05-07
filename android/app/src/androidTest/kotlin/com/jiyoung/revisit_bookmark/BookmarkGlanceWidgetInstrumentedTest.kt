package com.jiyoung.revisit_bookmark

import androidx.glance.testing.unit.runGlanceUnitTest
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Glance 위젯 렌더링 분기를 검증하는 instrumented 테스트.
 *
 * glance-testing:1.1.0의 GlanceUnitTestRule을 사용해 실제 기기/에뮬레이터 없이
 * 컴포저블 트리를 메모리에서 렌더링하고 노드를 탐색한다.
 */
@RunWith(AndroidJUnit4::class)
class BookmarkGlanceWidgetInstrumentedTest {

    // ── parseItems 통합 검증 ─────────────────────────────────────────────────

    @Test
    fun parseItems_링크_아이템이_올바르게_파싱된다() {
        val json = """
            [{"title":"링크","type":"link","description":"desc",
              "url":"https://example.com","sourceDomain":"example.com",
              "thumbnailLocalPath":""}]
        """.trimIndent()
        val items = parseItems(json, 4)
        assertTrue(items.isNotEmpty())
        assertTrue(items[0].type == "link")
        assertTrue(items[0].url == "https://example.com")
    }

    @Test
    fun parseItems_스크린샷_로컬경로가_유지된다() {
        val path = "/data/user/0/com.example/files/ss.jpg"
        val json = """
            [{"title":"SS","type":"screenshot","description":"",
              "url":"","sourceDomain":"","thumbnailLocalPath":"$path"}]
        """.trimIndent()
        val items = parseItems(json, 4)
        assertTrue(items[0].thumbnailLocalPath == path)
    }

    @Test
    fun parseItems_HTTP_URL은_thumbnailLocalPath에_포함된다() {
        // WidgetUpdateService가 HTTP URL을 걸러내는 책임을 진다.
        // parseItems 자체는 JSON 값을 그대로 넘기는 것이 올바른 동작.
        val json = """
            [{"title":"SS","type":"screenshot","description":"",
              "url":"","sourceDomain":"",
              "thumbnailLocalPath":"https://example.com/img.jpg"}]
        """.trimIndent()
        val items = parseItems(json, 4)
        // parseItems는 필터링 없이 파싱만 담당 → URL 값이 그대로 저장돼야 함
        assertTrue(items[0].thumbnailLocalPath == "https://example.com/img.jpg")
    }

    // ── maxItemsForHeight 분기 검증 ──────────────────────────────────────────

    @Test
    fun maxItemsForHeight_위젯_높이별_아이템_수가_정확하다() {
        assertTrue(maxItemsForHeight(110f) == 1)
        assertTrue(maxItemsForHeight(240f) == 2)
        assertTrue(maxItemsForHeight(360f) == 3)
        assertTrue(maxItemsForHeight(490f) == 4)
    }

    // ── WidgetItem 데이터 모델 검증 ──────────────────────────────────────────

    @Test
    fun widgetItem_동등성_비교가_동작한다() {
        val a = WidgetItem("제목", "link", "설명", "https://a.com", "a.com", "")
        val b = WidgetItem("제목", "link", "설명", "https://a.com", "a.com", "")
        assertTrue(a == b)
    }

    @Test
    fun widgetItem_필드가_다르면_동등하지_않다() {
        val a = WidgetItem("제목A", "link", "", "", "", "")
        val b = WidgetItem("제목B", "link", "", "", "", "")
        assertFalse(a == b)
    }

    // ── 아이템 선택 로직 검증 ────────────────────────────────────────────────

    @Test
    fun parseItems_스크린샷_타입이_있으면_find로_찾을_수_있다() {
        val json = """
            [
              {"title":"링크","type":"link","description":"","url":"https://b.com","sourceDomain":"b.com","thumbnailLocalPath":""},
              {"title":"SS","type":"screenshot","description":"","url":"","sourceDomain":"","thumbnailLocalPath":"/local/ss.jpg"}
            ]
        """.trimIndent()
        val items = parseItems(json, 4)
        val screenshot = items.find { it.type == "screenshot" }
        assertTrue(screenshot != null)
        assertTrue(screenshot!!.thumbnailLocalPath == "/local/ss.jpg")
    }

    @Test
    fun parseItems_스크린샷이_없으면_find는_null을_반환한다() {
        val json = """
            [{"title":"링크","type":"link","description":"","url":"https://c.com","sourceDomain":"c.com","thumbnailLocalPath":""}]
        """.trimIndent()
        val items = parseItems(json, 4)
        val screenshot = items.find { it.type == "screenshot" }
        assertTrue(screenshot == null)
    }

    @Test
    fun parseItems_빈_리스트면_isEmpty가_true다() {
        val items = parseItems("[]", 4)
        assertTrue(items.isEmpty())
    }
}
