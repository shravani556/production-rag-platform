FROM python:3.12-slim

LABEL org.opencontainers.image.title="Production RAG Platform" \
      org.opencontainers.image.description="Document-grounded Streamlit RAG application using ChromaDB and Ollama" \
      org.opencontainers.image.version="0.1.0" \
      org.opencontainers.image.source="https://github.com/shravani556/production-rag-platform"

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    STREAMLIT_SERVER_ADDRESS=0.0.0.0 \
    STREAMLIT_SERVER_HEADLESS=true \
    STREAMLIT_SERVER_PORT=8501

RUN groupadd --system rag \
    && useradd --system --gid rag --create-home rag

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=rag:rag app ./app
COPY --chown=rag:rag app.py ingest.py ./

RUN mkdir -p /app/data/chroma_db /app/documents/source /app/evaluation \
    && chown -R rag:rag /app/data /app/documents /app/evaluation

EXPOSE 8501

VOLUME ["/app/data/chroma_db"]

USER rag

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8501/_stcore/health', timeout=3)"]

CMD ["streamlit", "run", "app.py"]
