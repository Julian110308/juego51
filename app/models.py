from sqlalchemy import (Column, Integer, String, Boolean,
                        DateTime, SmallInteger, ForeignKey, Text)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base

class Usuario(Base):
    __tablename__ = "usuario"

    id_usuario        = Column(Integer, primary_key=True, index=True)
    nombre_usuario    = Column(String(50), unique=True, nullable=False)
    correo            = Column(String(120), unique=True, nullable=False)
    contrasena_hash   = Column(String(255), nullable=False)
    avatar_url        = Column(String(255), nullable=True)
    puntos_saldo      = Column(Integer, default=100, nullable=False)
    idioma            = Column(String(5), default="es")
    fecha_registro    = Column(DateTime, server_default=func.now())
    ultimo_acceso     = Column(DateTime, nullable=True)
    activo            = Column(Boolean, default=True)

class Sala(Base):
    __tablename__ = "sala"

    id_sala         = Column(Integer, primary_key=True, index=True)
    codigo_sala     = Column(String(10), unique=True, nullable=True)
    tipo_sala       = Column(String(10), nullable=False)  # privada / publica
    max_jugadores   = Column(SmallInteger, default=4)
    estado_sala     = Column(String(15), default="esperando")
    id_creador      = Column(Integer, ForeignKey("usuario.id_usuario"))
    fecha_creacion  = Column(DateTime, server_default=func.now())

class Partida(Base):
    __tablename__ = "partida"

    id_partida      = Column(Integer, primary_key=True, index=True)
    id_sala         = Column(Integer, ForeignKey("sala.id_sala"), nullable=True)
    modo_juego      = Column(String(15), nullable=False)
    dificultad_ia   = Column(String(10), nullable=True)
    estado_partida  = Column(String(15), default="en_progreso")
    id_ganador      = Column(Integer, ForeignKey("usuario.id_usuario"), nullable=True)
    turno_actual    = Column(Integer, default=1)
    fecha_inicio    = Column(DateTime, server_default=func.now())
    fecha_fin       = Column(DateTime, nullable=True)
    duracion_seg    = Column(Integer, nullable=True)
    estado_json     = Column(Text, nullable=True)

class JugadorPartida(Base):
    __tablename__ = "jugador_partida"

    id_jugador_partida = Column(Integer, primary_key=True, index=True)
    id_partida         = Column(Integer, ForeignKey("partida.id_partida"), nullable=False)
    id_usuario         = Column(Integer, ForeignKey("usuario.id_usuario"), nullable=True)
    es_ia              = Column(Boolean, default=False)
    orden_turno        = Column(SmallInteger, nullable=False)
    puntos_ganados     = Column(Integer, nullable=True)
    resultado          = Column(String(10), nullable=True)
    se_rindio          = Column(Boolean, default=False)
    fecha_union        = Column(DateTime, server_default=func.now())

class Carta(Base):
    __tablename__ = "carta"

    id_carta        = Column(Integer, primary_key=True, index=True)
    palo            = Column(String(10), nullable=False)
    valor_nombre    = Column(String(5), nullable=False)
    valor_numerico  = Column(SmallInteger, nullable=False)
    imagen_url      = Column(String(255), nullable=True)

class ManoCarta(Base):
    __tablename__ = "mano_carta"

    id_mano_carta       = Column(Integer, primary_key=True, index=True)
    id_jugador_partida  = Column(Integer, ForeignKey("jugador_partida.id_jugador_partida"))
    id_carta            = Column(Integer, ForeignKey("carta.id_carta"))
    en_mano             = Column(Boolean, default=True)
    turno_recibida      = Column(Integer, nullable=True)
    turno_jugada        = Column(Integer, nullable=True)

class Apuesta(Base):
    __tablename__ = "apuesta"

    id_apuesta        = Column(Integer, primary_key=True, index=True)
    id_partida        = Column(Integer, ForeignKey("partida.id_partida"))
    id_usuario        = Column(Integer, ForeignKey("usuario.id_usuario"))
    puntos_apostados  = Column(Integer, nullable=False)
    resultado_apuesta = Column(String(10), default="pendiente")
    puntos_ganados    = Column(Integer, nullable=True)
    fecha_apuesta     = Column(DateTime, server_default=func.now())

class HistorialPuntos(Base):
    __tablename__ = "historial_puntos"

    id_historial      = Column(Integer, primary_key=True, index=True)
    id_usuario        = Column(Integer, ForeignKey("usuario.id_usuario"))
    id_partida        = Column(Integer, ForeignKey("partida.id_partida"), nullable=True)
    tipo_movimiento   = Column(String(15), nullable=False)
    puntos_cambio     = Column(Integer, nullable=False)
    saldo_resultante  = Column(Integer, nullable=False)
    descripcion       = Column(String(255), nullable=True)
    fecha             = Column(DateTime, server_default=func.now())