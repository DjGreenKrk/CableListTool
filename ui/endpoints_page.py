from __future__ import annotations

from PySide6.QtWidgets import (
    QComboBox,
    QFormLayout,
    QHBoxLayout,
    QLineEdit,
    QMessageBox,
    QPushButton,
    QSpinBox,
    QTableWidget,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)

from models import Endpoint
from ui.helpers import fill_combo, item, natural_sort_key, set_table_headers
from ui.name_sequence import make_sequence, next_name_after_sequence, next_name_for_prefix, resolve_name_rule


class EndpointsPage(QWidget):
    def __init__(self, window) -> None:
        super().__init__()
        self.window = window
        self.current_id: str | None = None
        self.row_endpoint_ids: list[str] = []

        self.table = QTableWidget()
        set_table_headers(self.table, ["Nazwa", "Typ", "Lokalizacja", "Opis"])
        self.table.itemSelectionChanged.connect(self.load_selected)

        self.name_edit = QLineEdit()
        self.type_combo = QComboBox()
        self.type_combo.setEditable(True)
        self.location_edit = QLineEdit()
        self.count_spin = QSpinBox()
        self.count_spin.setRange(1, 9999)
        self.description_edit = QTextEdit()

        form = QFormLayout()
        form.addRow("Nazwa", self.name_edit)
        form.addRow("Typ", self.type_combo)
        form.addRow("Lokalizacja", self.location_edit)
        form.addRow("Ilość nowych", self.count_spin)
        form.addRow("Opis", self.description_edit)

        new_button = QPushButton("Nowy")
        save_button = QPushButton("Zapisz")
        delete_button = QPushButton("Usuń")
        new_button.clicked.connect(self.clear_form)
        save_button.clicked.connect(self.save_item)
        delete_button.clicked.connect(self.delete_item)

        buttons = QHBoxLayout()
        buttons.addWidget(new_button)
        buttons.addWidget(save_button)
        buttons.addWidget(delete_button)

        right = QVBoxLayout()
        right.addLayout(form)
        right.addLayout(buttons)
        right.addStretch()

        layout = QHBoxLayout(self)
        layout.addWidget(self.table, 2)
        layout.addLayout(right, 1)

    def refresh(self) -> None:
        fill_combo(self.type_combo, self.window.project.settings.endpoint_types, self.type_combo.currentText())
        endpoints = sorted(
            self.window.project.endpoints,
            key=lambda endpoint: (
                self.window.project.settings.endpoint_type_priorities.get(endpoint.endpoint_type, 999_999),
                natural_sort_key(endpoint.name),
            ),
        )
        self.row_endpoint_ids = [endpoint.id for endpoint in endpoints]
        self.table.blockSignals(True)
        self.table.setRowCount(len(endpoints))
        for row, endpoint in enumerate(endpoints):
            self.table.setItem(row, 0, item(endpoint.name))
            self.table.setItem(row, 1, item(endpoint.endpoint_type))
            self.table.setItem(row, 2, item(endpoint.location))
            self.table.setItem(row, 3, item(endpoint.description))
        self.table.resizeColumnsToContents()
        self.table.blockSignals(False)

    def clear_form(self) -> None:
        self.current_id = None
        self.name_edit.clear()
        fill_combo(self.type_combo, self.window.project.settings.endpoint_types)
        self.location_edit.clear()
        self.count_spin.setValue(1)
        self.count_spin.setEnabled(True)
        self.description_edit.clear()
        self.table.clearSelection()

    def load_selected(self) -> None:
        row = self.table.currentRow()
        if row < 0 or row >= len(self.row_endpoint_ids):
            return
        endpoint = self.window.project.find_endpoint(self.row_endpoint_ids[row])
        if endpoint is None:
            return
        self.current_id = endpoint.id
        self.name_edit.setText(endpoint.name)
        fill_combo(self.type_combo, self.window.project.settings.endpoint_types, endpoint.endpoint_type)
        self.location_edit.setText(endpoint.location)
        self.count_spin.setValue(1)
        self.count_spin.setEnabled(False)
        self.description_edit.setPlainText(endpoint.description)

    def save_item(self) -> None:
        endpoint_type = self.type_combo.currentText().strip()
        location = self.location_edit.text().strip()
        description = self.description_edit.toPlainText().strip()
        name = self.name_edit.text().strip()
        if not name:
            name = self.generated_name(endpoint_type)
        if endpoint_type and endpoint_type not in self.window.project.settings.endpoint_types:
            self.window.project.settings.endpoint_types.append(endpoint_type)

        endpoint = self.find_current()
        if endpoint is not None:
            endpoint.name = name
            endpoint.endpoint_type = endpoint_type
            endpoint.location = location
            endpoint.description = description
            self.after_existing_saved(name)
        else:
            created_names = make_sequence(name, self.count_spin.value())
            for item_name in created_names:
                self.window.project.endpoints.append(
                    Endpoint(
                        name=item_name,
                        endpoint_type=endpoint_type,
                        location=location,
                        description=description,
                    )
                )
            self.after_new_saved(name, self.count_spin.value())
        self.window.refresh_all()

    def after_new_saved(self, name: str, count: int) -> None:
        self.current_id = None
        self.name_edit.setText(next_name_after_sequence(name, count))
        self.count_spin.setValue(1)
        self.count_spin.setEnabled(True)
        self.description_edit.clear()
        self.table.clearSelection()

    def after_existing_saved(self, name: str) -> None:
        self.current_id = None
        self.name_edit.setText(next_name_after_sequence(name, 1))
        self.count_spin.setEnabled(True)
        self.description_edit.clear()
        self.table.clearSelection()

    def delete_item(self) -> None:
        endpoint = self.find_current()
        if endpoint is None:
            return
        used = any(
            connection.source_id == endpoint.id or connection.destination_id == endpoint.id
            for connection in self.window.project.connections
        )
        if used:
            QMessageBox.warning(self, "Nie można usunąć", "Ten punkt jest użyty w połączeniach.")
            return
        self.window.project.endpoints.remove(endpoint)
        self.clear_form()
        self.window.refresh_all()

    def find_current(self) -> Endpoint | None:
        if self.current_id is None:
            return None
        return self.window.project.find_endpoint(self.current_id)

    def generated_name(self, endpoint_type: str) -> str:
        prefix = resolve_name_rule(self.window.project.settings.endpoint_name_rules, endpoint_type, endpoint_type.upper()[:3])
        return next_name_for_prefix(prefix, [endpoint.name for endpoint in self.window.project.endpoints])
