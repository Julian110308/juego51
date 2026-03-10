import json
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Partida, JugadorPartida, HistorialPuntos, Usuario
from ..schemas import (
    PartidaCrear, JugadaBajar, JugadaAgregar, JugadaSwap, JugadaDescartar,
)
from ..routers.auth import get_current_user
from ..game.motor51 import Motor51

router = APIRouter(prefix="/partidas", tags=["Partidas"])


# ── Helpers ────────────────────────────────────────────────────────────────────

def _cargar_motor(partida: Partida) -> Motor51:
    if not partida.estado_json:
        raise HTTPException(status_code=500, detail="Estado de partida no encontrado")
    return Motor51.desde_estado(json.loads(partida.estado_json))


def _guardar_motor(partida: Partida, motor: Motor51, db: Session) -> None:
    partida.estado_json = json.dumps(motor.serializar())
    db.commit()


def _get_partida(id_partida: int, db: Session) -> Partida:
    partida = db.query(Partida).filter(Partida.id_partida == id_partida).first()
    if not partida:
        raise HTTPException(status_code=404, detail="Partida no encontrada")
    return partida


def _get_jugador_partida(id_partida: int, id_usuario: int, db: Session) -> JugadorPartida:
    jp = db.query(JugadorPartida).filter(
        JugadorPartida.id_partida == id_partida,
        JugadorPartida.id_usuario == id_usuario,
        JugadorPartida.es_ia == False,
    ).first()
    if not jp:
        raise HTTPException(status_code=403, detail="No eres jugador de esta partida")
    return jp


def _cerrar_ronda(partida: Partida, motor: Motor51, db: Session) -> None:
    """Guarda resultados al final de la ronda en historial y actualiza saldos."""
    partida.estado_partida = "finalizada"
    partida.id_ganador = None
    partida.fecha_fin = datetime.now(timezone.utc)

    penalizaciones = {
        pid: est.penalizacion_total()
        for pid, est in motor.jugadores.items()
        if pid != motor.ganador_ronda
    }

    for pid_jp, puntos_pen in penalizaciones.items():
        jp = db.query(JugadorPartida).filter(
            JugadorPartida.id_jugador_partida == pid_jp
        ).first()
        if not jp or jp.es_ia or not jp.id_usuario:
            continue

        usuario = db.query(Usuario).filter(Usuario.id_usuario == jp.id_usuario).first()
        if not usuario:
            continue

        usuario.puntos_saldo = max(0, usuario.puntos_saldo - puntos_pen)
        jp.resultado = "derrota"
        jp.puntos_ganados = -puntos_pen

        db.add(HistorialPuntos(
            id_usuario=jp.id_usuario,
            id_partida=partida.id_partida,
            tipo_movimiento="penalizacion",
            puntos_cambio=-puntos_pen,
            saldo_resultante=usuario.puntos_saldo,
            descripcion=f"Penalización ronda {partida.id_partida}",
        ))

    # Marcar ganador
    if motor.ganador_ronda is not None:
        jp_ganador = db.query(JugadorPartida).filter(
            JugadorPartida.id_jugador_partida == motor.ganador_ronda
        ).first()
        if jp_ganador:
            jp_ganador.resultado = "victoria"
            if jp_ganador.id_usuario:
                partida.id_ganador = jp_ganador.id_usuario

    db.commit()


def _ejecutar_ia_y_guardar(partida: Partida, motor: Motor51, db: Session) -> list[dict]:
    """Ejecuta turnos de IA mientras sea su turno, guarda estado y devuelve log."""
    log_ia: list[dict] = []
    while not motor.finalizada:
        pid = motor.jugador_activo()
        if pid is None or not motor.jugadores[pid].es_ia:
            break
        log_ia.extend(motor.ejecutar_turno_ia())

    if motor.finalizada:
        _cerrar_ronda(partida, motor, db)

    _guardar_motor(partida, motor, db)
    return log_ia


# ── Endpoints ──────────────────────────────────────────────────────────────────

