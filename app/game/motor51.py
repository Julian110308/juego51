import random
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional


# ── Constantes ─────────────────────────────────────────────────────────────────

PALOS = ["corazones", "diamantes", "treboles", "picas"]
VALORES = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

# Posición en escalera (A puede estar al inicio A-2-3)
ORDEN = {v: i for i, v in enumerate(VALORES)}  # A=0, 2=1, ..., K=12

# Valor para calcular si se puede bajar (≥51). As = 1 u 11 a elección.
VALOR_BAJADA: dict[str, int] = {
    "A": 11, "2": 2, "3": 3, "4": 4, "5": 5,
    "6": 6,  "7": 7, "8": 8, "9": 9, "10": 10,
    "J": 11, "Q": 11, "K": 11,
}

# Penalización al cierre de ronda (cartas que quedan en mano)
PENALIZACION: dict[str, int] = {
    "A": 25, "2": 2, "3": 3, "4": 4, "5": 5,
    "6": 6,  "7": 7, "8": 8, "9": 9, "10": 10,
    "J": 11, "Q": 11, "K": 11,
    "JOKER": 50,
}

LIMITE_BAJADA = 51
LIMITE_ELIMINACION = 500
CARTAS_INICIALES = 14


# ── Enums ──────────────────────────────────────────────────────────────────────

class FaseTurno(str, Enum):
    ROBAR    = "robar"
    ACCIONES = "acciones"
    DESCARTAR = "descartar"


# ── Carta ──────────────────────────────────────────────────────────────────────

@dataclass
class Carta:
    palo: Optional[str]   # None para comodines
    valor_nombre: str     # "A","2",...,"K","JOKER"
    iid: int              # id único de instancia en la partida (0-107)

    @property
    def es_joker(self) -> bool:
        return self.valor_nombre == "JOKER"

    @property
    def valor_bajada(self) -> int:
        return 0 if self.es_joker else VALOR_BAJADA[self.valor_nombre]

    @property
    def penalizacion(self) -> int:
        return PENALIZACION["JOKER"] if self.es_joker else PENALIZACION[self.valor_nombre]

    def __str__(self) -> str:
        return "JOKER" if self.es_joker else f"{self.valor_nombre} de {self.palo}"

    def to_dict(self) -> dict:
        return {"iid": self.iid, "valor": self.valor_nombre, "palo": self.palo, "es_joker": self.es_joker}


# ── Mazo (2 barajas + 4 comodines = 108 cartas) ───────────────────────────────

class Mazo:
    def __init__(self):
        cartas: list[Carta] = []
        iid = 0
        for _ in range(2):
            for palo in PALOS:
                for valor in VALORES:
                    cartas.append(Carta(palo, valor, iid)); iid += 1
            for _ in range(2):
                cartas.append(Carta(None, "JOKER", iid)); iid += 1
        self.cartas = cartas
        random.shuffle(self.cartas)

    def robar(self) -> Optional[Carta]:
        return self.cartas.pop() if self.cartas else None

    def recargar_desde_descarte(self, descarte: list[Carta]) -> None:
        if len(descarte) <= 1:
            return
        tope = descarte.pop()
        self.cartas = descarte.copy()
        descarte.clear()
        descarte.append(tope)
        random.shuffle(self.cartas)

    def __len__(self) -> int:
        return len(self.cartas)


# ── Combinación (tercia o escalera) ───────────────────────────────────────────

