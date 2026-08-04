from pathlib import Path

from app.config.runtime import environment_path, environment_string


def test_environment_path_uses_default_when_variable_is_unset(monkeypatch):
    monkeypatch.delenv("RAG_CHROMA_PATH", raising=False)

    assert environment_path("RAG_CHROMA_PATH", Path("data/chroma")) == Path(
        "data/chroma"
    )


def test_environment_helpers_use_configured_values(monkeypatch):
    monkeypatch.setenv("RAG_CHROMA_PATH", "custom/chroma")
    monkeypatch.setenv("RAG_LLM_MODEL", "test-model")

    assert environment_path("RAG_CHROMA_PATH", Path("unused")) == Path(
        "custom/chroma"
    )
    assert environment_string("RAG_LLM_MODEL", "unused") == "test-model"