@router.post("/crear", status_code=status.HTTP_201_CREATED)
def crear_partida(
    datos: PartidaCrear,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if datos.modo_juego == "cpu" and datos.num_ias < 1:
        raise HTTPException(status_code=400, detail="Modo CPU requiere al menos 1 IA")

    # 1. Crear registro de partida
    partida = Partida(
        modo_juego=datos.modo_juego,
        dificultad_ia=datos.dificultad_ia,
        estado_partida="en_progreso",
    )
    db.add(partida)
    db.flush()

    # 2. Crear JugadorPartida para el humano
    jp_humano = JugadorPartida(
        id_partida=partida.id_partida,
        id_usuario=usuario.id_usuario,
        es_ia=False,
        orden_turno=1,
    )
    db.add(jp_humano)
    db.flush()

    jugadores_ids = [jp_humano.id_jugador_partida]
    ias_ids = []

    # 3. Crear JugadorPartida para cada IA
    for i in range(datos.num_ias):
        jp_ia = JugadorPartida(
            id_partida=partida.id_partida,
            id_usuario=None,
            es_ia=True,
            orden_turno=i + 2,
        )
        db.add(jp_ia)
        db.flush()
        jugadores_ids.append(jp_ia.id_jugador_partida)
        ias_ids.append(jp_ia.id_jugador_partida)

    # 4. Inicializar motor y repartir
    motor = Motor51(jugadores=jugadores_ids, ias=ias_ids, dificultad=datos.dificultad_ia)
    motor.repartir()

    partida.estado_json = json.dumps(motor.serializar())
    db.commit()

    return {
        "id_partida": partida.id_partida,
        "id_jugador_partida": jp_humano.id_jugador_partida,
        "estado": motor.estado(para_jugador=jp_humano.id_jugador_partida),
    }


@router.get("/{id_partida}/estado")
def estado_partida(
    id_partida: int,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    partida = _get_partida(id_partida, db)
    jp = _get_jugador_partida(id_partida, usuario.id_usuario, db)
    motor = _cargar_motor(partida)
    return motor.estado(para_jugador=jp.id_jugador_partida)


@router.post("/{id_partida}/robar")
def robar(
    id_partida: int,
    fuente: str = "mazo",
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    partida = _get_partida(id_partida, db)
    jp = _get_jugador_partida(id_partida, usuario.id_usuario, db)
    motor = _cargar_motor(partida)

    if fuente == "descarte":
        resultado = motor.robar_descarte(jp.id_jugador_partida)
    else:
        resultado = motor.robar_mazo(jp.id_jugador_partida)

    if "error" in resultado:
        raise HTTPException(status_code=400, detail=resultado["error"])

    _guardar_motor(partida, motor, db)
    return {"resultado": resultado, "estado": motor.estado(para_jugador=jp.id_jugador_partida)}


@router.post("/{id_partida}/bajar")
def bajar(
    id_partida: int,
    datos: JugadaBajar,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    partida = _get_partida(id_partida, db)
    jp = _get_jugador_partida(id_partida, usuario.id_usuario, db)
    motor = _cargar_motor(partida)

    comb_data = [{"tipo": c.tipo, "iids": c.iids} for c in datos.combinaciones]
    resultado = motor.bajar(jp.id_jugador_partida, comb_data)

    if "error" in resultado:
        raise HTTPException(status_code=400, detail=resultado["error"])

    _guardar_motor(partida, motor, db)
    return {"resultado": resultado, "estado": motor.estado(para_jugador=jp.id_jugador_partida)}


@router.post("/{id_partida}/agregar")
def agregar(
    id_partida: int,
    datos: JugadaAgregar,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    partida = _get_partida(id_partida, db)
    jp = _get_jugador_partida(id_partida, usuario.id_usuario, db)
    motor = _cargar_motor(partida)

    resultado = motor.agregar_a_combinacion(jp.id_jugador_partida, datos.idx_mesa, datos.iids)

    if "error" in resultado:
        raise HTTPException(status_code=400, detail=resultado["error"])

    _guardar_motor(partida, motor, db)
    return {"resultado": resultado, "estado": motor.estado(para_jugador=jp.id_jugador_partida)}


@router.post("/{id_partida}/swap")
def swap_joker(
    id_partida: int,
    datos: JugadaSwap,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    partida = _get_partida(id_partida, db)
    jp = _get_jugador_partida(id_partida, usuario.id_usuario, db)
    motor = _cargar_motor(partida)

    resultado = motor.swap_joker(
        jp.id_jugador_partida, datos.idx_mesa, datos.iid_carta_real, datos.iid_joker
    )

    if "error" in resultado:
        raise HTTPException(status_code=400, detail=resultado["error"])

    _guardar_motor(partida, motor, db)
    return {"resultado": resultado, "estado": motor.estado(para_jugador=jp.id_jugador_partida)}


@router.post("/{id_partida}/descartar")
def descartar(
    id_partida: int,
    datos: JugadaDescartar,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    partida = _get_partida(id_partida, db)
    jp = _get_jugador_partida(id_partida, usuario.id_usuario, db)
    motor = _cargar_motor(partida)

    resultado = motor.descartar(jp.id_jugador_partida, datos.iid_carta)

    if "error" in resultado:
        raise HTTPException(status_code=400, detail=resultado["error"])

    if motor.finalizada:
        _cerrar_ronda(partida, motor, db)
        _guardar_motor(partida, motor, db)
        return {"resultado": resultado, "ia_log": [], "estado": motor.estado(para_jugador=jp.id_jugador_partida)}

    # Ejecutar turnos de IA si corresponde
    log_ia = _ejecutar_ia_y_guardar(partida, motor, db)

    return {
        "resultado": resultado,
        "ia_log": log_ia,
        "estado": motor.estado(para_jugador=jp.id_jugador_partida),
    }


@router.post("/{id_partida}/rendirse")
def rendirse(
    id_partida: int,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    partida = _get_partida(id_partida, db)
    if partida.estado_partida == "finalizada":
        raise HTTPException(status_code=400, detail="La partida ya finalizó")

    jp = _get_jugador_partida(id_partida, usuario.id_usuario, db)
    jp.se_rindio = True
    jp.resultado = "rendido"

    motor = _cargar_motor(partida)

    # Calcular penalización de las cartas en mano
    est = motor.jugadores.get(jp.id_jugador_partida)
    if est:
        penalizacion = est.penalizacion_total()
        usuario.puntos_saldo = max(0, usuario.puntos_saldo - penalizacion)
        db.add(HistorialPuntos(
            id_usuario=usuario.id_usuario,
            id_partida=id_partida,
            tipo_movimiento="rendicion",
            puntos_cambio=-penalizacion,
            saldo_resultante=usuario.puntos_saldo,
            descripcion="El jugador se rindió",
        ))

    partida.estado_partida = "finalizada"
    partida.fecha_fin = datetime.now(timezone.utc)
    db.commit()

    return {"mensaje": "Te has rendido", "penalizacion": est.penalizacion_total() if est else 0}
