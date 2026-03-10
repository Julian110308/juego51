from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta, timezone
from typing import Optional
from dotenv import load_dotenv
import os

from ..database import get_db
from ..models import Usuario
from ..schemas import UsuarioRegistro, UsuarioLogin, Token, TokenData, UsuarioRespuesta

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY", "clave_insegura_cambiar")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

router = APIRouter(prefix="/auth", tags=["Autenticación"])


# ── Utilidades ─────────────────────────────────────────────────────────────────

def hashear_contrasena(contrasena: str) -> str:
    return pwd_context.hash(contrasena)


def verificar_contrasena(contrasena_plana: str, contrasena_hash: str) -> bool:
    return pwd_context.verify(contrasena_plana, contrasena_hash)


def crear_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    payload = data.copy()
    expira = datetime.now(timezone.utc) + (
        expires_delta if expires_delta else timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    payload.update({"exp": expira})
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


# ── Dependencia: usuario autenticado ──────────────────────────────────────────

def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> Usuario:
    credenciales_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudo validar las credenciales",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        id_usuario: Optional[int] = payload.get("sub")
        if id_usuario is None:
            raise credenciales_error
        token_data = TokenData(id_usuario=int(id_usuario))
    except JWTError:
        raise credenciales_error

    usuario = db.query(Usuario).filter(Usuario.id_usuario == token_data.id_usuario).first()
    if usuario is None or not usuario.activo:
        raise credenciales_error
    return usuario


# ── Endpoints ──────────────────────────────────────────────────────────────────

@router.post("/registro", response_model=UsuarioRespuesta, status_code=status.HTTP_201_CREATED)
def registro(datos: UsuarioRegistro, db: Session = Depends(get_db)):
    if db.query(Usuario).filter(Usuario.correo == datos.correo).first():
        raise HTTPException(status_code=400, detail="El correo ya está registrado")
    if db.query(Usuario).filter(Usuario.nombre_usuario == datos.nombre_usuario).first():
        raise HTTPException(status_code=400, detail="El nombre de usuario ya está en uso")

    nuevo_usuario = Usuario(
        nombre_usuario=datos.nombre_usuario,
        correo=datos.correo,
        contrasena_hash=hashear_contrasena(datos.contrasena),
    )
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)
    return nuevo_usuario


@router.post("/login", response_model=Token)
def login(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    usuario = db.query(Usuario).filter(Usuario.correo == form.username).first()
    if not usuario or not verificar_contrasena(form.password, usuario.contrasena_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos",
        )
    if not usuario.activo:
        raise HTTPException(status_code=403, detail="Cuenta desactivada")

    usuario.ultimo_acceso = datetime.now(timezone.utc)
    db.commit()

    token = crear_token({"sub": str(usuario.id_usuario)})
    return {"access_token": token, "token_type": "bearer"}


@router.get("/me", response_model=UsuarioRespuesta)
def obtener_perfil(usuario_actual: Usuario = Depends(get_current_user)):
    return usuario_actual
