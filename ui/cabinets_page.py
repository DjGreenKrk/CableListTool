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

from models import Cabinet
from naming import auto_assign_cabinet_priorities
from ui.helpers import fill_combo, item, natural_sort_key, set_table_headers
from ui.name_sequence import make_sequence, next_name_after_sequence, next_name_for_prefix, resolve_name_rule


class CabinetsPage(QWidget):
    def __init__(self, window) -> None:
        super().__init__()
        self.window = window
        self.current_id: str | None = None
        self.row_cabinet_ids: list[str] = []

        self.table = QTableWidget()
        set_table_headers(self.table, ["Nazwa", "Typ", "Lokalizacja", "Priorytet", "Opis"])
        self.table.itemSelectionChanged.connect(self.load_selected)

        self.name_edit = QLineEdit()
        self.type_combo = QComboBox()
        self.type_combo.setEditable(True)
        self.location_edit = QLineEdit()
        self.count_spin = QSpinBox()
        self.count_spin.setRange(1, 9999)
        self.priority_spin = QSpinBox()
        self.priority_spin.setRange(0, 9999)
        self.description_edit = QTextEdit()

        form = QFormLayout()
        form.addRow("Nazwa", self.name_edit)
        form.addRow("Typ", self.type_combo)
        form.addRow("Lokalizacja", self.location_edit)
        form.addRow("Ilość nowych", self.count_spin)
        form.addRow("Priorytet", self.priority_spin)
        form.addRow("Opis", self.description_edit)

        new_button = QPushButton("Nowa")
        save_button = QPushButton("Zapisz")
        delete_button = QPushButton("Usuń")
        auto_button = QPushButton("Przelicz priorytety")
        new_button.clicked.connect(self.clear_form)
        save_button.clicked.connect(self.save_item)
        delete_button.clicked.connect(self.delete_item)
        auto_button.clicked.connect(self.auto_priorities)

        buttons = QHBoxLayout()
        buttons.addWidget(new_button)
        buttons.addWidget(save_button)
        buttons.addWidget(delete_button)
        buttons.addWidget(auto_button)

        right = QVBoxLayout()
        right.addLayout(form)
        right.addLayout(buttons)
        right.addStretch()

        layout = QHBoxLayout(self)
        layout.addWidget(self.table, 2)
        layout.addLayout(right, 1)

    def refresh(self) -> None:
        project = self.window.project
        fill_combo(self.type_combo, project.settings.cabinet_types, self.type_combo.currentText())
        cabinets = sorted(project.cabinets, key=lambda cabinet: natural_sort_key(cabinet.name))
        self.row_cabinet_ids = [cabinet.id for cabinet in cabinets]
        self.table.blockSignals(True)
        self.table.setRowCount(len(cabinets))
        for row, cabinet in enumerate(cabinets):
            self.table.setItem(row, 0, item(cabinet.name))
            self.table.setItem(row, 1, item(cabinet.cabinet_type))
            self.table.setItem(row, 2, item(cabinet.location))
            self.table.setItem(row, 3, item(cabinet.priority))
            self.table.setItem(row, 4, item(cabinet.description))
        self.table.resizeColumnsToContents()
        self.table.blockSignals(False)

    def clear_form(self) -> None:
        self.current_id = None
        self.name_edit.clear()
        fill_combo(self.type_combo, self.window.project.settings.cabinet_types)
        self.location_edit.clear()
        self.count_spin.setValue(1)
        self.count_spin.setEnabled(True)
        self.priority_spin.setValue(0)
        self.description_edit.clear()
        self.table.clearSelection()

    def load_selected(self) -> None:
        row = self.table.currentRow()
        if row < 0 or row >= len(self.row_cabinet_ids):
            return
        cabinet = self.window.project.find_cabinet(self.row_cabinet_ids[row])
        if cabinet is None:
            return
        self.current_id = cabinet.id
        self.name_edit.setText(cabinet.name)
        fill_combo(self.type_combo, self.window.project.settings.cabinet_types, cabinet.cabinet_type)
        self.location_edit.setText(cabinet.location)
        self.count_spin.setValue(1)
        self.count_spin.setEnabled(False)
        self.priority_spin.setValue(cabinet.priority)
        self.description_edit.setPlainText(cabinet.description)

    def save_item(self) -> None:
        cabinet_type = self.type_combo.currentText().strip()
        location = self.location_edit.text().strip()
        priority = self.priority_spin.value()
        description = self.description_edit.toPlainText().strip()
        name = self.name_edit.text().strip()
        if not name:
            name = self.generated_name(cabinet_type)
        if cabinet_type and cabinet_type not in self.window.project.settings.cabinet_types:
            self.window.project.settings.cabinet_types.append(cabinet_type)

        cabinet = self.find_current()
        if cabinet is not None:
            cabinet.name = name
            cabinet.cabinet_type = cabinet_type
            cabinet.location = location
            cabinet.priority = priority
            cabinet.description = description
            self.after_existing_saved(name)
        else:
            created_names = make_sequence(name, self.count_spin.value())
            for offset, item_name in enumerate(created_names):
                self.window.project.cabinets.append(
                    Cabinet(
                        name=item_name,
                        cabinet_type=cabinet_type,
                        location=location,
                        priority=priority + offset if priority else 0,
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
        cabinet = self.find_current()
        if cabinet is None:
            return
        used = any(
            connection.source_id == cabinet.id or connection.destination_id == cabinet.id
            for connection in self.window.project.connections
        )
        if used:
            QMessageBox.warning(self, "Nie można usunąć", "Ta szafa jest użyta w połączeniach.")
            return
        self.window.project.cabinets.remove(cabinet)
        self.clear_form()
        self.window.refresh_all()

    def auto_priorities(self) -> None:
        auto_assign_cabinet_priorities(self.window.project)
        self.window.refresh_all()

    def find_current(self) -> Cabinet | None:
        if self.current_id is None:
            return None
        return self.window.project.find_cabinet(self.current_id)

    def generated_name(self, cabinet_type: str) -> str:
        prefix = resolve_name_rule(self.window.project.settings.cabinet_name_rules, cabinet_type, cabinet_type.upper()[:3])
        return next_name_for_prefix(prefix, [cabinet.name for cabinet in self.window.project.cabinets])
