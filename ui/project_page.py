from __future__ import annotations

from PySide6.QtWidgets import (
    QFormLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QPushButton,
    QPlainTextEdit,
    QVBoxLayout,
    QWidget,
)

from ui.helpers import lines_to_list


class ProjectPage(QWidget):
    def __init__(self, window) -> None:
        super().__init__()
        self.window = window

        self.name_edit = QLineEdit()
        self.code_edit = QLineEdit()
        self.cabinet_type_rules_edit = QPlainTextEdit()
        self.endpoint_type_rules_edit = QPlainTextEdit()
        self.signal_types_edit = QPlainTextEdit()
        self.statuses_edit = QPlainTextEdit()

        project_form = QFormLayout()
        project_form.addRow("Nazwa", self.name_edit)
        project_form.addRow("Kod", self.code_edit)

        project_box = QGroupBox("Projekt")
        project_box.setLayout(project_form)

        settings_layout = QHBoxLayout()
        settings_layout.addWidget(self.group("Typy i nazwy szaf", self.cabinet_type_rules_edit, "Format: Typ=Wzór"))
        settings_layout.addWidget(self.group("Typy i nazwy punktów", self.endpoint_type_rules_edit, "Format: Typ=Wzór|Priorytet"))
        settings_layout.addWidget(self.group("Typy sygnałów", self.signal_types_edit, "Format: Typ=Kod eksportu|Priorytet"))
        settings_layout.addWidget(self.group("Statusy", self.statuses_edit))

        save_button = QPushButton("Zastosuj zmiany")
        save_button.clicked.connect(self.apply_changes)

        layout = QVBoxLayout(self)
        layout.addWidget(project_box)
        layout.addLayout(settings_layout)
        layout.addWidget(save_button)
        layout.addStretch()

    def group(self, title: str, editor: QPlainTextEdit, hint: str = "Jedna wartość w linii.") -> QGroupBox:
        editor.setMinimumHeight(220)
        box = QGroupBox(title)
        layout = QVBoxLayout(box)
        layout.addWidget(QLabel(hint))
        layout.addWidget(editor)
        return box

    def refresh(self) -> None:
        project = self.window.project
        self.name_edit.setText(project.name)
        self.code_edit.setText(project.code)
        self.cabinet_type_rules_edit.setPlainText(
            format_type_rules(project.settings.cabinet_types, project.settings.cabinet_name_rules)
        )
        self.endpoint_type_rules_edit.setPlainText(
            format_type_rules(
                project.settings.endpoint_types,
                project.settings.endpoint_name_rules,
                project.settings.endpoint_type_priorities,
            )
        )
        self.signal_types_edit.setPlainText(
            format_type_rules(
                project.settings.signal_types,
                project.settings.signal_type_export_names,
                project.settings.signal_type_priorities,
            )
        )
        self.statuses_edit.setPlainText("\n".join(project.settings.statuses))

    def apply_changes(self) -> None:
        project = self.window.project
        project.name = self.name_edit.text().strip()
        project.code = self.code_edit.text().strip()
        project.settings.cabinet_types, project.settings.cabinet_name_rules = parse_type_rules(
            self.cabinet_type_rules_edit.toPlainText()
        )
        (
            project.settings.endpoint_types,
            project.settings.endpoint_name_rules,
            project.settings.endpoint_type_priorities,
        ) = parse_type_rules_with_priorities(self.endpoint_type_rules_edit.toPlainText())
        (
            project.settings.signal_types,
            project.settings.signal_type_export_names,
            project.settings.signal_type_priorities,
        ) = parse_type_rules_with_priorities(self.signal_types_edit.toPlainText())
        project.settings.statuses = lines_to_list(self.statuses_edit.toPlainText())
        self.window.refresh_all()


def parse_priorities(text: str) -> dict[str, int]:
    result: dict[str, int] = {}
    for line in lines_to_list(text):
        if "=" in line:
            key, value = line.split("=", 1)
        elif ":" in line:
            key, value = line.split(":", 1)
        else:
            continue
        try:
            priority = int(value.strip())
        except ValueError:
            continue
        key = key.strip()
        if key and priority > 0:
            result[key] = priority
    return result


def parse_mapping(text: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in lines_to_list(text):
        if "=" in line:
            key, value = line.split("=", 1)
        elif ":" in line:
            key, value = line.split(":", 1)
        else:
            continue
        key = key.strip()
        value = value.strip()
        if key and value:
            result[key] = value
    return result


def format_mapping(mapping: dict[str, str]) -> str:
    return "\n".join(f"{key}={value}" for key, value in mapping.items())


def parse_type_rules(text: str) -> tuple[list[str], dict[str, str]]:
    types: list[str] = []
    rules: dict[str, str] = {}
    for line in lines_to_list(text):
        if "=" in line:
            key, value = line.split("=", 1)
        elif ":" in line:
            key, value = line.split(":", 1)
        else:
            key, value = line, ""
        key = key.strip()
        value = value.strip()
        if not key:
            continue
        types.append(key)
        if value:
            rules[key] = value
    return types, rules


def parse_type_rules_with_priorities(text: str) -> tuple[list[str], dict[str, str], dict[str, int]]:
    types: list[str] = []
    rules: dict[str, str] = {}
    priorities: dict[str, int] = {}
    for line in lines_to_list(text):
        priority = None
        body = line
        if "|" in line:
            body, priority_text = line.rsplit("|", 1)
            try:
                priority = int(priority_text.strip())
            except ValueError:
                priority = None

        parsed_types, parsed_rules = parse_type_rules(body)
        if not parsed_types:
            continue
        item_type = parsed_types[0]
        types.append(item_type)
        if item_type in parsed_rules:
            rules[item_type] = parsed_rules[item_type]
        if priority is not None and priority > 0:
            priorities[item_type] = priority
    return types, rules, priorities


def format_type_rules(types: list[str], rules: dict[str, str], priorities: dict[str, int] | None = None) -> str:
    lines = []
    seen = set()
    priorities = priorities or {}
    for item_type in types:
        seen.add(item_type)
        rule = rules.get(item_type)
        priority = priorities.get(item_type)
        line = f"{item_type}={rule}" if rule else item_type
        if priority:
            line = f"{line}|{priority}"
        lines.append(line)
    for item_type, rule in rules.items():
        if item_type not in seen:
            priority = priorities.get(item_type)
            line = f"{item_type}={rule}"
            if priority:
                line = f"{line}|{priority}"
            lines.append(line)
    return "\n".join(lines)
