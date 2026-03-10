import json
from typing import Optional
from fastapi import WebSocket


class SalaManager:
    """
    Gestiona conexiones WebSocket activas por sala en memoria.

    Estructura interna:
        salas[id_sala][id_jugador_partida] = {
            "ws": WebSocket,
            "nombre": str,
            "conectado": bool,
        }
    """

    def __init__(self):
        self.salas: dict[int, dict[int, dict]] = {}

    async def conectar(
        self, id_sala: int, id_jugador_partida: int, nombre: str, ws: WebSocket
    ) -> None:
        if id_sala not in self.salas:
            self.salas[id_sala] = {}
        # Si ya existía la clave (reconexión), reutilizamos el slot
        self.salas[id_sala][id_jugador_partida] = {
            "ws": ws,
            "nombre": nombre,
            "conectado": True,
        }

    def desconectar(self, id_sala: int, id_jugador_partida: int) -> None:
        if id_sala in self.salas and id_jugador_partida in self.salas[id_sala]:
            self.salas[id_sala][id_jugador_partida]["conectado"] = False

    def limpiar_sala(self, id_sala: int) -> None:
        self.salas.pop(id_sala, None)

    def jugadores_conectados(self, id_sala: int) -> int:
        return sum(
            1 for info in self.salas.get(id_sala, {}).values() if info["conectado"]
        )

    def nombre_jugador(self, id_sala: int, id_jugador_partida: int) -> str:
        info = self.salas.get(id_sala, {}).get(id_jugador_partida, {})
        return info.get("nombre", "Desconocido")

    async def broadcast(
        self, id_sala: int, mensaje: dict, excluir: Optional[int] = None
    ) -> None:
        """Envía a todos los jugadores conectados en la sala, opcionalmente excluyendo uno."""
        for jp_id, info in list(self.salas.get(id_sala, {}).items()):
            if jp_id == excluir or not info["conectado"]:
                continue
            await self._enviar(info, mensaje)

    async def enviar_a(self, id_sala: int, id_jugador_partida: int, mensaje: dict) -> None:
        """Envía un mensaje a un jugador específico."""
        info = self.salas.get(id_sala, {}).get(id_jugador_partida)
        if info and info["conectado"]:
            await self._enviar(info, mensaje)

    async def broadcast_estado(self, id_sala: int, motor, tipo: str = "estado") -> None:
        """Envía el snapshot del motor a cada jugador con su vista personal."""
        for jp_id, info in list(self.salas.get(id_sala, {}).items()):
            if not info["conectado"]:
                continue
            await self._enviar(info, {
                "tipo": tipo,
                "datos": motor.estado(para_jugador=jp_id),
            })

    @staticmethod
    async def _enviar(info: dict, mensaje: dict) -> None:
        try:
            await info["ws"].send_json(mensaje)
        except Exception:
            info["conectado"] = False


# Instancia global (singleton por proceso)
manager = SalaManager()
