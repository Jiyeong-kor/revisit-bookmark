package com.jiyoung.revisit_bookmark

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ParseItemsTest {

    @Test
    fun `빈 배열 JSON은 빈 리스트를 반환한다`() {
        val result = parseItems("[]", 4)
        assertTrue(result.isEmpty())
    }

    @Test
    fun `유효한 JSON을 WidgetItem 리스트로 파싱한다`() {
        val json = """
            [
              {
                "title": "테스트 제목",
                "type": "link",
                "description": "설명",
                "url": "https://example.com",
                "sourceDomain": "example.com",
                "thumbnailLocalPath": "/local/img.jpg"
              }
            ]
        """.trimIndent()

        val result = parseItems(json, 4)
        assertEquals(1, result.size)
        val item = result[0]
        assertEquals("테스트 제목", item.title)
        assertEquals("link", item.type)
        assertEquals("설명", item.description)
        assertEquals("https://example.com", item.url)
        assertEquals("example.com", item.sourceDomain)
        assertEquals("/local/img.jpg", item.thumbnailLocalPath)
    }

    @Test
    fun `maxCount로 결과 수가 제한된다`() {
        val json = """
            [
              {"title":"a","type":"link","description":"","url":"","sourceDomain":"","thumbnailLocalPath":""},
              {"title":"b","type":"memo","description":"","url":"","sourceDomain":"","thumbnailLocalPath":""},
              {"title":"c","type":"link","description":"","url":"","sourceDomain":"","thumbnailLocalPath":""}
            ]
        """.trimIndent()

        val result = parseItems(json, 2)
        assertEquals(2, result.size)
        assertEquals("a", result[0].title)
        assertEquals("b", result[1].title)
    }

    @Test
    fun `JSON 배열보다 큰 maxCount는 배열 크기만큼만 반환한다`() {
        val json = """[{"title":"only","type":"memo","description":"","url":"","sourceDomain":"","thumbnailLocalPath":""}]"""
        val result = parseItems(json, 10)
        assertEquals(1, result.size)
    }

    @Test
    fun `잘못된 JSON이면 빈 리스트를 반환한다`() {
        val result = parseItems("not json at all", 4)
        assertTrue(result.isEmpty())
    }

    @Test
    fun `빈 문자열이면 빈 리스트를 반환한다`() {
        val result = parseItems("", 4)
        assertTrue(result.isEmpty())
    }

    @Test
    fun `누락된 필드는 빈 문자열로 처리된다`() {
        val json = """[{"title":"제목만"}]"""
        val result = parseItems(json, 4)
        assertEquals(1, result.size)
        assertEquals("제목만", result[0].title)
        assertEquals("", result[0].type)
        assertEquals("", result[0].url)
    }

    @Test
    fun `여러 타입의 아이템이 순서대로 파싱된다`() {
        val json = """
            [
              {"title":"링크","type":"link","description":"","url":"https://a.com","sourceDomain":"a.com","thumbnailLocalPath":""},
              {"title":"메모","type":"memo","description":"내용","url":"","sourceDomain":"","thumbnailLocalPath":""},
              {"title":"스크린샷","type":"screenshot","description":"","url":"","sourceDomain":"","thumbnailLocalPath":"/local/ss.jpg"}
            ]
        """.trimIndent()

        val result = parseItems(json, 4)
        assertEquals(3, result.size)
        assertEquals("link", result[0].type)
        assertEquals("memo", result[1].type)
        assertEquals("screenshot", result[2].type)
        assertEquals("/local/ss.jpg", result[2].thumbnailLocalPath)
    }
}

/**
 * screenshotItem 선택 조건 테스트:
 * items.find { it.type == "screenshot" && it.thumbnailLocalPath.isNotEmpty() }
 *
 * - 썸네일 있는 스크린샷 → screenshotItem != null → FullScreenshotContent 분기
 * - 썸네일 없는 스크린샷 → screenshotItem == null → ItemListContent 분기 (빈 상태 방지)
 */
class ScreenshotItemSelectionTest {

    private fun makeItem(type: String, thumbnailLocalPath: String) = WidgetItem(
        title = "제목", type = type, description = "", url = "", sourceDomain = "",
        thumbnailLocalPath = thumbnailLocalPath,
    )

    @Test
    fun `썸네일 있는 스크린샷은 screenshotItem으로 선택된다`() {
        val items = listOf(
            makeItem("memo", ""),
            makeItem("screenshot", "/data/app/widget_thumb.jpg"),
        )
        val screenshotItem = items.find { it.type == "screenshot" && it.thumbnailLocalPath.isNotEmpty() }
        assertEquals("/data/app/widget_thumb.jpg", screenshotItem?.thumbnailLocalPath)
    }

    @Test
    fun `썸네일 없는 스크린샷은 screenshotItem으로 선택되지 않는다`() {
        val items = listOf(
            makeItem("link", ""),
            makeItem("screenshot", ""),   // thumbnailLocalPath 비어있음
        )
        val screenshotItem = items.find { it.type == "screenshot" && it.thumbnailLocalPath.isNotEmpty() }
        assertEquals(null, screenshotItem)
    }

    @Test
    fun `스크린샷 없이 링크·메모만 있으면 screenshotItem은 null이다`() {
        val items = listOf(makeItem("link", ""), makeItem("memo", ""))
        val screenshotItem = items.find { it.type == "screenshot" && it.thumbnailLocalPath.isNotEmpty() }
        assertEquals(null, screenshotItem)
    }

    @Test
    fun `여러 스크린샷 중 썸네일 있는 첫 번째만 선택된다`() {
        val items = listOf(
            makeItem("screenshot", ""),                      // 썸네일 없음 → 무시
            makeItem("screenshot", "/first/thumb.jpg"),     // 썸네일 있음 → 선택
            makeItem("screenshot", "/second/thumb.jpg"),    // 두 번째는 선택 안 됨
        )
        val screenshotItem = items.find { it.type == "screenshot" && it.thumbnailLocalPath.isNotEmpty() }
        assertEquals("/first/thumb.jpg", screenshotItem?.thumbnailLocalPath)
    }
}

class MaxItemsForHeightTest {

    @Test
    fun `490dp 이상이면 4개`() {
        assertEquals(4, maxItemsForHeight(490f))
        assertEquals(4, maxItemsForHeight(600f))
        assertEquals(4, maxItemsForHeight(1000f))
    }

    @Test
    fun `360dp 이상 490dp 미만이면 3개`() {
        assertEquals(3, maxItemsForHeight(360f))
        assertEquals(3, maxItemsForHeight(400f))
        assertEquals(3, maxItemsForHeight(489f))
    }

    @Test
    fun `240dp 이상 360dp 미만이면 2개`() {
        assertEquals(2, maxItemsForHeight(240f))
        assertEquals(2, maxItemsForHeight(300f))
        assertEquals(2, maxItemsForHeight(359f))
    }

    @Test
    fun `240dp 미만이면 1개`() {
        assertEquals(1, maxItemsForHeight(110f))
        assertEquals(1, maxItemsForHeight(200f))
        assertEquals(1, maxItemsForHeight(239f))
    }

    @Test
    fun `경계값이 올바른 구간에 속한다`() {
        assertEquals(1, maxItemsForHeight(239.9f))
        assertEquals(2, maxItemsForHeight(240f))
        assertEquals(2, maxItemsForHeight(359.9f))
        assertEquals(3, maxItemsForHeight(360f))
        assertEquals(3, maxItemsForHeight(489.9f))
        assertEquals(4, maxItemsForHeight(490f))
    }
}
