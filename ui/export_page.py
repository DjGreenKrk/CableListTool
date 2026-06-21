from __future__ import annotations

from PySide6.QtWidgets import QLabel, QPushButton, QVBoxLayout, QWidget

from naming import generate_labels


class ExportPage(QWidget):
    def __init__(self, window) -> None:
        super().__init__()
        self.window = window
        self.summary_label = QLabel()
        self.export_button = QPushButton("Eksport XLSX")
        self.export_button.clicked.connect(self.window.export_xlsx)

        layout = QVBoxLayout(self)
        layout.addWidget(self.summary_label)
        layout.addWidget(self.export_button)
        layout.addStretch()

    def refresh(self) -> None:
        labels = generate_labels(self.window.project)
        self.summary_label.setText(
            "\n".join(
                [
                    f"Projekt: {self.window.project.name or '-'}",
                    f"Szafy: {len(self.window.project.cabinets)}",
                    f"Punkty: {len(self.window.project.endpoints)}",
                    f"Połączenia: {len(self.window.project.connections)}",
                    f"Wiersze eksportu: {len(labels)}",
                ]
            )
        )

