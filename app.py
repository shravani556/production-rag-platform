from __future__ import annotations

import re
import time
import json
from pathlib import Path
from typing import Any

import chromadb
import ollama
import streamlit as st
from rank_bm25 import BM25Okapi


# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent
CHROMA_PATH = PROJECT_ROOT / "data" / "chroma_db"
EVALUATION_FILE = PROJECT_ROOT / "evaluation_cases.json"

COLLECTION_NAME = "rag_docs"

# Use this for the requested 3B version:
LLM_MODEL = "qwen2.5:3b"

# Change to qwen2.5:1.5b for faster CPU testing:
# LLM_MODEL = "qwen2.5:1.5b"

EMBEDDING_MODEL = "nomic-embed-text"

DENSE_CANDIDATES = 20
BM25_CANDIDATES = 20
RRF_CONSTANT = 60

MAX_HISTORY_MESSAGES = 6


# ---------------------------------------------------------
# Cached resources
# ---------------------------------------------------------

@st.cache_resource
def get_chroma_collection():
    client = chromadb.PersistentClient(path=str(CHROMA_PATH))

    return client.get_collection(name=COLLECTION_NAME)


@st.cache_resource
def load_cross_encoder():
    """
    Loaded only when the user enables reranking.

    The first use downloads the free reranker model and can take time.
    """

    from sentence_transformers import CrossEncoder

    return CrossEncoder("cross-encoder/ms-marco-MiniLM-L-6-v2")


# ---------------------------------------------------------
# Basic helpers
# ---------------------------------------------------------

def tokenize(text: str) -> list[str]:
    return re.findall(r"[a-zA-Z0-9_#.+/-]+", text.lower())
@st.cache_data
def load_evaluation_cases() -> list[dict[str, Any]]:
    """
    Load manually labelled test questions.

    These labels allow us to calculate real retrieval metrics instead of
    guessing whether retrieval was accurate.
    """

    if not EVALUATION_FILE.exists():
        return []

    with EVALUATION_FILE.open(
        "r",
        encoding="utf-8",
    ) as file:
        return json.load(file)


def normalize_text(text: str) -> str:
    """
    Normalize text for simple comparisons.
    """

    return " ".join(text.lower().strip().split())


def find_evaluation_case(question: str):

    normalized_question = normalize_text(question)

    print("===================================")
    print("USER QUESTION:")
    print(normalized_question)
    print("===================================")

    for evaluation_case in load_evaluation_cases():

        expected_question = normalize_text(
            evaluation_case["question"]
        )

        print("EXPECTED QUESTION:")
        print(expected_question)
        print("-----------------------------------")

        if normalized_question == expected_question:
            print("MATCH FOUND")
            return evaluation_case

    print("NO MATCH FOUND")
    return None


def section_matches_expected(
    retrieved_section: str,
    expected_sections: list[str],
) -> bool:
    """
    Return True when a retrieved section matches one expected section.

    Partial matching is used so headings such as:
    'A. Document ingestion pipeline'
    and
    'Document ingestion pipeline'
    can be considered equivalent.
    """

    retrieved_normalized = normalize_text(retrieved_section)

    for expected_section in expected_sections:
        expected_normalized = normalize_text(expected_section)

        if (
            expected_normalized in retrieved_normalized
            or retrieved_normalized in expected_normalized
        ):
            return True

    return False


def calculate_retrieval_metrics(
    candidates: list[dict[str, Any]],
    expected_sections: list[str],
) -> dict[str, float]:
    """
    Calculate labelled retrieval metrics.

    Hit@K:
        Whether at least one expected section appeared.

    Precision@K:
        Percentage of retrieved chunks that match expected sections.

    MRR:
        Measures how early the first relevant chunk appeared.
        Rank 1 = 1.0
        Rank 2 = 0.5
        Rank 3 = 0.333
    """

    relevance_flags: list[bool] = []

    for candidate in candidates:
        retrieved_section = candidate["metadata"].get(
            "section",
            "",
        )

        is_relevant = section_matches_expected(
            retrieved_section=retrieved_section,
            expected_sections=expected_sections,
        )

        relevance_flags.append(is_relevant)

    relevant_count = sum(relevance_flags)
    retrieved_count = len(candidates)

    precision_at_k = (
        relevant_count / retrieved_count
        if retrieved_count
        else 0.0
    )

    hit_at_k = 1.0 if relevant_count > 0 else 0.0

    reciprocal_rank = 0.0

    for rank, is_relevant in enumerate(
        relevance_flags,
        start=1,
    ):
        if is_relevant:
            reciprocal_rank = 1.0 / rank
            break

    return {
        "hit_at_k": hit_at_k,
        "precision_at_k": precision_at_k,
        "mrr": reciprocal_rank,
        "relevant_count": float(relevant_count),
        "retrieved_count": float(retrieved_count),
    }


