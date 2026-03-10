from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional, Any


# ── Autenticación ──────────────────────────────────────────────────────────────

class UsuarioRegistro(BaseModel):
    nombre_usuario: str = Field(..., min_length=3, max_length=50)
    correo: EmailStr
    contrasena: str = Field(..., min_length=6, max_length=100)


class UsuarioLogin(BaseModel):
    correo: EmailStr
    contrasena: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    id_usuario: Optional[int] = None


# ── Usuario ────────────────────────────────────────────────────────────────────

class UsuarioRespuesta(BaseModel):
    id_usuario: int
    nombre_usuario: str
    correo: str
    avatar_url: Optional[str]
    puntos_saldo: int
    idioma: str
    fecha_registro: datetime
    activo: bool

    model_config = {"from_attributes": True}


# ── Partidas ───────────────────────────────────────────────────────────────────

class PartidaCrear(BaseModel):
    modo_juego: str = Field(..., pattern="^(cpu|local|privada|publica)$")
    dificultad_ia: str = Field("medio", pattern="^(facil|medio|dificil)$")
    num_ias: int = Field(1, ge=1, le=3)


class CombinacionData(BaseModel):
    tipo: str = Field(..., pattern="^(tercia|escalera)$")
    iids: list[int]


class JugadaBajar(BaseModel):
    combinaciones: list[CombinacionData]


class JugadaAgregar(BaseModel):
    idx_mesa: int
    iids: list[int]


class JugadaSwap(BaseModel):
    idx_mesa: int
    iid_carta_real: int
    iid_joker: int


class JugadaDescartar(BaseModel):
    iid_carta: int


class PartidaRespuesta(BaseModel):
    id_partida: int
    id_jugador_partida: int
    modo_juego: str
    estado_partida: str
    estado_juego: Any  # snapshot del motor

    model_config = {"from_attributes": True}


# ── Usuarios ───────────────────────────────────────────────────────────────────

class UsuarioEditar(BaseModel):
    nombre_usuario: Optional[str] = Field(None, min_length=3, max_length=50)
    avatar_url: Optional[str] = Field(None, max_length=255)
    idioma: Optional[str] = Field(None, max_length=5)


class EstadisticasUsuario(BaseModel):
    partidas_jugadas: int
    partidas_ganadas: int
    partidas_perdidas: int
    puntos_saldo: int


class HistorialEntrada(BaseModel):
    id_historial: int
    id_partida: Optional[int]
    tipo_movimiento: str
    puntos_cambio: int
    saldo_resultante: int
    descripcion: Optional[str]
    fecha: datetime

    model_config = {"from_attributes": True}


class LeaderboardEntrada(BaseModel):
    posicion: int
    id_usuario: int
    nombre_usuario: str
    puntos_saldo: int
    partidas_ganadas: int


# ── Salas ──────────────────────────────────────────────────────────────────────

class SalaCrear(BaseModel):
    tipo_sala: str = Field("privada", pattern="^(privada|publica)$")
    max_jugadores: int = Field(2, ge=2, le=4)
    dificultad_ia: str = Field("medio", pattern="^(facil|medio|dificil)$")


class SalaRespuesta(BaseModel):
    id_sala: int
    codigo_sala: Optional[str]
    tipo_sala: str
    max_jugadores: int
    estado_sala: str
    id_jugador_partida: int
    id_partida: int

    model_config = {"from_attributes": True}
