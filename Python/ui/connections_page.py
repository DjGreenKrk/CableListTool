from __future__ import annotations

from PySide6.QtWidgets import (
    QAbstractItemView,
    QComboBox,
    QFormLayout,
    QHBoxLayout,
    QMessageBox,
    QPushButton,
    QSpinBox,
    QTableWidget,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)

from models import Connection
from naming import generate_labels
from ui.helpers import fill_combo, item, natural_sort_key, set_table_headers

UNKNOWN_DESTINATION_LABEL = "Nieznane"
UNKNOWN_DESTINATION_STATUS = "Niezidentyfikowany"
DEFAULT_FOUND_STATUS = "Do sprawdzenia"


class ConnectionsPage(QWidget):
    def __init__(self, window) -> None:
        super().__init__()
        self.window = window
        self.current_id: str | None = None
        self.row_connection_ids: list[str] = []

        self.table = QTableWidget()
        set_table_headers(self.table, ["Oznaczenie", "Skąd", "Dokąd", "Typ", "Status", "Uwagi"])
        self.table.setSelectionMode(QAbstractItemView.ExtendedSelection)
        self.table.itemSelectionChanged.connect(self.load_selected)

        self.source_combo = QComboBox()
        self.destination_combo = QComboBox()
        self.signal_combo = QComboBox()
        self.signal_combo.setEditable(True)
        self.quantity_spin = QSpinBox()
        self.quantity_spin.setRange(1, 9999)
        self.status_combo = QComboBox()
        self.status_combo.setEditable(True)
        self.notes_edit = QTextEdit()

        self.source_combo.currentIndexChanged.connect(self.refresh_destination_combo)

        form = QFormLayout()
        form.addRow("Skąd", self.source_combo)
        form.addRow("Dokąd", self.destination_combo)
        form.addRow("Typ sygnału", self.signal_combo)
        form.addRow("Ilość nowych", self.quantity_spin)
        form.addRow("Status", self.status_combo)
        form.addRow("Uwagi", self.notes_edit)

        new_button = QPushButton("Nowe")
        save_button = QPushButton("Zapisz")
        delete_button = QPushButton("Usuń")
        reverse_button = QPushButton("Odwróć kierunek")
        merge_button = QPushButton("Połącz przewody")
        new_button.clicked.connect(self.clear_form)
        save_button.clicked.connect(self.save_item)
        delete_button.clicked.connect(self.delete_selected)
        reverse_button.clicked.connect(self.reverse_selected)
        merge_button.clicked.connect(self.merge_selected)

        buttons = QHBoxLayout()
        buttons.addWidget(new_button)
        buttons.addWidget(save_button)
        buttons.addWidget(delete_button)

        tools = QHBoxLayout()
        tools.addWidget(reverse_button)
        tools.addWidget(merge_button)

        right = QVBoxLayout()
        right.addLayout(form)
        right.addLayout(buttons)
        right.addLayout(tools)
        right.addStretch()

        layout = QHBoxLayout(self)
        layout.addWidget(self.table, 3)
        layout.addLayout(right, 1)

    def refresh(self) -> None:
        self.window.project.expand_connection_quantities()
        fill_combo(self.signal_combo, self.window.project.settings.signal_types, self.signal_combo.currentText())
        fill_combo(self.status_combo, self.window.project.settings.statuses, self.status_combo.currentText())
        self.refresh_source_combo()
        self.refresh_destination_combo()
        self.refresh_table()

    def refresh_table(self) -> None:
        labels = generate_labels(self.window.project)
        self.row_connection_ids = [label.connection_id for label in labels]
        self.table.blockSignals(True)
        self.table.setRowCount(len(labels))
        for row, label in enumerate(labels):
            self.table.setItem(row, 0, item(label.designation))
            self.table.setItem(row, 1, item(label.source))
            self.table.setItem(row, 2, item(label.destination))
            self.table.setItem(row, 3, item(label.signal_type))
            self.table.setItem(row, 4, item(label.status))
            self.table.setItem(row, 5, item(label.notes))
        self.table.resizeColumnsToContents()
        self.table.blockSignals(False)

    def refresh_source_combo(self, current_id: str | None = None) -> None:
        if current_id is None:
            current_id = self.combo_id(self.source_combo)
        self.source_combo.blockSignals(True)
        self.source_combo.clear()
        for object_id, name, kind in self.sorted_objects():
            self.source_combo.addItem(f"{name} ({kind})", object_id)
        index = self.index_for_id(self.source_combo, current_id)
        if index >= 0:
            self.source_combo.setCurrentIndex(index)
        self.source_combo.blockSignals(False)

    def refresh_destination_combo(self, current_id: str | None = None) -> None:
        if current_id is None:
            current_id = self.combo_id(self.destination_combo)
        source_id = self.combo_id(self.source_combo)
        self.destination_combo.blockSignals(True)
        self.destination_combo.clear()
        self.destination_combo.addItem(UNKNOWN_DESTINATION_LABEL, "")
        for object_id, name, kind in self.sorted_objects():
            if object_id == source_id:
                continue
            self.destination_combo.addItem(f"{name} ({kind})", object_id)
        index = self.index_for_id(self.destination_combo, current_id)
        self.destination_combo.setCurrentIndex(index if index >= 0 else 0)
        self.destination_combo.blockSignals(False)

    def clear_form(self) -> None:
        self.current_id = None
        self.refresh_source_combo()
        self.refresh_destination_combo("")
        fill_combo(self.signal_combo, self.window.project.settings.signal_types)
        self.quantity_spin.setValue(1)
        self.quantity_spin.setEnabled(True)
        fill_combo(self.status_combo, self.window.project.settings.statuses)
        self.notes_edit.clear()
        self.table.clearSelection()

    def load_selected(self) -> None:
        ids = self.selected_connection_ids()
        if len(ids) != 1:
            self.current_id = None
            self.quantity_spin.setEnabled(True)
            return
        connection = self.find_connection(ids[0])
        if connection is None:
            return
        self.current_id = connection.id
        self.refresh_source_combo(connection.source_id)
        self.refresh_destination_combo(connection.destination_id)
        fill_combo(self.signal_combo, self.window.project.settings.signal_types, connection.signal_type)
        self.quantity_spin.setValue(1)
        self.quantity_spin.setEnabled(False)
        fill_combo(self.status_combo, self.window.project.settings.statuses, connection.status)
        self.notes_edit.setPlainText(connection.notes)

    def save_item(self) -> None:
        source_id = self.combo_id(self.source_combo)
        destination_id = self.combo_id(self.destination_combo)
        if not source_id:
            QMessageBox.warning(self, "Brak źródła", "Wybierz źródło połączenia.")
            return
        if destination_id and source_id == destination_id:
            QMessageBox.warning(self, "Błędne połączenie", "Źródło i cel nie mogą być tym samym obiektem.")
            return

        signal_type = self.signal_combo.currentText().strip()
        status = self.status_combo.currentText().strip()
        if not destination_id:
            status = UNKNOWN_DESTINATION_STATUS
        notes = self.notes_edit.toPlainText().strip()
        self.ensure_dictionary_values(signal_type, status)

        existing = self.find_connection(self.current_id) if self.current_id else None
        if existing is not None:
            existing.source_id = source_id
            existing.destination_id = destination_id
            existing.signal_type = signal_type
            existing.quantity = 1
            existing.status = status
            existing.notes = notes
        else:
            for _ in range(self.quantity_spin.value()):
                self.window.project.connections.append(
                    Connection(
                        source_id=source_id,
                        destination_id=destination_id,
                        signal_type=signal_type,
                        quantity=1,
                        status=status,
                        notes=notes,
                    )
                )
        self.window.refresh_all()

    def delete_selected(self) -> None:
        ids = set(self.selected_connection_ids())
        if not ids:
            return
        self.window.project.connections = [
            connection for connection in self.window.project.connections if connection.id not in ids
        ]
        self.current_id = None
        self.window.refresh_all()

    def reverse_selected(self) -> None:
        changed = 0
        for connection_id in self.selected_connection_ids():
            connection = self.find_connection(connection_id)
            if connection is None or not connection.destination_id:
                continue
            connection.source_id, connection.destination_id = connection.destination_id, connection.source_id
            changed += 1
        if changed == 0:
            QMessageBox.information(self, "Odwróć kierunek", "Wybierz przewód ze znanym początkiem i końcem.")
            return
        self.window.refresh_all()

    def merge_selected(self) -> None:
        generate_labels(self.window.project)
        ids = self.selected_connection_ids()
        if len(ids) != 2:
            QMessageBox.warning(self, "Połącz przewody", "Wybierz dokładnie dwa niezidentyfikowane przewody.")
            return
        first = self.find_connection(ids[0])
        second = self.find_connection(ids[1])
        if first is None or second is None:
            return
        if first.signal_type != second.signal_type:
            QMessageBox.warning(self, "Połącz przewody", "Przewody muszą mieć ten sam typ sygnału.")
            return
        if first.destination_id or second.destination_id:
            QMessageBox.warning(self, "Połącz przewody", "Na razie łączenie działa dla dwóch przewodów z końcem `Nieznane`.")
            return
        if first.source_id == second.source_id:
            QMessageBox.warning(self, "Połącz przewody", "Wybrane przewody mają ten sam punkt początkowy.")
            return

        keeper, removed = self.merge_order(first, second)
        keeper.destination_id = removed.source_id
        keeper.quantity = 1
        keeper.status = DEFAULT_FOUND_STATUS
        keeper.notes = merge_notes(keeper.notes, removed.notes)
        self.window.project.connections.remove(removed)
        self.current_id = keeper.id
        self.window.refresh_all()

    def merge_order(self, first: Connection, second: Connection) -> tuple[Connection, Connection]:
        first_rank = self.connection_cabinet_rank(first)
        second_rank = self.connection_cabinet_rank(second)
        if first_rank is None and second_rank is None:
            return first, second
        if first_rank is None:
            return second, first
        if second_rank is None:
            return first, second
        return (first, second) if first_rank <= second_rank else (second, first)

    def connection_cabinet_rank(self, connection: Connection) -> tuple[int, str] | None:
        cabinets = []
        for object_id in (connection.source_id, connection.destination_id):
            cabinet = self.window.project.find_cabinet(object_id)
            if cabinet is not None:
                cabinets.append(cabinet)
        if not cabinets:
            return None
        cabinet = min(cabinets, key=lambda item: (item.priority or 999_999, item.name.lower()))
        return (cabinet.priority or 999_999, cabinet.name.lower())

    def selected_connection_ids(self) -> list[str]:
        rows = sorted({index.row() for index in self.table.selectedIndexes()})
        return [self.row_connection_ids[row] for row in rows if row < len(self.row_connection_ids)]

    def find_connection(self, connection_id: str | None) -> Connection | None:
        if connection_id is None:
            return None
        return next((item for item in self.window.project.connections if item.id == connection_id), None)

    def ensure_dictionary_values(self, signal_type: str, status: str) -> None:
        if signal_type and signal_type not in self.window.project.settings.signal_types:
            self.window.project.settings.signal_types.append(signal_type)
        if status and status not in self.window.project.settings.statuses:
            self.window.project.settings.statuses.append(status)

    def combo_id(self, combo: QComboBox) -> str:
        value = combo.currentData()
        return "" if value is None else str(value)

    def index_for_id(self, combo: QComboBox, object_id: str) -> int:
        for index in range(combo.count()):
            if combo.itemData(index) == object_id:
                return index
        return -1

    def sorted_objects(self) -> list[tuple[str, str, str]]:
        kind_order = {"Cabinet": 0, "Endpoint": 1}
        priorities = self.window.project.settings.endpoint_type_priorities

        def endpoint_type_priority(row: tuple[str, str, str]) -> int:
            if row[2] != "Endpoint":
                return 0
            endpoint = self.window.project.find_endpoint(row[0])
            if endpoint is None:
                return 999_999
            return priorities.get(endpoint.endpoint_type, 999_999)

        return sorted(
            self.window.project.all_objects(),
            key=lambda row: (kind_order.get(row[2], 99), endpoint_type_priority(row), natural_sort_key(row[1])),
        )


def merge_notes(first: str, second: str) -> str:
    notes = [note for note in (first.strip(), second.strip()) if note]
    if not notes:
        return ""
    return " | ".join(notes)