def calculate_keyword_coverage(
    answer: str,
    expected_keywords: list[str],
) -> dict[str, Any]:
    """
    Measure whether expected concepts appear in the generated answer.

    This is not full semantic answer accuracy. It is a simple transparent
    completeness check for important concepts.
    """

    normalized_answer = normalize_text(answer)

    matched_keywords = [
        keyword
        for keyword in expected_keywords
        if normalize_text(keyword) in normalized_answer
    ]

    missing_keywords = [
        keyword
        for keyword in expected_keywords
        if normalize_text(keyword) not in normalized_answer
    ]

    coverage = (
        len(matched_keywords) / len(expected_keywords)
        if expected_keywords
        else 0.0
    )

    return {
        "coverage": coverage,
        "matched_keywords": matched_keywords,
        "missing_keywords": missing_keywords,
    }


def calculate_context_overlap(
    answer: str,
    context: str,
) -> float:
    """
    Calculate a basic lexical overlap between answer and context.

    This is only a groundedness proxy. It must not be treated as proof that
    every answer statement is correct.
    """

    answer_tokens = {
        token
        for token in tokenize(answer)
        if len(token) > 3
    }

    context_tokens = {
        token
        for token in tokenize(context)
        if len(token) > 3
    }

    if not answer_tokens:
        return 0.0

    shared_tokens = answer_tokens.intersection(context_tokens)

    return len(shared_tokens) / len(answer_tokens)
def cosine_similarity_percent(distance: float | None) -> float:
    """
    Convert Chroma cosine distance into a simple similarity percentage.

    Because the collection uses cosine distance:
        similarity ≈ 1 - distance

    This is useful for visualization only.
    It is not an answer-confidence score.
    """

    if distance is None:
        return 0.0

    similarity = 1.0 - float(distance)

    return max(0.0, min(1.0, similarity)) * 100


def extract_ollama_usage(response: Any) -> dict[str, float]:
    """
    Extract token and timing information returned by Ollama.
    Ollama durations are returned in nanoseconds.
    """

    prompt_tokens = int(response.get("prompt_eval_count", 0) or 0)
    output_tokens = int(response.get("eval_count", 0) or 0)

    prompt_duration_ns = int(
        response.get("prompt_eval_duration", 0) or 0
    )

    output_duration_ns = int(
        response.get("eval_duration", 0) or 0
    )

    load_duration_ns = int(
        response.get("load_duration", 0) or 0
    )

    total_duration_ns = int(
        response.get("total_duration", 0) or 0
    )

    output_duration_seconds = output_duration_ns / 1_000_000_000

    tokens_per_second = (
        output_tokens / output_duration_seconds
        if output_duration_seconds > 0
        else 0.0
    )

    return {
        "prompt_tokens": prompt_tokens,
        "output_tokens": output_tokens,
        "total_tokens": prompt_tokens + output_tokens,
        "prompt_eval_seconds": (
            prompt_duration_ns / 1_000_000_000
        ),
        "output_eval_seconds": (
            output_duration_ns / 1_000_000_000
        ),
        "load_seconds": load_duration_ns / 1_000_000_000,
        "ollama_total_seconds": (
            total_duration_ns / 1_000_000_000
        ),
        "tokens_per_second": tokens_per_second,
    }    

def get_embedding(text: str) -> list[float]:
    response = ollama.embed(
        model=EMBEDDING_MODEL,
        input=text,
    )

    return response["embeddings"][0]


