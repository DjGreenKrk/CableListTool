from __future__ import annotations

import json
from pathlib import Path

from models import Project


def load_project(path: str | Path) -> Project:
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    return Project.from_dict(data)


def save_project(project: Project, path: str | Path) -> None:
    text = json.dumps(project.to_dict(), ensure_ascii=False, indent=2)
    Path(path).write_text(text + "\n", encoding="utf-8")