@dataclass
class Combinacion:
    tipo: str           # "tercia" | "escalera"
    cartas: list[Carta]

    def es_valida(self) -> bool:
        if len(self.cartas) < 3:
            return False
        jokers = [c for c in self.cartas if c.es_joker]
        if len(jokers) > 1:
            return False
        normales = [c for c in self.cartas if not c.es_joker]
        if not normales:
            return False
        if self.tipo == "tercia" and len(self.cartas) > 4:
            return False  # máx 4 cartas (una por palo)
        return self._validar_tercia(normales) if self.tipo == "tercia" else self._validar_escalera(normales)

    def _validar_tercia(self, normales: list[Carta]) -> bool:
        # Mismo valor, palos distintos (sin repetir palo)
        valores = {c.valor_nombre for c in normales}
        if len(valores) > 1:
            return False
        palos = [c.palo for c in normales]
        return len(palos) == len(set(palos))

    def _validar_escalera(self, normales: list[Carta]) -> bool:
        # Mismo palo, valores consecutivos (el joker puede cubrir 1 hueco)
        palos = {c.palo for c in normales}
        if len(palos) > 1:
            return False
        tiene_joker = len(self.cartas) > len(normales)

        # Probar A como carta baja (índice 0: A-2-3-...) y como carta alta (índice 13: ..Q-K-A)
        def _check(indices: list[int]) -> bool:
            if len(indices) != len(set(indices)):
                return False
            huecos = sum(1 for i in range(1, len(indices)) if indices[i] - indices[i-1] == 2)
            saltos = sum(1 for i in range(1, len(indices)) if indices[i] - indices[i-1] > 2)
            consecutivos = sum(1 for i in range(1, len(indices)) if indices[i] - indices[i-1] == 1)
            if saltos > 0:
                return False
            return huecos <= 1 if tiene_joker else consecutivos == len(indices) - 1

        tiene_as = any(c.valor_nombre == "A" for c in normales)
        # Índices con A como baja (0)
        indices_bajo = sorted(ORDEN[c.valor_nombre] for c in normales)
        if _check(indices_bajo):
            return True
        # Índices con A como alta (13, después de K=12) solo si hay As
        if tiene_as:
            indices_alto = sorted(
                (13 if c.valor_nombre == "A" else ORDEN[c.valor_nombre])
                for c in normales
            )
            if _check(indices_alto):
                return True
        return False

    def _joker_indice_escalera(self) -> Optional[int]:
        """Devuelve el índice ORDEN que el comodín ocupa en esta escalera."""
        normales = [c for c in self.cartas if not c.es_joker]
        if not normales:
            return None
        tiene_as = any(c.valor_nombre == "A" for c in normales)

        def _buscar_hueco(indices: list[int]) -> Optional[int]:
            for i in range(1, len(indices)):
                if indices[i] - indices[i - 1] == 2:
                    return indices[i - 1] + 1
            return None

        indices_bajo = sorted(ORDEN[c.valor_nombre] for c in normales)
        hueco = _buscar_hueco(indices_bajo)
        if hueco is not None:
            return hueco
        if tiene_as:
            indices_alto = sorted(
                (13 if c.valor_nombre == "A" else ORDEN[c.valor_nombre])
                for c in normales
            )
            hueco = _buscar_hueco(indices_alto)
            if hueco is not None:
                return hueco
        # Sin hueco interno: el comodín está en un extremo; determinarlo por posición física
        joker_phys = next(i for i, c in enumerate(self.cartas) if c.es_joker)
        if joker_phys == 0:
            return min(indices_bajo) - 1
        else:
            return max(indices_bajo) + 1

    def valor_total(self) -> int:
        """Suma de valores para verificar si alcanza 51 al bajarse.
        El As vale 1 en escaleras donde está al inicio (A-2-3), 11 en todo lo demás.
        """
        normales = [c for c in self.cartas if not c.es_joker]
        jokers = [c for c in self.cartas if c.es_joker]

        # Determinar valor del As según contexto
        # Tercia/cuarteto: A=11
        # Escalera A-2-3...: A=1
        # Escalera ..Q-K-A o ..K-A: A=11
        as_valor = 11  # por defecto
        if self.tipo == "escalera" and normales:
            nombres = {c.valor_nombre for c in normales}
            if "A" in nombres:
                tiene_k = "K" in nombres
                tiene_2 = "2" in nombres
                if tiene_2 and not tiene_k:
                    as_valor = 1   # A-2-3-... → As bajo
                # si tiene K (..K-A) → As alto = 11 (ya es el default)

        total = 0
        for carta in normales:
            if carta.valor_nombre == "A":
                total += as_valor
            else:
                total += carta.valor_bajada

        # El joker toma el valor de la carta que sustituye
        if jokers and normales:
            if self.tipo == "tercia":
                val_normal = normales[0].valor_nombre
                total += as_valor if val_normal == "A" else VALOR_BAJADA.get(val_normal, 0)
            else:
                indices = sorted(ORDEN[c.valor_nombre] for c in normales)
                for i in range(1, len(indices)):
                    if indices[i] - indices[i-1] == 2:
                        total += indices[i-1] + 1
                        break
                else:
                    total += normales[0].valor_bajada
        return total

    def to_dict(self) -> dict:
        return {
            "tipo": self.tipo,
            "cartas": [c.to_dict() for c in self.cartas],
            "valor_total": self.valor_total(),
        }

    def ordenar_cartas(self) -> None:
        """Reordena las cartas en la posición correcta de la secuencia."""
        if self.tipo != "escalera":
            return
        normales = [c for c in self.cartas if not c.es_joker]
        jokers = [c for c in self.cartas if c.es_joker]
        if not normales:
            return

        tiene_as = any(c.valor_nombre == "A" for c in normales)
        tiene_k = any(c.valor_nombre == "K" for c in normales)
        tiene_2 = any(c.valor_nombre == "2" for c in normales)
        as_alto = tiene_as and tiene_k and not tiene_2

        def get_idx(c: Carta) -> int:
            if c.valor_nombre == "A":
                return 13 if as_alto else 0
            return ORDEN[c.valor_nombre]

        if jokers:
            joker_idx = self._joker_indice_escalera()
            if joker_idx is None:
                joker_idx = max(get_idx(c) for c in normales) + 1
            items = [(get_idx(c), c) for c in normales] + [(joker_idx, jokers[0])]
            items.sort(key=lambda x: x[0])
            self.cartas = [item[1] for item in items]
        else:
            self.cartas = sorted(normales, key=get_idx)


