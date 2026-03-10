import json
import random
import string
from datetime import datetime, timezone

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from dotenv import load_dotenv
import os

from ..database import get_db, SessionLocal
from ..models import Sala, Partida, JugadorPartida, Usuario
from ..schemas import SalaCrear, SalaRespuesta
from ..routers.auth import get_current_user
from ..game.motor51 import Motor51
from ..game.sala_manager import manager
from ..routers.partidas import _cerrar_ronda

load_dotenv()
SECRET_KEY = os.getenv("SECRET_KEY", "clave_insegura_cambiar")
ALGORITHM  = os.getenv("ALGORITHM", "HS256")

router = APIRouter(tags=["Salas"])


# ── Helpers ────────────────────────────────────────────────────────────────────

def _generar_codigo(largo: int = 6) -> str:
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=largo))


def _autenticar_token(token: str, db: Session):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        id_usuario = int(payload.get("sub", 0))
    except (JWTError, ValueError):
        return None
    return db.query(Usuario).filter(
        Usuario.id_usuario == id_usuario, Usuario.activo == True
    ).first()


def _iniciar_partida_en_sala(sala: Sala, partida: Partida, db: Session) -> Motor51:
    """Crea el Motor51, reparte cartas y persiste el estado inicial."""
    jps = (
        db.query(JugadorPartida)
        .filter(JugadorPartida.id_partida == partida.id_partida)
        .order_by(JugadorPartida.orden_turno)
        .all()
    )
    jugadores_ids = [jp.id_jugador_partida for jp in jps]
    ias_ids = [jp.id_jugador_partida for jp in jps if jp.es_ia]

    motor = Motor51(
        jugadores=jugadores_ids,
        ias=ias_ids,
        dificultad=partida.dificultad_ia or "medio",
    )
    motor.repartir()

    partida.estado_partida = "en_progreso"
    sala.estado_sala = "en_juego"
    partida.estado_json = json.dumps(motor.serializar())
    db.commit()
    return motor


# ── Endpoints HTTP de sala ─────────────────────────────────────────────────────

