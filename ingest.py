from __future__ import annotations

import hashlib
import os
import re
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import chromadb
import ollama
from bs4 import BeautifulSoup, Tag
from pypdf import PdfReader


# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent
DOCS_PATH = PROJECT_ROOT / "docs"
CHROMA_PATH = PROJECT_ROOT / "data" / "chroma_db"

COLLECTION_NAME = "rag_docs"
EMBEDDING_MODEL = "nomic-embed-text"

CHUNK_SIZE = 1400
CHUNK_OVERLAP = 200
EMBEDDING_BATCH_SIZE = 16

SUPPORTED_EXTENSIONS = {".html", ".htm", ".pdf"}


@dataclass
class ExtractedSection:
    text: str
    section: str
    page: int | None = None


# ---------------------------------------------------------
# General helpers
# ---------------------------------------------------------

def clean_text(text: str) -> str:
    """Normalize whitespace while retaining paragraph boundaries."""

    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)

    return text.strip()


def create_record_id(
    source: str,
    section: str,
    chunk_index: int,
    text: str,
) -> str:
    raw_value = f"{source}|{section}|{chunk_index}|{text}"
    return hashlib.sha256(raw_value.encode("utf-8")).hexdigest()


# ---------------------------------------------------------
# HTML extraction
# ---------------------------------------------------------

def table_to_text(table: Tag) -> str:
    """Convert an HTML table into readable rows."""

    rows: list[str] = []

    for row in table.find_all("tr"):
        cells = [
            clean_text(cell.get_text(" ", strip=True))
            for cell in row.find_all(["th", "td"])
        ]

        cells = [cell for cell in cells if cell]

        if cells:
            rows.append(" | ".join(cells))

    if not rows:
        return ""

    return "TABLE:\n" + "\n".join(rows)


def read_html_sections(file_path: Path) -> list[ExtractedSection]:
    """
    Extract HTML by H1/H2/H3/H4 headings.

    Each section keeps its heading as metadata. Tables are preserved in a
    readable row format rather than being flattened into unrelated words.
    """

    html = file_path.read_text(encoding="utf-8", errors="ignore")
    soup = BeautifulSoup(html, "lxml")

    # Remove styling and navigation content that should not enter the index.
    for unwanted in soup(
        ["script", "style", "noscript", "nav", "footer", "header"]
    ):
        unwanted.decompose()

    sections: list[ExtractedSection] = []
    current_heading = "Document introduction"
    current_parts: list[str] = []

    def flush_section() -> None:
        nonlocal current_parts

        section_text = clean_text("\n\n".join(current_parts))

        if section_text:
            sections.append(
                ExtractedSection(
                    text=section_text,
                    section=current_heading,
                )
            )

        current_parts = []

    elements = soup.find_all(
        ["h1", "h2", "h3", "h4", "p", "li", "pre", "table"]
    )

    for element in elements:
        if element.name in {"h1", "h2", "h3", "h4"}:
            flush_section()

            heading = clean_text(element.get_text(" ", strip=True))
            if heading:
                current_heading = heading

            continue

        if element.name == "table":
            table_text = table_to_text(element)

            if table_text:
                current_parts.append(table_text)

            continue

        content = clean_text(element.get_text(" ", strip=True))

        if content:
            current_parts.append(content)

    flush_section()

    return sections


# ---------------------------------------------------------
# PDF extraction
# ---------------------------------------------------------

def read_pdf_sections(file_path: Path) -> list[ExtractedSection]:
    """
    Extract selectable text from each PDF page.

    This does not perform OCR. Image-only PDF pages require a separate OCR
    service or library.
    """

    reader = PdfReader(str(file_path))
    sections: list[ExtractedSection] = []

    for page_number, page in enumerate(reader.pages, start=1):
        page_text = clean_text(page.extract_text() or "")

        if page_text:
            sections.append(
                ExtractedSection(
                    text=page_text,
                    section=f"Page {page_number}",
                    page=page_number,
                )
            )
        else:
            print(
                f"  Warning: No selectable text found on page {page_number}. "
                "It may require OCR."
            )

    return sections


def read_document(file_path: Path) -> list[ExtractedSection]:
    extension = file_path.suffix.lower()

    if extension in {".html", ".htm"}:
        return read_html_sections(file_path)

    if extension == ".pdf":
        return read_pdf_sections(file_path)

    raise ValueError(f"Unsupported file type: {extension}")


# ---------------------------------------------------------
# Structure-aware overlapping chunking
# ---------------------------------------------------------

def split_long_paragraph(
    paragraph: str,
    chunk_size: int,
    overlap: int,
) -> list[str]:
    """Sliding-window fallback for a paragraph larger than chunk_size."""

    chunks: list[str] = []
    start = 0
    step = chunk_size - overlap

    while start < len(paragraph):
        end = start + chunk_size
        chunk = paragraph[start:end].strip()

        if chunk:
            chunks.append(chunk)

        start += step

    return chunks


