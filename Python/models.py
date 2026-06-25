from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any
from uuid import uuid4


SCHEMA_VERSION = 1

DEFAULT_CABINET_TYPES = [
    "Szafa sterująca",
    "Rack",
    "Szafa elektryczna",
    "Inne",
]

DEFAULT_ENDPOINT_TYPES = [
    "Floorbox",
    "Przyłącze",
    "Urządzenie",
    "Oprawa",
    "Panel",
    "Projektor",
    "Przycisk",
    "Inne",
]

DEFAULT_SIGNAL_TYPES = [
    "ETH",
    "DMX",
    "DALI",
    "230V",
    "AUDIO",
    "HDMI",
    "USB",
    "CTRL",
    "INNE",
]

DEFAULT_STATUSES = [
    "Do sprawdzenia",
    "Potwierdzone",
    "Niezgodność",
    "Brak kabla",
    "Niezidentyfikowany",
]

DEFAULT_CABINET_NAME_RULES = {
    "Szafa sterująca": "RSC-N",
    "Rack": "RACK-N",
    "Szafa elektryczna": "EL-N",
}

DEFAULT_ENDPOINT_NAME_RULES = {
    "Floorbox": "FB-NN",
    "Przyłącze": "WB-N",
    "Urządzenie": "DEV-N",
    "Oprawa": "OP-N",
    "Panel": "TSC-N",
    "Projektor": "PROJ-N",
    "Przycisk": "BTN-N",
}


def new_id() -> str:
    return str(uuid4())


@dataclass
class Cabinet:
    name: str = ""
    cabinet_type: str = DEFAULT_CABINET_TYPES[0]
    location: str = ""
    description: str = ""
    priority: int = 0
    id: str = field(default_factory=new_id)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Cabinet":
        return cls(
            id=str(data.get("id") or new_id()),
            name=str(data.get("name", "")),
            cabinet_type=str(data.get("cabinet_type", data.get("type", DEFAULT_CABINET_TYPES[0]))),
            location=str(data.get("location", "")),
            description=str(data.get("description", "")),
            priority=int(data.get("priority", 0) or 0),
        )

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "cabinet_type": self.cabinet_type,
            "location": self.location,
            "description": self.description,
            "priority": self.priority,
        }


@dataclass
class Endpoint:
    name: str = ""
    endpoint_type: str = DEFAULT_ENDPOINT_TYPES[0]
    location: str = ""
    description: str = ""
    id: str = field(default_factory=new_id)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Endpoint":
        return cls(
            id=str(data.get("id") or new_id()),
            name=str(data.get("name", "")),
            endpoint_type=str(data.get("endpoint_type", data.get("type", DEFAULT_ENDPOINT_TYPES[0]))),
            location=str(data.get("location", "")),
            description=str(data.get("description", "")),
        )

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "endpoint_type": self.endpoint_type,
            "location": self.location,
            "description": self.description,
        }


@dataclass
class Connection:
    source_id: str = ""
    destination_id: str = ""
    signal_type: str = DEFAULT_SIGNAL_TYPES[0]
    quantity: int = 1
    status: str = DEFAULT_STATUSES[0]
    cable_number: int | None = None
    cable_statuses: dict[str, str] = field(default_factory=dict)
    notes: str = ""
    id: str = field(default_factory=new_id)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Connection":
        quantity = int(data.get("quantity", 1) or 1)
        return cls(
            id=str(data.get("id") or new_id()),
            source_id=str(data.get("source_id", "")),
            destination_id=str(data.get("destination_id", "")),
            signal_type=str(data.get("signal_type", DEFAULT_SIGNAL_TYPES[0])),
            quantity=max(1, quantity),
            status=str(data.get("status", DEFAULT_STATUSES[0])),
            cable_number=clean_optional_int(data.get("cable_number")),
            cable_statuses=clean_status_map(data.get("cable_statuses", {})),
            notes=str(data.get("notes", "")),
        )

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "source_id": self.source_id,
            "destination_id": self.destination_id,
            "signal_type": self.signal_type,
            "quantity": 1,
            "status": self.status,
            "cable_number": self.cable_number,
            "cable_statuses": {},
            "notes": self.notes,
        }


@dataclass
class Settings:
    cabinet_types: list[str] = field(default_factory=lambda: DEFAULT_CABINET_TYPES.copy())
    cabinet_name_rules: dict[str, str] = field(default_factory=lambda: DEFAULT_CABINET_NAME_RULES.copy())
    endpoint_types: list[str] = field(default_factory=lambda: DEFAULT_ENDPOINT_TYPES.copy())
    endpoint_name_rules: dict[str, str] = field(default_factory=lambda: DEFAULT_ENDPOINT_NAME_RULES.copy())
    endpoint_type_priorities: dict[str, int] = field(default_factory=dict)
    signal_types: list[str] = field(default_factory=lambda: DEFAULT_SIGNAL_TYPES.copy())
    signal_type_export_names: dict[str, str] = field(default_factory=dict)
    signal_type_priorities: dict[str, int] = field(default_factory=dict)
    statuses: list[str] = field(default_factory=lambda: DEFAULT_STATUSES.copy())

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Settings":
        return cls(
            cabinet_types=clean_list(data.get("cabinet_types"), DEFAULT_CABINET_TYPES),
            cabinet_name_rules=clean_str_map(data.get("cabinet_name_rules"), DEFAULT_CABINET_NAME_RULES),
            endpoint_types=clean_list(data.get("endpoint_types"), DEFAULT_ENDPOINT_TYPES),
            endpoint_name_rules=clean_str_map(data.get("endpoint_name_rules"), DEFAULT_ENDPOINT_NAME_RULES),
            endpoint_type_priorities=clean_int_map(data.get("endpoint_type_priorities", {})),
            signal_types=clean_list(data.get("signal_types"), DEFAULT_SIGNAL_TYPES),
            signal_type_export_names=clean_str_map(
                data.get("signal_type_export_names", data.get("signal_type_descriptions", {})),
                {},
            ),
            signal_type_priorities=clean_int_map(data.get("signal_type_priorities", {})),
            statuses=clean_list(data.get("statuses"), DEFAULT_STATUSES),
        )

    def to_dict(self) -> dict[str, Any]:
        return {
            "cabinet_types": self.cabinet_types,
            "cabinet_name_rules": self.cabinet_name_rules,
            "endpoint_types": self.endpoint_types,
            "endpoint_name_rules": self.endpoint_name_rules,
            "endpoint_type_priorities": self.endpoint_type_priorities,
            "signal_types": self.signal_types,
            "signal_type_export_names": self.signal_type_export_names,
            "signal_type_priorities": self.signal_type_priorities,
            "statuses": self.statuses,
        }


