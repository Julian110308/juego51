from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func

from ..database import get_db
from ..models import Usuario, JugadorPartida, HistorialPuntos, Partida
from ..schemas import (
    UsuarioRespuesta, UsuarioEditar, EstadisticasUsuario,
    HistorialEntrada, LeaderboardEntrada,
)
from ..routers.auth import get_current_user

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])


# ── Perfil ─────────────────────────────────────────────────────────────────────

@router.get("/perfil", response_model=UsuarioRespuesta)
def obtener_perfil(usuario: Usuario = Depends(get_current_user)):
    return usuario


@router.put("/perfil", response_model=UsuarioRespuesta)
def editar_perfil(
    datos: UsuarioEditar,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if datos.nombre_usuario and datos.nombre_usuario != usuario.nombre_usuario:
        existe = db.query(Usuario).filter(
            Usuario.nombre_usuario == datos.nombre_usuario,
            Usuario.id_usuario != usuario.id_usuario,
        ).first()
        if existe:
            raise HTTPException(status_code=400, detail="El nombre de usuario ya está en uso")
        usuario.nombre_usuario = datos.nombre_usuario

    if datos.avatar_url is not None:
        usuario.avatar_url = datos.avatar_url

    if datos.idioma is not None:
        usuario.idioma = datos.idioma

    db.commit()
    db.refresh(usuario)
    return usuario


# ── Estadísticas ───────────────────────────────────────────────────────────────

@router.get("/estadisticas", response_model=EstadisticasUsuario)
def estadisticas(
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    total = db.query(func.count(JugadorPartida.id_jugador_partida)).filter(
        JugadorPartida.id_usuario == usuario.id_usuario,
        JugadorPartida.es_ia == False,
    ).scalar() or 0

    ganadas = db.query(func.count(JugadorPartida.id_jugador_partida)).filter(
        JugadorPartida.id_usuario == usuario.id_usuario,
        JugadorPartida.resultado == "victoria",
    ).scalar() or 0

    perdidas = db.query(func.count(JugadorPartida.id_jugador_partida)).filter(
        JugadorPartida.id_usuario == usuario.id_usuario,
        JugadorPartida.resultado.in_(["derrota", "rendido"]),
    ).scalar() or 0

    return EstadisticasUsuario(
        partidas_jugadas=total,
        partidas_ganadas=ganadas,
        partidas_perdidas=perdidas,
        puntos_saldo=usuario.puntos_saldo,
    )


# ── Historial de partidas ──────────────────────────────────────────────────────

@router.get("/historial", response_model=list[HistorialEntrada])
def historial(
    limite: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    registros = (
        db.query(HistorialPuntos)
        .filter(HistorialPuntos.id_usuario == usuario.id_usuario)
        .order_by(HistorialPuntos.fecha.desc())
        .offset(offset)
        .limit(limite)
        .all()
    )
    return registros


@router.get("/partidas", response_model=list[dict])
def partidas_jugadas(
    limite: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Historial de partidas con resultado."""
    registros = (
        db.query(JugadorPartida, Partida)
        .join(Partida, JugadorPartida.id_partida == Partida.id_partida)
        .filter(
            JugadorPartida.id_usuario == usuario.id_usuario,
            JugadorPartida.es_ia == False,
        )
        .order_by(Partida.fecha_inicio.desc())
        .offset(offset)
        .limit(limite)
        .all()
    )
    return [
        {
            "id_partida": partida.id_partida,
            "modo_juego": partida.modo_juego,
            "estado_partida": partida.estado_partida,
            "resultado": jp.resultado,
            "puntos_ganados": jp.puntos_ganados,
            "fecha_inicio": partida.fecha_inicio,
            "fecha_fin": partida.fecha_fin,
        }
        for jp, partida in registros
    ]


# ── Leaderboard ────────────────────────────────────────────────────────────────

@router.get("/leaderboard", response_model=list[LeaderboardEntrada])
def leaderboard(
    limite: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    _: Usuario = Depends(get_current_user),
):
    """Top jugadores por puntos_saldo. Requiere estar autenticado."""
    usuarios = (
        db.query(Usuario)
        .filter(Usuario.activo == True)
        .order_by(Usuario.puntos_saldo.desc())
        .limit(limite)
        .all()
    )

    # Contar victorias por usuario en una sola consulta
    victorias_q = (
        db.query(
            JugadorPartida.id_usuario,
            func.count(JugadorPartida.id_jugador_partida).label("ganadas"),
        )
        .filter(JugadorPartida.resultado == "victoria")
        .group_by(JugadorPartida.id_usuario)
        .all()
    )
    victorias_map = {row.id_usuario: row.ganadas for row in victorias_q}

    return [
        LeaderboardEntrada(
            posicion=i + 1,
            id_usuario=u.id_usuario,
            nombre_usuario=u.nombre_usuario,
            puntos_saldo=u.puntos_saldo,
            partidas_ganadas=victorias_map.get(u.id_usuario, 0),
        )
        for i, u in enumerate(usuarios)
    ]