@router.post("/salas/crear", response_model=SalaRespuesta, status_code=201)
def crear_sala(
    datos: SalaCrear,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Generar código único para salas privadas
    codigo = None
    if datos.tipo_sala == "privada":
        while True:
            codigo = _generar_codigo()
            if not db.query(Sala).filter(Sala.codigo_sala == codigo).first():
                break

    sala = Sala(
        codigo_sala=codigo,
        tipo_sala=datos.tipo_sala,
        max_jugadores=datos.max_jugadores,
        estado_sala="esperando",
        id_creador=usuario.id_usuario,
    )
    db.add(sala)
    db.flush()

    partida = Partida(
        id_sala=sala.id_sala,
        modo_juego="privada" if datos.tipo_sala == "privada" else "publica",
        dificultad_ia=datos.dificultad_ia,
        estado_partida="esperando",
    )
    db.add(partida)
    db.flush()

    jp = JugadorPartida(
        id_partida=partida.id_partida,
        id_usuario=usuario.id_usuario,
        es_ia=False,
        orden_turno=1,
    )
    db.add(jp)
    db.commit()
    db.refresh(jp)

    return SalaRespuesta(
        id_sala=sala.id_sala,
        codigo_sala=sala.codigo_sala,
        tipo_sala=sala.tipo_sala,
        max_jugadores=sala.max_jugadores,
        estado_sala=sala.estado_sala,
        id_jugador_partida=jp.id_jugador_partida,
        id_partida=partida.id_partida,
    )


@router.post("/salas/unirse", response_model=SalaRespuesta)
def unirse_sala(
    codigo_sala: str = Query(..., min_length=1),
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    sala = db.query(Sala).filter(Sala.codigo_sala == codigo_sala).first()
    if not sala:
        raise HTTPException(status_code=404, detail="Sala no encontrada")
    if sala.estado_sala != "esperando":
        raise HTTPException(status_code=400, detail="La sala ya comenzó o está cerrada")

    partida = db.query(Partida).filter(Partida.id_sala == sala.id_sala).first()
    if not partida:
        raise HTTPException(status_code=404, detail="Partida no encontrada")

    jugadores_actuales = db.query(JugadorPartida).filter(
        JugadorPartida.id_partida == partida.id_partida,
        JugadorPartida.es_ia == False,
    ).count()

    if jugadores_actuales >= sala.max_jugadores:
        raise HTTPException(status_code=400, detail="La sala está llena")

    # Verificar que no esté ya en la sala
    ya_unido = db.query(JugadorPartida).filter(
        JugadorPartida.id_partida == partida.id_partida,
        JugadorPartida.id_usuario == usuario.id_usuario,
    ).first()
    if ya_unido:
        raise HTTPException(status_code=400, detail="Ya estás en esta sala")

    jp = JugadorPartida(
        id_partida=partida.id_partida,
        id_usuario=usuario.id_usuario,
        es_ia=False,
        orden_turno=jugadores_actuales + 1,
    )
    db.add(jp)
    db.commit()
    db.refresh(jp)

    return SalaRespuesta(
        id_sala=sala.id_sala,
        codigo_sala=sala.codigo_sala,
        tipo_sala=sala.tipo_sala,
        max_jugadores=sala.max_jugadores,
        estado_sala=sala.estado_sala,
        id_jugador_partida=jp.id_jugador_partida,
        id_partida=partida.id_partida,
    )


# ── WebSocket ──────────────────────────────────────────────────────────────────

@router.websocket("/ws/sala/{id_sala}")
async def websocket_sala(
    id_sala: int,
    websocket: WebSocket,
    token: str = Query(...),
):
    """
    Protocolo de mensajes cliente → servidor:

        {"tipo": "chat",     "mensaje": "hola"}
        {"tipo": "robar",    "fuente": "mazo"|"descarte"}
        {"tipo": "bajar",    "combinaciones": [{"tipo":"tercia","iids":[...]},...]}
        {"tipo": "agregar",  "idx_mesa": 0, "iids": [...]}
        {"tipo": "swap",     "idx_mesa": 0, "iid_carta_real": 5, "iid_joker": 10}
        {"tipo": "descartar","iid_carta": 7}
        {"tipo": "rendirse"}

    Servidor → cliente:

        {"tipo": "conectado",         "jugador": "nombre"}
        {"tipo": "desconectado",      "jugador": "nombre"}
        {"tipo": "sala_lista",        "jugadores": [...]}
        {"tipo": "estado",            "datos": {...}}
        {"tipo": "jugada",            "accion": "...", "jugador": "...", "resultado": {...}, "ia_log": [...], "datos": {...}}
        {"tipo": "chat",              "autor": "nombre", "mensaje": "...", "hora": "..."}
        {"tipo": "ronda_terminada",   "ganador": "nombre", "penalizaciones": {...}}
        {"tipo": "error",             "detalle": "..."}
    """
    db = SessionLocal()
    jp = None
    await websocket.accept()
    try:
        # ── 1. Autenticación ───────────────────────────────────────────────────
        usuario = _autenticar_token(token, db)
        if not usuario:
            await websocket.send_json({"tipo": "error", "detalle": "Token inválido"})
            await websocket.close(code=1008)
            return

        sala = db.query(Sala).filter(Sala.id_sala == id_sala).first()
        if not sala:
            await websocket.send_json({"tipo": "error", "detalle": "Sala no encontrada"})
            await websocket.close(code=1008)
            return

        partida = db.query(Partida).filter(Partida.id_sala == id_sala).first()
        if not partida:
            await websocket.send_json({"tipo": "error", "detalle": "Partida no encontrada"})
            await websocket.close(code=1008)
            return

        jp = db.query(JugadorPartida).filter(
            JugadorPartida.id_partida == partida.id_partida,
            JugadorPartida.id_usuario == usuario.id_usuario,
            JugadorPartida.es_ia == False,
        ).first()
        if not jp:
            await websocket.send_json({"tipo": "error", "detalle": "No eres jugador de esta sala"})
            await websocket.close(code=1008)
            return

        # ── 2. Registrar conexión ──────────────────────────────────────────────
        await manager.conectar(id_sala, jp.id_jugador_partida, usuario.nombre_usuario, websocket)

        await manager.broadcast(id_sala, {
            "tipo": "conectado",
            "jugador": usuario.nombre_usuario,
        }, excluir=jp.id_jugador_partida)

        # ── 3. Enviar estado actual (reconexión o estado inicial) ──────────────
        if partida.estado_json:
            motor = Motor51.desde_estado(json.loads(partida.estado_json))
            await websocket.send_json({
                "tipo": "estado",
                "datos": motor.estado(para_jugador=jp.id_jugador_partida),
            })

        # ── 4. Verificar si la sala está lista para empezar ────────────────────
        if sala.estado_sala == "esperando":
            jugadores_en_sala = db.query(JugadorPartida).filter(
                JugadorPartida.id_partida == partida.id_partida,
                JugadorPartida.es_ia == False,
            ).count()

            if jugadores_en_sala >= sala.max_jugadores:
                motor = _iniciar_partida_en_sala(sala, partida, db)

                jugadores_nombres = [
                    db.query(Usuario).filter(
                        Usuario.id_usuario == jp_obj.id_usuario
                    ).first().nombre_usuario
                    for jp_obj in db.query(JugadorPartida).filter(
                        JugadorPartida.id_partida == partida.id_partida,
                        JugadorPartida.es_ia == False,
                    ).all()
                ]
                await manager.broadcast(id_sala, {
                    "tipo": "sala_lista",
                    "jugadores": jugadores_nombres,
                })
                await manager.broadcast_estado(id_sala, motor)

        # ── 5. Bucle principal de mensajes ─────────────────────────────────────
        while True:
            data = await websocket.receive_json()
            await _procesar_mensaje(id_sala, jp, usuario, data, db)

    except WebSocketDisconnect:
        pass
    except Exception as e:
        try:
            await websocket.send_json({"tipo": "error", "detalle": str(e)})
        except Exception:
            pass
    finally:
        if jp:
            manager.desconectar(id_sala, jp.id_jugador_partida)
            await manager.broadcast(id_sala, {
                "tipo": "desconectado",
                "jugador": usuario.nombre_usuario if usuario else "Jugador",
            })
        db.close()


# ── Procesador de mensajes ─────────────────────────────────────────────────────

async def _procesar_mensaje(
    id_sala: int,
    jp: JugadorPartida,
    usuario: Usuario,
    data: dict,
    db: Session,
) -> None:
    tipo = data.get("tipo")

    # Chat (no requiere partida activa)
    if tipo == "chat":
        mensaje = str(data.get("mensaje", "")).strip()[:200]
        if mensaje:
            await manager.broadcast(id_sala, {
                "tipo": "chat",
                "autor": usuario.nombre_usuario,
                "mensaje": mensaje,
                "hora": datetime.now(timezone.utc).strftime("%H:%M"),
            })
        return

    # Para acciones de juego se necesita la partida activa
    partida = db.query(Partida).filter(Partida.id_sala == id_sala).first()
    if not partida or partida.estado_partida != "en_progreso":
        await manager.enviar_a(id_sala, jp.id_jugador_partida, {
            "tipo": "error", "detalle": "La partida no está en progreso",
        })
        return

    motor = Motor51.desde_estado(json.loads(partida.estado_json))
    resultado: dict | None = None

    if tipo == "robar":
        fuente = data.get("fuente", "mazo")
        resultado = (
            motor.robar_descarte(jp.id_jugador_partida)
            if fuente == "descarte"
            else motor.robar_mazo(jp.id_jugador_partida)
        )

    elif tipo == "bajar":
        resultado = motor.bajar(jp.id_jugador_partida, data.get("combinaciones", []))

    elif tipo == "agregar":
        resultado = motor.agregar_a_combinacion(
            jp.id_jugador_partida, data.get("idx_mesa", 0), data.get("iids", [])
        )

    elif tipo == "swap":
        resultado = motor.swap_joker(
            jp.id_jugador_partida,
            data.get("idx_mesa", 0),
            data.get("iid_carta_real", 0),
            data.get("iid_joker", 0),
        )

    elif tipo == "descartar":
        resultado = motor.descartar(jp.id_jugador_partida, data.get("iid_carta", 0))

    elif tipo == "rendirse":
        est = motor.jugadores.get(jp.id_jugador_partida)
        penalizacion = est.penalizacion_total() if est else 0
        jp.se_rindio = True
        jp.resultado = "rendido"
        partida.estado_partida = "finalizada"
        partida.fecha_fin = datetime.now(timezone.utc)
        db.commit()
        await manager.broadcast(id_sala, {
            "tipo": "ronda_terminada",
            "ganador": None,
            "motivo": f"{usuario.nombre_usuario} se rindió",
            "penalizaciones": {jp.id_jugador_partida: penalizacion},
        })
        return

    else:
        await manager.enviar_a(id_sala, jp.id_jugador_partida, {
            "tipo": "error", "detalle": f"Tipo desconocido: {tipo}",
        })
        return

    # Error en la acción
    if resultado and "error" in resultado:
        await manager.enviar_a(id_sala, jp.id_jugador_partida, {
            "tipo": "error", "detalle": resultado["error"],
        })
        return

    # Ejecutar turnos de IA si corresponde
    log_ia: list[dict] = []
    if not motor.finalizada:
        while not motor.finalizada:
            pid = motor.jugador_activo()
            if pid is None or not motor.jugadores[pid].es_ia:
                break
            log_ia.extend(motor.ejecutar_turno_ia())

    # Cerrar ronda si terminó
    if motor.finalizada:
        _cerrar_ronda(partida, motor, db)

    # Persistir estado
    partida.estado_json = json.dumps(motor.serializar())
    db.commit()

    # Broadcast a todos los jugadores (cada uno ve su propia mano)
    for pid_jp in list(manager.salas.get(id_sala, {}).keys()):
        msg: dict = {
            "tipo": "jugada",
            "accion": tipo,
            "jugador": usuario.nombre_usuario,
            "resultado": resultado,
            "datos": motor.estado(para_jugador=pid_jp),
        }
        if log_ia:
            msg["ia_log"] = log_ia
        await manager.enviar_a(id_sala, pid_jp, msg)

    # Notificación especial al cerrar ronda
    if motor.finalizada:
        ganador_jp = db.query(JugadorPartida).filter(
            JugadorPartida.id_jugador_partida == motor.ganador_ronda
        ).first()
        ganador_nombre = None
        if ganador_jp and ganador_jp.id_usuario:
            u = db.query(Usuario).filter(
                Usuario.id_usuario == ganador_jp.id_usuario
            ).first()
            ganador_nombre = u.nombre_usuario if u else None

        penalizaciones = {
            pid: est.penalizacion_total()
            for pid, est in motor.jugadores.items()
            if pid != motor.ganador_ronda
        }
        await manager.broadcast(id_sala, {
            "tipo": "ronda_terminada",
            "ganador": ganador_nombre,
            "penalizaciones": penalizaciones,
        })