def unique_source_names(collection) -> list[str]:
    results = collection.get(include=["metadatas"])

    return sorted(
        {
            metadata["source"]
            for metadata in results["metadatas"]
            if metadata and metadata.get("source")
        }
    )


def build_contextual_search_query(
    current_question: str,
    messages: list[dict[str, str]],
) -> str:
    """
    Resolve follow-up questions without making another LLM call.

    Example:
      Previous: What is RAG?
      Current: What are its limitations?

    Search query:
      What is RAG? What are its limitations?
    """

    follow_up_markers = {
        "it",
        "its",
        "that",
        "this",
        "they",
        "them",
        "those",
        "these",
        "explain more",
        "give example",
        "what about",
        "why",
        "how",
    }

    normalized = current_question.lower().strip()
    appears_to_be_follow_up = (
        len(current_question.split()) <= 12
        or any(marker in normalized for marker in follow_up_markers)
    )

    if not appears_to_be_follow_up:
        return current_question

    previous_user_questions = [
        message["content"]
        for message in messages
        if message["role"] == "user"
    ]

    if not previous_user_questions:
        return current_question

    previous_question = previous_user_questions[-1]

    return f"{previous_question}\nFollow-up question: {current_question}"


# ---------------------------------------------------------
# Dense retrieval
# ---------------------------------------------------------

def dense_retrieve(
    collection,
    query: str,
    candidate_count: int,
    selected_sources: list[str],
) -> list[dict[str, Any]]:
    query_embedding = get_embedding(query)

    query_arguments: dict[str, Any] = {
        "query_embeddings": [query_embedding],
        "n_results": candidate_count,
        "include": ["documents", "metadatas", "distances"],
    }

    if selected_sources:
        query_arguments["where"] = {
            "source": {"$in": selected_sources}
        }

    results = collection.query(**query_arguments)

    candidates: list[dict[str, Any]] = []

    for rank, (
        record_id,
        document,
        metadata,
        distance,
    ) in enumerate(
        zip(
            results["ids"][0],
            results["documents"][0],
            results["metadatas"][0],
            results["distances"][0],
        ),
        start=1,
    ):
        candidates.append(
            {
                "id": record_id,
                "document": document,
                "metadata": metadata,
                "dense_rank": rank,
                "distance": float(distance),
            }
        )

    return candidates


# ---------------------------------------------------------
# BM25 keyword retrieval
# ---------------------------------------------------------

def bm25_retrieve(
    collection,
    query: str,
    candidate_count: int,
    selected_sources: list[str],
) -> list[dict[str, Any]]:
    results = collection.get(
        include=["documents", "metadatas"]
    )

    records: list[dict[str, Any]] = []

    for record_id, document, metadata in zip(
        results["ids"],
        results["documents"],
        results["metadatas"],
    ):
        if selected_sources and metadata["source"] not in selected_sources:
            continue

        records.append(
            {
                "id": record_id,
                "document": document,
                "metadata": metadata,
            }
        )

    if not records:
        return []

    tokenized_corpus = [
        tokenize(record["document"])
        for record in records
    ]

    bm25 = BM25Okapi(tokenized_corpus)
    scores = bm25.get_scores(tokenize(query))

    ranked_indexes = sorted(
        range(len(scores)),
        key=lambda index: scores[index],
        reverse=True,
    )[:candidate_count]

    candidates: list[dict[str, Any]] = []

    for rank, index in enumerate(ranked_indexes, start=1):
        candidate = dict(records[index])
        candidate["bm25_rank"] = rank
        candidate["bm25_score"] = float(scores[index])
        candidates.append(candidate)

    return candidates


# ---------------------------------------------------------
# Hybrid fusion
# ---------------------------------------------------------

