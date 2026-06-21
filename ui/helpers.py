from __future__ import annotations

import re

from PySide6.QtWidgets import QComboBox, QTableWidget, QTableWidgetItem


def set_table_headers(table: QTableWidget, headers: list[str]) -> None:
    table.setColumnCount(len(headers))
    table.setHorizontalHeaderLabels(headers)
    table.setAlternatingRowColors(True)
    table.setSelectionBehavior(QTableWidget.SelectRows)
    table.setSelectionMode(QTableWidget.SingleSelection)


def fill_combo(combo: QComboBox, values: list[str], current: str = "") -> None:
    combo.blockSignals(True)
    combo.clear()
    combo.addItems(values)
    if current:
        index = combo.findText(current)
        if index < 0 and combo.isEditable():
            combo.addItem(current)
            index = combo.findText(current)
        if index >= 0:
            combo.setCurrentIndex(index)
    combo.blockSignals(False)


def item(text: object) -> QTableWidgetItem:
    return QTableWidgetItem("" if text is None else str(text))


def lines_to_list(text: str) -> list[str]:
    return [line.strip() for line in text.splitlines() if line.strip()]


def natural_sort_key(value: object) -> list[object]:
    parts = re.split(r"(\d+)", str(value).lower())
    return [int(part) if part.isdigit() else part for part in parts]
