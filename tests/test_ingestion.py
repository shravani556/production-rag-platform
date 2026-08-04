from app.ingestion.ingest import (
    chunk_section,
    clean_text,
    create_record_id,
    read_html_sections,
)


def test_clean_text_normalizes_whitespace_without_losing_paragraphs():
    assert clean_text("  first\r\n\r\n\r\nsecond\t value  ") == "first\n\nsecond value"


def test_record_ids_are_stable_and_content_sensitive():
    first = create_record_id("source.html", "Overview", 0, "content")

    assert first == create_record_id("source.html", "Overview", 0, "content")
    assert first != create_record_id("source.html", "Overview", 0, "other content")


def test_chunk_section_preserves_heading_and_splits_long_content():
    chunks = chunk_section("word " * 300, "Architecture", chunk_size=350, overlap=40)

    assert len(chunks) > 1
    assert all(chunk.startswith("Section: Architecture\n\n") for chunk in chunks)


def test_html_extraction_ignores_script_content_and_preserves_tables(tmp_path):
    source = tmp_path / "example.html"
    source.write_text(
        "<h1>Overview</h1><p>Useful text</p><script>ignore me</script>"
        "<table><tr><th>Name</th><td>Value</td></tr></table>",
        encoding="utf-8",
    )

    sections = read_html_sections(source)

    assert len(sections) == 1
    assert sections[0].section == "Overview"
    assert "Useful text" in sections[0].text
    assert "Name | Value" in sections[0].text
    assert "ignore me" not in sections[0].text