def reciprocal_rank_fusion(
    dense_candidates: list[dict[str, Any]],
    bm25_candidates: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """
    Merge dense and BM25 rankings using Reciprocal Rank Fusion.

    Documents appearing in both result sets receive a higher combined score.
    """

    combined: dict[str, dict[str, Any]] = {}

    for candidate in dense_candidates:
        record_id = candidate["id"]

        combined[record_id] = dict(candidate)
        combined[record_id]["rrf_score"] = (
            1.0 / (RRF_CONSTANT + candidate["dense_rank"])
        )

    for candidate in bm25_candidates:
        record_id = candidate["id"]
        bm25_contribution = (
            1.0 / (RRF_CONSTANT + candidate["bm25_rank"])
        )

        if record_id not in combined:
            combined[record_id] = dict(candidate)
            combined[record_id]["rrf_score"] = 0.0

        combined[record_id]["rrf_score"] += bm25_contribution
        combined[record_id]["bm25_rank"] = candidate["bm25_rank"]
        combined[record_id]["bm25_score"] = candidate["bm25_score"]

    return sorted(
        combined.values(),
        key=lambda item: item["rrf_score"],
        reverse=True,
    )


# ---------------------------------------------------------
# Optional Cross-Encoder reranking
# ---------------------------------------------------------

def cross_encoder_rerank(
    query: str,
    candidates: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    if not candidates:
        return []

    reranker = load_cross_encoder()

    pairs = [
        [query, candidate["document"]]
        for candidate in candidates
    ]

    scores = reranker.predict(pairs)

    reranked: list[dict[str, Any]] = []

    for candidate, score in zip(candidates, scores):
        updated_candidate = dict(candidate)
        updated_candidate["reranker_score"] = float(score)
        reranked.append(updated_candidate)

    return sorted(
        reranked,
        key=lambda item: item["reranker_score"],
        reverse=True,
    )


# ---------------------------------------------------------
# Complete retrieval
# ---------------------------------------------------------

def retrieve(
    collection,
    query: str,
    final_top_k: int,
    selected_sources: list[str],
    use_reranker: bool,
) -> tuple[list[dict[str, Any]], dict[str, float]]:
    retrieval_start = time.perf_counter()

    dense_start = time.perf_counter()
    dense_candidates = dense_retrieve(
        collection=collection,
        query=query,
        candidate_count=DENSE_CANDIDATES,
        selected_sources=selected_sources,
    )
    dense_time = time.perf_counter() - dense_start

    bm25_start = time.perf_counter()
    bm25_candidates = bm25_retrieve(
        collection=collection,
        query=query,
        candidate_count=BM25_CANDIDATES,
        selected_sources=selected_sources,
    )
    bm25_time = time.perf_counter() - bm25_start

    fusion_start = time.perf_counter()
    fused_candidates = reciprocal_rank_fusion(
        dense_candidates=dense_candidates,
        bm25_candidates=bm25_candidates,
    )
    fusion_time = time.perf_counter() - fusion_start

    reranker_time = 0.0

    if use_reranker:
        reranker_start = time.perf_counter()

        # Re-rank a limited candidate set for reasonable CPU performance.
        fused_candidates = cross_encoder_rerank(
            query=query,
            candidates=fused_candidates[:12],
        )

        reranker_time = time.perf_counter() - reranker_start

    final_candidates = fused_candidates[:final_top_k]

    timings = {
        "dense": dense_time,
        "bm25": bm25_time,
        "fusion": fusion_time,
        "reranker": reranker_time,
        "total_retrieval": time.perf_counter() - retrieval_start,
    }

    return final_candidates, timings


# ---------------------------------------------------------
# Prompt and answer generation
# ---------------------------------------------------------

def build_context(candidates: list[dict[str, Any]]) -> str:
    context_blocks: list[str] = []

    for number, candidate in enumerate(candidates, start=1):
        metadata = candidate["metadata"]

        source = metadata.get("source", "Unknown")
        section = metadata.get("section", "Unknown")
        page = metadata.get("page")

        citation_label = (
            f"Source {number}: {source}, section: {section}"
        )

        if page is not None:
            citation_label += f", page: {page}"

        context_blocks.append(
            f"[{citation_label}]\n{candidate['document']}"
        )

    return "\n\n---\n\n".join(context_blocks)


def ask_llm(
    question: str,
    context: str,
    chat_history: list[dict[str, str]],
) -> tuple[str, dict[str, float]]:
    system_prompt = """
You are a strict document-grounded RAG assistant.

Rules:
1. Answer only from the supplied document context.
2. Do not introduce facts that are absent from the context.
3. If the context is insufficient, clearly say:
   "I could not find enough information in the uploaded documents."
4. When the user asks to understand a topic, explain:
   - what it means,
   - why it matters,
   - the workflow or steps,
   - and a simple example when available.
5. When asked about a workflow, present the steps in their correct order.
6. Mention source file names and sections used.
7. Clearly distinguish information directly stated in the source from any
   interpretation.
"""

    recent_history = chat_history[-MAX_HISTORY_MESSAGES:]

    messages: list[dict[str, str]] = [
        {
            "role": "system",
            "content": system_prompt.strip(),
        }
    ]

    messages.extend(recent_history)

    messages.append(
        {
            "role": "user",
            "content": (
                f"DOCUMENT CONTEXT:\n{context}\n\n"
                f"CURRENT QUESTION:\n{question}"
            ),
        }
    )

    response = ollama.chat(
        model=LLM_MODEL,
        messages=messages,
        stream=False,
        options={
            "temperature": 0.1,
            "num_ctx": 4096,
        },
    )

    return response["message"]["content"], extract_ollama_usage(response)


# ---------------------------------------------------------
# Streamlit UI
# ---------------------------------------------------------

st.set_page_config(
    page_title="Advanced Local RAG Assistant",
    page_icon="📚",
    layout="wide",
)

st.title("Advanced Local RAG Assistant")
st.caption(
    "Hybrid search + metadata + optional reranking + conversation memory"
)

try:
    collection = get_chroma_collection()
except Exception as error:
    st.error(
        "The ChromaDB collection could not be opened. "
        "Run `python ingest.py` first."
    )
    st.exception(error)
    st.stop()


# Initialize conversation memory.
if "messages" not in st.session_state:
    st.session_state.messages = []


# Sidebar settings.
with st.sidebar:
    st.header("RAG Settings")

    st.write(f"**LLM:** `{LLM_MODEL}`")
    st.write(f"**Embedding:** `{EMBEDDING_MODEL}`")
    st.write(f"**Indexed chunks:** `{collection.count()}`")

    all_sources = unique_source_names(collection)

    selected_sources = st.multiselect(
        "Search these documents",
        options=all_sources,
        default=all_sources,
    )

    top_k = st.slider(
        "Final chunks sent to Qwen",
        min_value=1,
        max_value=8,
        value=4,
    )

    use_reranker = st.checkbox(
        "Enable Cross-Encoder reranking",
        value=False,
        help=(
            "Improves relevance but uses more CPU. "
            "The first run downloads the reranker model."
        ),
    )

    if st.button("Clear conversation"):
        st.session_state.messages = []
        st.rerun()


# Display existing chat.
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])


