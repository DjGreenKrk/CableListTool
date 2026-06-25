APP_STYLESHEET = """
QMainWindow, QWidget {
    background: #07111a;
    color: #eef8ff;
    font-family: Segoe UI;
    font-size: 10pt;
}

QMenuBar, QMenu {
    background: #0d1a24;
    color: #eef8ff;
}

QMenuBar::item:selected, QMenu::item:selected {
    background: #2b5c79;
}

QTabWidget::pane {
    border: 1px solid #1f3443;
}

QTabBar::tab {
    background: #0d1a24;
    color: #eef8ff;
    border: 1px solid #1f3443;
    padding: 8px 14px;
}

QTabBar::tab:selected {
    background: #2b5c79;
}

QTableWidget {
    background: #0d1a24;
    alternate-background-color: #102331;
    color: #eef8ff;
    gridline-color: #1f3443;
    selection-background-color: #2b5c79;
    selection-color: #eef8ff;
    border: 1px solid #1f3443;
}

QHeaderView::section {
    background: #0d1a24;
    color: #eef8ff;
    border: 1px solid #1f3443;
    padding: 5px;
}

QLineEdit, QTextEdit, QPlainTextEdit, QComboBox, QSpinBox {
    background: #0d1a24;
    color: #eef8ff;
    border: 1px solid #1f3443;
    padding: 5px;
}

QPushButton {
    background: #153144;
    color: #eef8ff;
    border: 1px solid #2b5c79;
    padding: 7px 10px;
}

QPushButton:hover {
    background: #2b5c79;
}

QLabel {
    color: #eef8ff;
}
"""