# ── Estado por jugador ─────────────────────────────────────────────────────────

@dataclass
class EstadoJugador:
    id_jugador: int
    es_ia: bool
    dificultad: str
    mano: list[Carta] = field(default_factory=list)
    bajado: bool = False   # ya puso combinaciones en mesa

    def penalizacion_total(self) -> int:
        return sum(c.penalizacion for c in self.mano)

    def to_dict(self, ocultar_mano: bool = False) -> dict:
        return {
            "id_jugador": self.id_jugador,
            "es_ia": self.es_ia,
            "cartas_en_mano": len(self.mano),
            "mano": [] if ocultar_mano else [c.to_dict() for c in self.mano],
            "bajado": self.bajado,
        }


# ── Motor principal ────────────────────────────────────────────────────────────

class Motor51:
    """
    Gestiona el estado completo de una ronda en memoria.

    Flujo de turno:
        1. robar_mazo(pid)  o  robar_descarte(pid)
        2. [opcional] bajar(pid, combinaciones)
                      agregar_a_combinacion(pid, idx_mesa, ids_cartas)
                      swap_joker(pid, idx_mesa, iid_carta_real, iid_joker)
        3. descartar(pid, iid_carta)  ← cierra el turno

    Uso:
        motor = Motor51(jugadores=[1, 2], ias=[2], dificultad="medio")
        motor.repartir()
        motor.robar_mazo(1)
        motor.bajar(1, [{"tipo":"tercia","iids":[5,22,60]}])
        motor.descartar(1, 10)
    """

    def __init__(self, jugadores: list[int], ias: list[int], dificultad: str = "medio"):
        if not (2 <= len(jugadores) <= 4):
            raise ValueError("Se necesitan entre 2 y 4 jugadores")
        self.mazo = Mazo()
        self.descarte: list[Carta] = []
        self.jugadores: dict[int, EstadoJugador] = {
            pid: EstadoJugador(pid, pid in ias, dificultad)
            for pid in jugadores
        }
        self.orden: list[int] = jugadores.copy()
        self.turno_idx: int = 0
        self.fase: FaseTurno = FaseTurno.ROBAR
        # Mesa: lista de (id_propietario, Combinacion)
        self.mesa: list[tuple[int, Combinacion]] = []
        self.finalizada: bool = False
        self.ganador_ronda: Optional[int] = None

    # ── Setup ──────────────────────────────────────────────────────────────────

    def repartir(self) -> None:
        for _ in range(CARTAS_INICIALES):
            for pid in self.orden:
                carta = self.mazo.robar()
                if carta:
                    self.jugadores[pid].mano.append(carta)
        primera = self.mazo.robar()
        if primera:
            self.descarte.append(primera)

    # ── Consultas ──────────────────────────────────────────────────────────────

    def jugador_activo(self) -> Optional[int]:
        return None if self.finalizada else self.orden[self.turno_idx % len(self.orden)]

    # ── Acciones del turno ─────────────────────────────────────────────────────

    def robar_mazo(self, id_jugador: int) -> dict:
        if err := self._check_turno(id_jugador, FaseTurno.ROBAR):
            return err
        if not self.mazo.cartas:
            self.mazo.recargar_desde_descarte(self.descarte)
        carta = self.mazo.robar()
        if not carta:
            return {"error": "No hay cartas disponibles"}
        self.jugadores[id_jugador].mano.append(carta)
        self.fase = FaseTurno.ACCIONES
        return {"accion": "robar_mazo", "carta": carta.to_dict()}

    def robar_descarte(self, id_jugador: int) -> dict:
        """Cualquier jugador puede robar del descarte para completar sus combinaciones."""
        if err := self._check_turno(id_jugador, FaseTurno.ROBAR):
            return err
        if not self.descarte:
            return {"error": "El montón de descarte está vacío"}
        jugador = self.jugadores[id_jugador]
        carta = self.descarte.pop()
        jugador.mano.append(carta)
        self.fase = FaseTurno.ACCIONES
        return {"accion": "robar_descarte", "carta": carta.to_dict()}

    def bajar(self, id_jugador: int, combinaciones_data: list[dict]) -> dict:
        """
        Poner combinaciones en la mesa por primera vez.
        combinaciones_data: [{"tipo": "tercia"|"escalera", "iids": [int, ...]}, ...]
        """
        if err := self._check_turno(id_jugador, FaseTurno.ACCIONES):
            return err
        jugador = self.jugadores[id_jugador]

        combs, err = self._construir_combinaciones(combinaciones_data, jugador.mano)
        if err:
            return {"error": err}

        for comb in combs:
            if not comb.es_valida():
                return {"error": f"Combinación inválida: {[str(c) for c in comb.cartas]}"}

        total = sum(c.valor_total() for c in combs)

        # Primera bajada: requiere ≥51 pts. Bajadas posteriores: sin restricción de puntos.
        if not jugador.bajado and total < LIMITE_BAJADA:
            return {"error": f"Tus combinaciones suman {total} puntos. Necesitas al menos {LIMITE_BAJADA}"}

        # Aplicar: sacar cartas de mano y ponerlas en mesa
        for comb in combs:
            comb.ordenar_cartas()
            for carta in comb.cartas:
                jugador.mano.remove(carta)
            self.mesa.append((id_jugador, comb))
        jugador.bajado = True

        return {
            "accion": "bajar",
            "combinaciones": len(combs),
            "puntos_bajada": total,
            "cartas_restantes": len(jugador.mano),
        }

    def agregar_a_combinacion(self, id_jugador: int, idx_mesa: int, iids: list[int]) -> dict:
        """Añadir cartas a una combinación ya en mesa (requiere estar bajado)."""
        if err := self._check_turno(id_jugador, FaseTurno.ACCIONES):
            return err
        jugador = self.jugadores[id_jugador]
        if not jugador.bajado:
            return {"error": "Debes bajarte primero"}
        if idx_mesa >= len(self.mesa):
            return {"error": "Combinación no encontrada"}

        cartas, err = self._buscar_en_mano(jugador, iids)
        if err:
            return {"error": err}

        _, comb = self.mesa[idx_mesa]
        nueva = Combinacion(comb.tipo, comb.cartas + cartas)
        if not nueva.es_valida():
            return {"error": "Las cartas no encajan en esa combinación"}

        # Escalera con joker: verificar que el comodín no "cambie" de posición
        if comb.tipo == "escalera" and any(c.es_joker for c in comb.cartas):
            idx_orig = comb._joker_indice_escalera()
            idx_nueva = nueva._joker_indice_escalera()
            if idx_orig != idx_nueva:
                return {"error": "Esa posición ya está ocupada por el comodín; solo puedes extender por los extremos libres"}

        nueva.ordenar_cartas()
        for c in cartas:
            jugador.mano.remove(c)
        self.mesa[idx_mesa] = (self.mesa[idx_mesa][0], nueva)

        return {"accion": "agregar", "cartas_agregadas": len(cartas), "cartas_restantes": len(jugador.mano)}

    def swap_joker(self, id_jugador: int, idx_mesa: int, iid_carta_real: int, iid_joker: int) -> dict:
        """
        Intercambiar un comodín en mesa por la carta real que representa.
        El comodín pasa a la mano del jugador y debe usarse en este mismo turno.
        """
        if err := self._check_turno(id_jugador, FaseTurno.ACCIONES):
            return err
        jugador = self.jugadores[id_jugador]
        if not jugador.bajado:
            return {"error": "Debes bajarte primero"}
        if idx_mesa >= len(self.mesa):
            return {"error": "Combinación no encontrada"}

        _, comb = self.mesa[idx_mesa]

        joker = next((c for c in comb.cartas if c.es_joker and c.iid == iid_joker), None)
        if not joker:
            return {"error": "Comodín no encontrado en esa combinación"}

        carta_real = next((c for c in jugador.mano if c.iid == iid_carta_real), None)
        if not carta_real:
            return {"error": "La carta real no está en tu mano"}

        nueva_lista = [carta_real if c.iid == iid_joker else c for c in comb.cartas]
        nueva = Combinacion(comb.tipo, nueva_lista)
        if not nueva.es_valida():
            return {"error": "La carta real no puede reemplazar al comodín en esa posición"}

        jugador.mano.remove(carta_real)
        self.mesa[idx_mesa] = (self.mesa[idx_mesa][0], nueva)
        jugador.mano.append(joker)  # el comodín vuelve a la mano

        return {
            "accion": "swap_joker",
            "joker_en_mano": joker.to_dict(),
            "nota": "El comodín debe usarse en este mismo turno",
        }

    def descartar(self, id_jugador: int, iid_carta: int) -> dict:
        """Descartar una carta y terminar el turno."""
        if err := self._check_turno(id_jugador, FaseTurno.ACCIONES):
            return err
        jugador = self.jugadores[id_jugador]

        carta = next((c for c in jugador.mano if c.iid == iid_carta), None)
        if not carta:
            return {"error": "La carta no está en tu mano"}

        jugador.mano.remove(carta)
        self.descarte.append(carta)
        resultado: dict = {"accion": "descartar", "carta": carta.to_dict()}

        if len(jugador.mano) == 0:
            self.finalizada = True
            self.ganador_ronda = id_jugador
            resultado["ronda_terminada"] = True
            resultado["ganador"] = id_jugador
            resultado["penalizaciones"] = {
                pid: est.penalizacion_total()
                for pid, est in self.jugadores.items()
                if pid != id_jugador
            }
        else:
            self._avanzar_turno()
            resultado["siguiente_jugador"] = self.jugador_activo()

        return resultado

    # ── IA ─────────────────────────────────────────────────────────────────────

    def ejecutar_turno_ia(self) -> list[dict]:
        """Ejecuta el turno completo de la IA activa y devuelve log de acciones."""
        pid = self.jugador_activo()
        if pid is None or not self.jugadores[pid].es_ia:
            return []

        log = []
        jugador = self.jugadores[pid]

        # 1. Robar del mazo
        res = self.robar_mazo(pid)
        log.append(res)

        # 2. Intentar bajarse si aún no lo hizo
        if not jugador.bajado:
            combs = _ia_encontrar_bajada(jugador.mano)
            if combs and sum(c.valor_total() for c in combs) >= LIMITE_BAJADA:
                data = [{"tipo": c.tipo, "iids": [x.iid for x in c.cartas]} for c in combs]
                res = self.bajar(pid, data)
                log.append(res)

        # 3. Si ya está bajado, intentar agregar cartas a mesa
        if jugador.bajado:
            for idx, (_, comb) in enumerate(self.mesa):
                for carta in jugador.mano[:]:
                    if carta.es_joker:
                        continue
                    nueva = Combinacion(comb.tipo, comb.cartas + [carta])
                    if nueva.es_valida():
                        res = self.agregar_a_combinacion(pid, idx, [carta.iid])
                        log.append(res)
                        break

        # 4. Descartar la carta menos útil
        if jugador.mano:
            descartar = _ia_elegir_descarte(jugador.mano, self.mesa)
            res = self.descartar(pid, descartar.iid)
            log.append(res)

        return log

    # ── Estado ─────────────────────────────────────────────────────────────────

    def estado(self, para_jugador: Optional[int] = None) -> dict:
        return {
            "finalizada": self.finalizada,
            "ganador_ronda": self.ganador_ronda,
            "jugador_activo": self.jugador_activo(),
            "fase": self.fase,
            "mazo_restante": len(self.mazo),
            "tope_descarte": self.descarte[-1].to_dict() if self.descarte else None,
            "mesa": [
                {"propietario": pid, "combinacion": comb.to_dict()}
                for pid, comb in self.mesa
            ],
            "jugadores": {
                pid: est.to_dict(ocultar_mano=(para_jugador is not None and pid != para_jugador))
                for pid, est in self.jugadores.items()
            },
        }

    # ── Helpers privados ───────────────────────────────────────────────────────

    def _check_turno(self, id_jugador: int, fase: FaseTurno) -> Optional[dict]:
        if self.finalizada:
            return {"error": "La partida ya finalizó"}
        if self.jugador_activo() != id_jugador:
            return {"error": "No es tu turno"}
        if self.fase != fase:
            return {"error": f"Acción no permitida en fase '{self.fase}'. Se esperaba '{fase}'"}
        return None

    def _construir_combinaciones(
        self, data: list[dict], mano: list[Carta]
    ) -> tuple[list[Combinacion], Optional[str]]:
        resultado = []
        usadas: set[int] = set()
        for item in data:
            tipo = item.get("tipo")
            if tipo not in ("tercia", "escalera"):
                return [], f"Tipo de combinación inválido: {tipo}"
            cartas = []
            for iid in item.get("iids", []):
                carta = next((c for c in mano if c.iid == iid and c.iid not in usadas), None)
                if not carta:
                    return [], f"Carta con iid={iid} no encontrada en tu mano"
                cartas.append(carta)
                usadas.add(iid)
            resultado.append(Combinacion(tipo, cartas))
        return resultado, None

    def _buscar_en_mano(
        self, jugador: EstadoJugador, iids: list[int]
    ) -> tuple[list[Carta], Optional[str]]:
        cartas = []
        for iid in iids:
            carta = next((c for c in jugador.mano if c.iid == iid), None)
            if not carta:
                return [], f"Carta con iid={iid} no encontrada en tu mano"
            cartas.append(carta)
        return cartas, None

    def _avanzar_turno(self) -> None:
        self.turno_idx = (self.turno_idx + 1) % len(self.orden)
        self.fase = FaseTurno.ROBAR

    # ── Serialización ──────────────────────────────────────────────────────────

    def serializar(self) -> dict:
        def carta_a_dict(c: Carta) -> dict:
            return {"palo": c.palo, "valor": c.valor_nombre, "iid": c.iid}

        return {
            "mazo": [carta_a_dict(c) for c in self.mazo.cartas],
            "descarte": [carta_a_dict(c) for c in self.descarte],
            "jugadores": {
                str(pid): {
                    "mano": [carta_a_dict(c) for c in est.mano],
                    "bajado": est.bajado,
                    "es_ia": est.es_ia,
                    "dificultad": est.dificultad,
                }
                for pid, est in self.jugadores.items()
            },
            "orden": self.orden,
            "turno_idx": self.turno_idx,
            "fase": self.fase.value,
            "mesa": [
                {"propietario": pid, "tipo": comb.tipo,
                 "cartas": [carta_a_dict(c) for c in comb.cartas]}
                for pid, comb in self.mesa
            ],
            "finalizada": self.finalizada,
            "ganador_ronda": self.ganador_ronda,
        }

    @classmethod
    def desde_estado(cls, data: dict) -> "Motor51":
        def hacer_carta(d: dict) -> Carta:
            return Carta(d["palo"], d["valor"], d["iid"])

        motor: Motor51 = object.__new__(cls)

        mazo_obj: Mazo = object.__new__(Mazo)
        mazo_obj.cartas = [hacer_carta(d) for d in data["mazo"]]
        motor.mazo = mazo_obj

        motor.descarte = [hacer_carta(d) for d in data["descarte"]]
        motor.jugadores = {}
        for pid_str, jdata in data["jugadores"].items():
            pid = int(pid_str)
            motor.jugadores[pid] = EstadoJugador(
                id_jugador=pid,
                es_ia=jdata["es_ia"],
                dificultad=jdata["dificultad"],
                mano=[hacer_carta(d) for d in jdata["mano"]],
                bajado=jdata["bajado"],
            )

        motor.orden = data["orden"]
        motor.turno_idx = data["turno_idx"]
        motor.fase = FaseTurno(data["fase"])
        motor.mesa = [
            (item["propietario"], Combinacion(item["tipo"], [hacer_carta(d) for d in item["cartas"]]))
            for item in data["mesa"]
        ]
        motor.finalizada = data["finalizada"]
        motor.ganador_ronda = data["ganador_ronda"]
        return motor