question = st.chat_input("Ask a question from your documents")


if question:
    with st.chat_message("user"):
        st.markdown(question)

    previous_messages = list(st.session_state.messages)

    st.session_state.messages.append(
        {
            "role": "user",
            "content": question,
        }
    )

    total_start = time.perf_counter()

    search_query = build_contextual_search_query(
        current_question=question,
        messages=previous_messages,
    )

    try:
        with st.chat_message("assistant"):
            with st.status(
                "Searching documents and generating answer...",
                expanded=True,
            ) as status:
                st.write(f"Search query: `{search_query}`")

                candidates, retrieval_timings = retrieve(
                    collection=collection,
                    query=search_query,
                    final_top_k=top_k,
                    selected_sources=selected_sources,
                    use_reranker=use_reranker,
                )

                if not candidates:
                    raise RuntimeError(
                        "No matching document chunks were found."
                    )

                st.write(
                    f"Retrieved {len(candidates)} final chunks."
                )

                context = build_context(candidates)

                llm_start = time.perf_counter()

                answer, ollama_usage = ask_llm(
                question=question,
                context=context,
                chat_history=previous_messages,
)

                llm_time = time.perf_counter() - llm_start
                total_time = time.perf_counter() - total_start

                status.update(
                    label="Answer completed",
                    state="complete",
                    expanded=False,
                )

            st.markdown(answer)

            st.subheader("Pipeline Monitor")

            pipeline_columns = st.columns(7)

            pipeline_columns[0].success("✅ Query")
            pipeline_columns[1].success("✅ Embedding")
            pipeline_columns[2].success("✅ Dense")
            pipeline_columns[3].success("✅ BM25")
            pipeline_columns[4].success("✅ RRF")

            if use_reranker:
                pipeline_columns[5].success("✅ Reranker")
            else:
                pipeline_columns[5].info("➖ Reranker")

            pipeline_columns[6].success("✅ Qwen")

            st.subheader("Performance")

            performance_columns = st.columns(4)

            performance_columns[0].metric(
                "Dense retrieval",
                f"{retrieval_timings['dense']:.2f}s",
            )

            performance_columns[1].metric(
                "BM25 retrieval",
                f"{retrieval_timings['bm25']:.2f}s",
            )

            performance_columns[2].metric(
                "LLM generation",
                f"{llm_time:.2f}s",
            )

            performance_columns[3].metric(
                "Total",
                f"{total_time:.2f}s",
            )

            if use_reranker:
                st.write(
                    "Cross-Encoder reranking: "
                    f"{retrieval_timings['reranker']:.2f}s"
                )

            st.subheader("Model Usage")

            usage_columns = st.columns(5)

            usage_columns[0].metric(
                "Prompt tokens",
                int(ollama_usage["prompt_tokens"]),
            )

            usage_columns[1].metric(
                "Output tokens",
                int(ollama_usage["output_tokens"]),
            )

            usage_columns[2].metric(
                "Total tokens",
                int(ollama_usage["total_tokens"]),
            )

            usage_columns[3].metric(
                "Tokens/sec",
                f"{ollama_usage['tokens_per_second']:.2f}",
            )

            usage_columns[4].metric(
                "Model load",
                f"{ollama_usage['load_seconds']:.2f}s",
            )

            with st.expander("Detailed Ollama timings"):
                st.write(
                    "Prompt evaluation: "
                    f"{ollama_usage['prompt_eval_seconds']:.2f}s"
                )

                st.write(
                    "Output generation: "
                    f"{ollama_usage['output_eval_seconds']:.2f}s"
                )

                st.write(
                    "Ollama total duration: "
                    f"{ollama_usage['ollama_total_seconds']:.2f}s"
                )         
            

            # -------------------------------------------------
            # Evaluation Dashboard
            # -------------------------------------------------

            st.subheader("Evaluation Dashboard")

            evaluation_case = find_evaluation_case(question)

            if evaluation_case is None:
                st.info(
                    "This question does not yet have a labelled "
                    "evaluation case. Add it to evaluation_cases.json "
                    "to calculate accuracy-related metrics."
                )

                context_overlap = calculate_context_overlap(
                    answer=answer,
                    context=context,
                )

                st.metric(
                    "Context overlap proxy",
                    f"{context_overlap * 100:.1f}%",
                    help=(
                        "This only measures shared words between the "
                        "answer and retrieved context. It is not a true "
                        "accuracy score."
                    ),
                )

            else:
                retrieval_metrics = calculate_retrieval_metrics(
                    candidates=candidates,
                    expected_sections=evaluation_case[
                        "expected_sections"
                    ],
                )

                keyword_metrics = calculate_keyword_coverage(
                    answer=answer,
                    expected_keywords=evaluation_case[
                        "expected_keywords"
                    ],
                )

                context_overlap = calculate_context_overlap(
                    answer=answer,
                    context=context,
                )

                evaluation_columns = st.columns(4)

                evaluation_columns[0].metric(
                    "Hit@K",
                    (
                        "100%"
                        if retrieval_metrics["hit_at_k"] == 1.0
                        else "0%"
                    ),
                    help=(
                        "Whether at least one expected source section "
                        "was retrieved."
                    ),
                )

                evaluation_columns[1].metric(
                    f"Precision@{len(candidates)}",
                    (
                        f"{retrieval_metrics['precision_at_k'] * 100:.1f}%"
                    ),
                    help=(
                        "Percentage of retrieved chunks matching the "
                        "manually labelled expected sections."
                    ),
                )

                evaluation_columns[2].metric(
                    "MRR",
                    f"{retrieval_metrics['mrr']:.3f}",
                    help=(
                        "Reciprocal rank of the first relevant result. "
                        "1.0 means the best result was relevant."
                    ),
                )

                evaluation_columns[3].metric(
                    "Answer coverage",
                    f"{keyword_metrics['coverage'] * 100:.1f}%",
                    help=(
                        "Percentage of manually expected concepts "
                        "mentioned in the answer."
                    ),
                )

                second_evaluation_row = st.columns(3)

                second_evaluation_row[0].metric(
                    "Relevant chunks",
                    (
                        f"{int(retrieval_metrics['relevant_count'])}"
                        f"/{int(retrieval_metrics['retrieved_count'])}"
                    ),
                )

                second_evaluation_row[1].metric(
                    "Context overlap proxy",
                    f"{context_overlap * 100:.1f}%",
                    help=(
                        "Shared answer/context terms. This is only a "
                        "groundedness proxy."
                    ),
                )

                second_evaluation_row[2].metric(
                    "End-to-end latency",
                    f"{total_time:.2f}s",
                )

                with st.expander("Evaluation details"):
                    st.write("**Expected sections:**")

                    for expected_section in evaluation_case[
                        "expected_sections"
                    ]:
                        st.write(f"- {expected_section}")

                    st.write("**Matched answer concepts:**")

                    if keyword_metrics["matched_keywords"]:
                        for keyword in keyword_metrics[
                            "matched_keywords"
                        ]:
                            st.write(f"✅ {keyword}")
                    else:
                        st.write("No expected keywords matched.")

                    st.write("**Missing answer concepts:**")

                    if keyword_metrics["missing_keywords"]:
                        for keyword in keyword_metrics[
                            "missing_keywords"
                        ]:
                            st.write(f"❌ {keyword}")
                    else:
                        st.write("No expected concepts are missing.")

            st.subheader("Retrieved Evidence")
            st.caption(
                "Similarity is derived from cosine distance. "
                "It indicates retrieval closeness, not answer correctness."
            )

            similarity_data = []

            for number, candidate in enumerate(candidates, start=1):
                metadata = candidate["metadata"]

                similarity_data.append(
                    {
                        "Chunk": (
                            f"{number}. "
                            f"{metadata.get('section', 'Unknown')}"
                        ),
                        "Similarity": cosine_similarity_percent(
                            candidate.get("distance")
                        ),
                    }
                )

            if similarity_data:
                st.dataframe(
                    similarity_data,
                    use_container_width=True,
                    hide_index=True,
                    column_config={
                        "Similarity": st.column_config.ProgressColumn(
                            "Similarity",
                            min_value=0,
                            max_value=100,
                            format="%.1f%%",
                        )
                    },
                )

            for number, candidate in enumerate(candidates, start=1):
                metadata = candidate["metadata"]

                source = metadata.get("source", "Unknown")
                section = metadata.get("section", "Unknown")
                page = metadata.get("page")

                label = (
                    f"{number}. {source} — {section}"
                    + (f" — page {page}" if page is not None else "")
                )

                with st.expander(label):
                    st.write(
                        f"Hybrid RRF score: "
                        f"{candidate.get('rrf_score', 0):.6f}"
                    )

                    if "distance" in candidate:
                        st.write(
                            f"Vector distance: "
                            f"{candidate['distance']:.6f}"
                        )

                    if "bm25_score" in candidate:
                        st.write(
                            f"BM25 score: "
                            f"{candidate['bm25_score']:.4f}"
                        )

                    if "reranker_score" in candidate:
                        st.write(
                            f"Reranker score: "
                            f"{candidate['reranker_score']:.4f}"
                        )

                    st.text(candidate["document"])

        st.session_state.messages.append(
            {
                "role": "assistant",
                "content": answer,
            }
        )

    except Exception as error:
        st.error("The RAG request failed.")
        st.exception(error)
