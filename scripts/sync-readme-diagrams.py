# -*- coding: utf-8 -*-
"""Sync Mermaid blocks in README.md from docs/architecture/*.mmd sources."""
from pathlib import Path
import re


def replace_mermaid_after_heading(readme: str, heading: str, mmd_content: str) -> str:
    pattern = re.compile(
        rf"({re.escape(heading)}.*?```mermaid\n)(.*?)(```)",
        re.DOTALL,
    )
    match = pattern.search(readme)
    if not match:
        raise ValueError(f"No mermaid block found after heading: {heading!r}")
    return readme[: match.start(2)] + mmd_content.rstrip() + "\n" + readme[match.end(2) :]


def main() -> None:
    repo = Path(__file__).resolve().parents[1]
    readme_path = repo / "README.md"
    clean_path = repo / "docs" / "architecture" / "clean-architecture.mmd"
    class_path = repo / "docs" / "architecture" / "class-diagram.mmd"

    readme = readme_path.read_text(encoding="utf-8")
    readme = replace_mermaid_after_heading(readme, "## Architecture", clean_path.read_text(encoding="utf-8"))
    readme = replace_mermaid_after_heading(readme, "### Class Diagram", class_path.read_text(encoding="utf-8"))
    readme_path.write_text(readme, encoding="utf-8")
    print(f"Synced {readme_path}")


if __name__ == "__main__":
    main()