@dataclass
class Project:
    name: str = ""
    code: str = ""
    cabinets: list[Cabinet] = field(default_factory=list)
    endpoints: list[Endpoint] = field(default_factory=list)
    connections: list[Connection] = field(default_factory=list)
    settings: Settings = field(default_factory=Settings)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Project":
        project_data = data.get("project", data)
        project = cls(
            name=str(project_data.get("name", "")),
            code=str(project_data.get("code", "")),
            cabinets=[Cabinet.from_dict(item) for item in data.get("cabinets", [])],
            endpoints=[Endpoint.from_dict(item) for item in data.get("endpoints", [])],
            connections=[Connection.from_dict(item) for item in data.get("connections", [])],
            settings=Settings.from_dict(data.get("settings", {})),
        )
        project.expand_connection_quantities()
        return project

    def to_dict(self) -> dict[str, Any]:
        return {
            "schema_version": SCHEMA_VERSION,
            "project": {
                "name": self.name,
                "code": self.code,
            },
            "cabinets": [item.to_dict() for item in self.cabinets],
            "endpoints": [item.to_dict() for item in self.endpoints],
            "connections": [item.to_dict() for item in self.connections],
            "settings": self.settings.to_dict(),
        }

    def all_objects(self) -> list[tuple[str, str, str]]:
        objects: list[tuple[str, str, str]] = []
        objects.extend((item.id, item.name, "Cabinet") for item in self.cabinets)
        objects.extend((item.id, item.name, "Endpoint") for item in self.endpoints)
        return objects

    def object_name(self, object_id: str) -> str:
        for item in self.cabinets:
            if item.id == object_id:
                return item.name
        for item in self.endpoints:
            if item.id == object_id:
                return item.name
        return ""

    def find_cabinet(self, cabinet_id: str) -> Cabinet | None:
        return next((item for item in self.cabinets if item.id == cabinet_id), None)

    def find_endpoint(self, endpoint_id: str) -> Endpoint | None:
        return next((item for item in self.endpoints if item.id == endpoint_id), None)

    def expand_connection_quantities(self) -> None:
        expanded: list[Connection] = []
        for connection in self.connections:
            quantity = max(1, connection.quantity)
            if quantity == 1:
                connection.quantity = 1
                connection.cable_statuses = {}
                expanded.append(connection)
                continue
            for index in range(1, quantity + 1):
                expanded.append(
                    Connection(
                        id=connection.id if index == 1 else new_id(),
                        source_id=connection.source_id,
                        destination_id=connection.destination_id,
                        signal_type=connection.signal_type,
                        quantity=1,
                        status=connection.cable_statuses.get(str(index), connection.status),
                        cable_number=connection.cable_number if quantity == 1 else None,
                        notes=connection.notes,
                    )
                )
        self.connections = expanded


def clean_list(value: Any, defaults: list[str]) -> list[str]:
    if not isinstance(value, list):
        return defaults.copy()
    items = [str(item).strip() for item in value if str(item).strip()]
    return items or defaults.copy()


def clean_status_map(value: Any) -> dict[str, str]:
    if not isinstance(value, dict):
        return {}
    result: dict[str, str] = {}
    for key, status in value.items():
        key_text = str(key).strip()
        status_text = str(status).strip()
        if key_text and status_text:
            result[key_text] = status_text
    return result


def clean_optional_int(value: Any) -> int | None:
    if value in (None, ""):
        return None
    try:
        number = int(value)
    except (TypeError, ValueError):
        return None
    return number if number > 0 else None


def clean_int_map(value: Any) -> dict[str, int]:
    if not isinstance(value, dict):
        return {}
    result: dict[str, int] = {}
    for key, number in value.items():
        key_text = str(key).strip()
        clean_number = clean_optional_int(number)
        if key_text and clean_number is not None:
            result[key_text] = clean_number
    return result


def clean_str_map(value: Any, defaults: dict[str, str]) -> dict[str, str]:
    if not isinstance(value, dict):
        return defaults.copy()
    result: dict[str, str] = {}
    for key, text in value.items():
        key_text = str(key).strip()
        value_text = str(text).strip()
        if key_text and value_text:
            result[key_text] = value_text
    return result