# ── Lógica de IA ───────────────────────────────────────────────────────────────

def _ia_encontrar_bajada(mano: list[Carta]) -> list[Combinacion]:
    """Busca combinaciones válidas en la mano que en conjunto sumen ≥ 51."""
    jokers = [c for c in mano if c.es_joker]
    normales = [c for c in mano if not c.es_joker]
    encontradas: list[Combinacion] = []
    usadas: set[int] = set()

    # Buscar tercias (mismo valor, palos distintos)
    por_valor: dict[str, list[Carta]] = {}
    for c in normales:
        por_valor.setdefault(c.valor_nombre, []).append(c)

    for valor, grupo in sorted(por_valor.items(), key=lambda x: -VALOR_BAJADA.get(x[0], 0)):
        palos_vistos: set[str] = set()
        unico = [c for c in grupo if c.iid not in usadas and c.palo not in palos_vistos
                 and not palos_vistos.add(c.palo)]  # type: ignore[func-returns-value]
        if len(unico) >= 3:
            comb = Combinacion("tercia", unico[:4])
            if comb.es_valida():
                encontradas.append(comb)
                usadas.update(c.iid for c in comb.cartas)

    # Buscar escaleras (mismo palo, valores consecutivos)
    por_palo: dict[str, list[Carta]] = {}
    for c in normales:
        if c.palo and c.iid not in usadas:
            por_palo.setdefault(c.palo, []).append(c)

    for palo, grupo in por_palo.items():
        ord_grupo = sorted(
            {c.valor_nombre: c for c in grupo if c.iid not in usadas}.values(),
            key=lambda c: ORDEN[c.valor_nombre]
        )
        run: list[Carta] = []
        for c in ord_grupo:
            if not run:
                run = [c]
            elif ORDEN[c.valor_nombre] - ORDEN[run[-1].valor_nombre] == 1:
                run.append(c)
            else:
                if len(run) >= 3:
                    comb = Combinacion("escalera", run)
                    if comb.es_valida():
                        encontradas.append(comb)
                        usadas.update(x.iid for x in run)
                run = [c]
        if len(run) >= 3:
            comb = Combinacion("escalera", run)
            if comb.es_valida():
                encontradas.append(comb)
                usadas.update(x.iid for x in run)

    return encontradas if sum(c.valor_total() for c in encontradas) >= LIMITE_BAJADA else []


def _ia_elegir_descarte(mano: list[Carta], mesa: list) -> Carta:
    """Descarta la carta menos útil (menor potencial de combinación)."""
    normales = [c for c in mano if not c.es_joker]
    if not normales:
        return mano[0]  # si solo tiene jokers, devuelve el primero (no debería pasar)

    por_valor: dict[str, int] = {}
    por_palo: dict[str, list[Carta]] = {}
    for c in normales:
        por_valor[c.valor_nombre] = por_valor.get(c.valor_nombre, 0) + 1
        por_palo.setdefault(c.palo or "", []).append(c)

    def utilidad(carta: Carta) -> int:
        score = por_valor.get(carta.valor_nombre, 0) * 3
        idx = ORDEN.get(carta.valor_nombre, 0)
        for vecina in por_palo.get(carta.palo or "", []):
            if vecina.iid != carta.iid:
                diff = abs(ORDEN.get(vecina.valor_nombre, 0) - idx)
                if diff <= 2:
                    score += 3 - diff
        return score

    return min(normales, key=lambda c: (utilidad(c), c.valor_bajada))
