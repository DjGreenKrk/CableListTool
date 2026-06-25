from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any

from models import Cabinet, Connection, Endpoint, Project

UNKNOWN_DESTINATION_NAME = "Nieznane"
UNKNOWN_DESTINATION_TOKEN = "NIEZNANE"


@dataclass(frozen=True)
class CableLabel:
    connection_id: str
    cable_index: int
    designation: str
    project: str
    source: str
    destination: str
    signal_type: str
    export_signal_type: str
    port_label: str
    number: str
    status: str
    notes: str


def sanitize_token(value: str) -> str:
    return re.sub(r"[-\s]+", "", value.strip())


def natural_number(value: str) -> int:
    match = re.search(r"\d+", value)
    if not match:
        return 999_999
    return int(match.group(0))


def natural_key(value: str) -> tuple[object, ...]:
    parts = re.split(r"(\d+)", value.lower())
    return tuple(int(part) if part.isdigit() else part for part in parts)


def auto_assign_cabinet_priorities(project: Project) -> None:
    sorted_cabinets = sorted(project.cabinets, key=lambda item: (natural_number(item.name), natural_key(item.name)))
    for index, cabinet in enumerate(sorted_cabinets, start=1):
        cabinet.priority = index


def generate_labels(project: Project) -> list[CableLabel]:
    ensure_cabinet_cable_numbers(project)
    labels: list[CableLabel] = []
    connections_by_type: dict[str, list[Connection]] = {}
    for connection in project.connections:
        connections_by_type.setdefault(connection.signal_type, []).append(connection)

    for signal_type in sorted(connections_by_type, key=lambda item: signal_type_sort_key(project, item)):
        connections = sorted(connections_by_type[signal_type], key=lambda item: connection_sort_key(project, item))
        max_fixed = max((item.cable_number or 0 for item in connections), default=0)
        total = sum(max(1, item.quantity) for item in connections)
        width = max(2, len(str(max(total, max_fixed))))
        counter = 1
        for connection in connections:
            for cable_index in range(1, max(1, connection.quantity) + 1):
                if connection.cable_number:
                    numeric_number = connection.cable_number
                else:
                    while number_is_used(connections, counter):
                        counter += 1
                    numeric_number = counter
                number = str(numeric_number).zfill(width)
                source = object_name(project, connection.source_id)
                destination = object_name(project, connection.destination_id, UNKNOWN_DESTINATION_NAME)
                status = connection.cable_statuses.get(str(cable_index), connection.status)
                destination_token = UNKNOWN_DESTINATION_TOKEN if not connection.destination_id else sanitize_token(destination)
                export_signal_type = signal_type_export_name(project, connection.signal_type)
                port_label = f"{sanitize_token(export_signal_type)}-{number}"
                designation = "-".join(
                    [
                        sanitize_token(project.code),
                        sanitize_token(source),
                        destination_token,
                        port_label,
                    ]
                )
                labels.append(
                    CableLabel(
                        connection_id=connection.id,
                        cable_index=cable_index,
                        designation=designation,
                        project=project.name,
                        source=source,
                        destination=destination,
                        signal_type=connection.signal_type,
                        export_signal_type=export_signal_type,
                        port_label=port_label,
                        number=number,
                        status=status,
                        notes=connection.notes,
                    )
                )
                counter = max(counter, numeric_number + 1)
    return labels


def ensure_cabinet_cable_numbers(project: Project) -> None:
    connections_by_type: dict[str, list[Connection]] = {}
    for connection in project.connections:
        if cabinets_for_connection(project, connection):
            connections_by_type.setdefault(connection.signal_type, []).append(connection)

    for connections in connections_by_type.values():
        used = {connection.cable_number for connection in connections if connection.cable_number}
        next_number = 1
        for connection in sorted(connections, key=lambda item: connection_sort_key(project, item)):
            if connection.cable_number:
                continue
            while next_number in used:
                next_number += 1
            connection.cable_number = next_number
            used.add(next_number)


def number_is_used(connections: list[Connection], number: int) -> bool:
    return any(connection.cable_number == number for connection in connections)


def labels_for_connection(project: Project, connection_id: str) -> list[CableLabel]:
    return [label for label in generate_labels(project) if label.connection_id == connection_id]


def connection_sort_key(project: Project, connection: Connection) -> tuple[Any, ...]:
    cabinets = cabinets_for_connection(project, connection)
    if cabinets:
        best_priority = min(cabinet.priority or natural_number(cabinet.name) for cabinet in cabinets)
        best_name = min(natural_key(cabinet.name) for cabinet in cabinets)
        return (
            0,
            best_priority,
            best_name,
            connection.cable_number or 999_999,
            endpoint_priority_key(project, connection),
            endpoint_key(project, connection),
            connection.id,
        )

    return (1, 999_999, endpoint_priority_key(project, connection), endpoint_key(project, connection), "", connection.id)


def cabinets_for_connection(project: Project, connection: Connection) -> list[Cabinet]:
    result = []
    for object_id in (connection.source_id, connection.destination_id):
        cabinet = project.find_cabinet(object_id)
        if cabinet is not None:
            result.append(cabinet)
    return result


def endpoints_for_connection(project: Project, connection: Connection) -> list[Endpoint]:
    result = []
    for object_id in (connection.source_id, connection.destination_id):
        endpoint = project.find_endpoint(object_id)
        if endpoint is not None:
            result.append(endpoint)
    return result


def endpoint_key(project: Project, connection: Connection) -> tuple[object, ...]:
    endpoints = endpoints_for_connection(project, connection)
    if endpoints:
        return min(natural_key(endpoint.name) for endpoint in endpoints)
    names = [object_name(project, connection.source_id), object_name(project, connection.destination_id)]
    names = [natural_key(name) for name in names if name]
    return min(names) if names else tuple()


def endpoint_priority_key(project: Project, connection: Connection) -> int:
    endpoints = endpoints_for_connection(project, connection)
    if not endpoints:
        return 999_999
    return min(project.settings.endpoint_type_priorities.get(endpoint.endpoint_type, 999_999) for endpoint in endpoints)


def signal_type_sort_key(project: Project, signal_type: str) -> tuple[int, tuple[object, ...]]:
    priority = project.settings.signal_type_priorities.get(signal_type, 999_999)
    return priority, natural_key(signal_type)


def signal_type_export_name(project: Project, signal_type: str) -> str:
    return project.settings.signal_type_export_names.get(signal_type, signal_type)


def object_name(project: Project, object_id: str, missing: str = "") -> str:
    if not object_id:
        return missing
    cabinet = project.find_cabinet(object_id)
    if cabinet is not None:
        return cabinet.name
    endpoint = project.find_endpoint(object_id)
    if endpoint is not None:
        return endpoint.name
    return missing