def chunk_section(
    section_text: str,
    section_heading: str,
    chunk_size: int = CHUNK_SIZE,
    overlap: int = CHUNK_OVERLAP,
) -> list[str]:
    """
    Paragraph-aware chunking.

    It first respects paragraph boundaries. Sliding-window splitting is used
    only when a single paragraph is too large.
    """

    heading_prefix = f"Section: {section_heading}\n\n"
    available_size = max(300, chunk_size - len(heading_prefix))

    paragraphs = [
        clean_text(paragraph)
        for paragraph in re.split(r"\n\s*\n", section_text)
        if clean_text(paragraph)
    ]

    raw_chunks: list[str] = []
    current = ""

    for paragraph in paragraphs:
        if len(paragraph) > available_size:
            if current:
                raw_chunks.append(current.strip())
                current = ""

            raw_chunks.extend(
                split_long_paragraph(
                    paragraph=paragraph,
                    chunk_size=available_size,
                    overlap=overlap,
                )
            )
            continue

        candidate = (
            f"{current}\n\n{paragraph}".strip()
            if current
            else paragraph
        )

        if len(candidate) <= available_size:
            current = candidate
        else:
            if current:
                raw_chunks.append(current.strip())

            # Retain some context from the preceding chunk.
            preceding_context = current[-overlap:].strip() if current else ""

            current = (
                f"{preceding_context}\n\n{paragraph}".strip()
                if preceding_context
                else paragraph
            )

    if current:
        raw_chunks.append(current.strip())

    return [
        f"{heading_prefix}{chunk}".strip()
        for chunk in raw_chunks
        if chunk.strip()
    ]


# ---------------------------------------------------------
# Ollama embeddings
# ---------------------------------------------------------

def create_embeddings(texts: list[str]) -> list[list[float]]:
    """
    Generate embeddings in one Ollama batch.

    The current Ollama embedding endpoint accepts a string or list of strings.
    """

    response = ollama.embed(
        model=EMBEDDING_MODEL,
        input=texts,
    )

    embeddings = response["embeddings"]

    if len(embeddings) != len(texts):
        raise RuntimeError(
            "The number of embeddings returned by Ollama does not match "
            "the number of input chunks."
        )

    return embeddings


# ---------------------------------------------------------
# Database ingestion
# ---------------------------------------------------------

def reset_vector_database() -> None:
    if CHROMA_PATH.exists():
        shutil.rmtree(CHROMA_PATH)

    CHROMA_PATH.mkdir(parents=True, exist_ok=True)


def main() -> None:
    if not DOCS_PATH.exists():
        raise FileNotFoundError(
            f"Documents folder does not exist: {DOCS_PATH}"
        )

    reset_vector_database()

    client = chromadb.PersistentClient(path=str(CHROMA_PATH))

    collection = client.get_or_create_collection(
        name=COLLECTION_NAME,
        metadata={"hnsw:space": "cosine"},
    )

    documents: list[str] = []
    metadatas: list[dict[str, Any]] = []
    ids: list[str] = []

    supported_files = sorted(
        file_path
        for file_path in DOCS_PATH.iterdir()
        if file_path.is_file()
        and file_path.suffix.lower() in SUPPORTED_EXTENSIONS
    )

    if not supported_files:
        raise RuntimeError(
            "No supported HTML or PDF documents were found in the docs folder."
        )

    print("\nStarting document ingestion\n")

    for file_path in supported_files:
        print(f"Reading: {file_path.name}")

        sections = read_document(file_path)
        file_chunk_count = 0
        extracted_characters = sum(len(section.text) for section in sections)

        for section in sections:
            chunks = chunk_section(
                section_text=section.text,
                section_heading=section.section,
            )

            for section_chunk_index, chunk in enumerate(chunks):
                global_chunk_index = len(documents)

                record_id = create_record_id(
                    source=file_path.name,
                    section=section.section,
                    chunk_index=section_chunk_index,
                    text=chunk,
                )

                metadata: dict[str, Any] = {
                    "source": file_path.name,
                    "file_type": file_path.suffix.lower(),
                    "section": section.section,
                    "chunk": global_chunk_index,
                    "section_chunk": section_chunk_index,
                    "character_count": len(chunk),
                }

                if section.page is not None:
                    metadata["page"] = section.page

                ids.append(record_id)
                documents.append(chunk)
                metadatas.append(metadata)
                file_chunk_count += 1

        print(f"  Extracted characters: {extracted_characters}")
        print(f"  Sections found: {len(sections)}")
        print(f"  Chunks created: {file_chunk_count}\n")

    print(f"Generating embeddings for {len(documents)} chunks...")

    for start in range(0, len(documents), EMBEDDING_BATCH_SIZE):
        end = min(start + EMBEDDING_BATCH_SIZE, len(documents))

        batch_documents = documents[start:end]
        batch_embeddings = create_embeddings(batch_documents)

        collection.add(
            ids=ids[start:end],
            documents=batch_documents,
            embeddings=batch_embeddings,
            metadatas=metadatas[start:end],
        )

        print(f"  Stored chunks {start + 1} to {end}")

    print("\nIngestion completed successfully.")
    print(f"Total chunks stored: {collection.count()}")
    print(f"Vector database: {CHROMA_PATH}")


if __name__ == "__main__":
    main()