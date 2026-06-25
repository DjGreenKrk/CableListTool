from __future__ import annotations

import re
from pathlib import Path

from PySide6.QtGui import QIcon
from PySide6.QtWidgets import (
    QFileDialog,
    QMainWindow,
    QMessageBox,
    QTabWidget,
)

from app_metadata import APP_NAME, APP_VERSION
from app_resources import resource_path
from export_xlsx import export_project_to_xlsx
from models import Project
from storage import load_project, save_project
from ui.cabinets_page import CabinetsPage
from ui.connections_page import ConnectionsPage
from ui.endpoints_page import EndpointsPage
from ui.export_page import ExportPage
from ui.project_page import ProjectPage
from ui.theme import APP_STYLESHEET


class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.project = Project(name="Nowy projekt", code="PRJ")
        self.current_path: Path | None = None

        self.setWindowTitle(f"{APP_NAME} {APP_VERSION}")
        self.setWindowIcon(QIcon(str(resource_path("resources/CableListTool.ico"))))
        self.resize(1180, 760)
        self.setStyleSheet(APP_STYLESHEET)

        self.tabs = QTabWidget()
        self.setCentralWidget(self.tabs)

        self.project_page = ProjectPage(self)
        self.cabinets_page = CabinetsPage(self)
        self.endpoints_page = EndpointsPage(self)
        self.connections_page = ConnectionsPage(self)
        self.export_page = ExportPage(self)

        self.tabs.addTab(self.project_page, "Projekt")
        self.tabs.addTab(self.cabinets_page, "Szafy")
        self.tabs.addTab(self.endpoints_page, "Punkty")
        self.tabs.addTab(self.connections_page, "Połączenia")
        self.tabs.addTab(self.export_page, "Export")

        self.create_menu()
        self.refresh_all()

    def create_menu(self) -> None:
        file_menu = self.menuBar().addMenu("Plik")

        new_action = file_menu.addAction("Nowy projekt")
        new_action.triggered.connect(self.new_project)

        open_action = file_menu.addAction("Otwórz...")
        open_action.triggered.connect(self.open_project)

        save_action = file_menu.addAction("Zapisz")
        save_action.triggered.connect(self.save_current_project)

        save_as_action = file_menu.addAction("Zapisz jako...")
        save_as_action.triggered.connect(self.save_project_as)

        file_menu.addSeparator()

        export_action = file_menu.addAction("Eksport XLSX...")
        export_action.triggered.connect(self.export_xlsx)

        file_menu.addSeparator()

        exit_action = file_menu.addAction("Zamknij")
        exit_action.triggered.connect(self.close)

    def refresh_all(self) -> None:
        for page in (
            self.project_page,
            self.cabinets_page,
            self.endpoints_page,
            self.connections_page,
            self.export_page,
        ):
            page.refresh()
        self.update_title()

    def update_title(self) -> None:
        suffix = f" - {self.current_path}" if self.current_path else ""
        self.setWindowTitle(f"{APP_NAME} {APP_VERSION}{suffix}")

    def new_project(self) -> None:
        self.project = Project(name="Nowy projekt", code="PRJ")
        self.current_path = None
        self.refresh_all()

    def open_project(self) -> None:
        path, _ = QFileDialog.getOpenFileName(self, "Otwórz projekt", "", "Projekt JSON (*.json)")
        if not path:
            return
        try:
            self.project = load_project(path)
        except Exception as error:
            QMessageBox.critical(self, "Błąd odczytu", str(error))
            return
        self.current_path = Path(path)
        self.refresh_all()

    def save_current_project(self) -> None:
        if self.current_path is None:
            self.save_project_as()
            return
        try:
            save_project(self.project, self.current_path)
        except Exception as error:
            QMessageBox.critical(self, "Błąd zapisu", str(error))
            return
        QMessageBox.information(self, "Zapis", "Projekt zapisany.")

    def save_project_as(self) -> None:
        path, _ = QFileDialog.getSaveFileName(self, "Zapisz projekt", "", "Projekt JSON (*.json)")
        if not path:
            return
        if not path.lower().endswith(".json"):
            path += ".json"
        self.current_path = Path(path)
        self.save_current_project()

    def export_xlsx(self) -> None:
        suggested = self.suggested_export_name()
        path, _ = QFileDialog.getSaveFileName(self, "Eksport XLSX", suggested, "Excel (*.xlsx)")
        if not path:
            return
        if not path.lower().endswith(".xlsx"):
            path += ".xlsx"
        target = Path(path)
        if target.exists():
            answer = QMessageBox.question(
                self,
                "Nadpisać plik?",
                f"Plik już istnieje:\n{target}\n\nNadpisać?",
            )
            if answer != QMessageBox.Yes:
                return
        try:
            export_project_to_xlsx(self.project, target)
        except Exception as error:
            QMessageBox.critical(self, "Błąd eksportu", str(error))
            return
        QMessageBox.information(self, "Eksport", f"Wyeksportowano:\n{target}")

    def suggested_export_name(self) -> str:
        base = self.project.name or self.project.code or "Lista_kablowa"
        base = re.sub(r"[^A-Za-z0-9_.-]+", "_", base).strip("_") or "Lista_kablowa"
        return str(Path.cwd() / f"{base}_lista_kablowa.xlsx")
