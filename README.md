# Escape Island — Roblox

Juego de escape por isla: llegás en balsa, recorrés un mapa enorme tipo laberinto, superás desafíos con dificultad creciente, recolectás recursos, crafteás objetos y guardás progreso en checkpoints.

## Requisitos

- [Roblox Studio](https://create.roblox.com/)
- [Rojo](https://rojo.space/) 7.x (recomendado con [Aftman](https://github.com/LPGhatguy/aftman))

## Instalación rápida

### 1. Instalar herramientas

```powershell
# En la carpeta del proyecto
aftman install
```

Si no tenés Aftman, instalá Rojo manualmente desde https://github.com/rojo-rbx/rojo/releases

### 2. Abrir en Studio (forma fácil — recomendada)

**Doble clic en `ABRIR-EN-STUDIO.bat`**

Eso compila y abre `EscapeIsland.rbxlx` en Studio **sin usar el plugin Rojo**.

Si no se abre solo:

1. Abrí **Roblox Studio**
2. **Archivo** → **Abrir desde archivo** (Open from File)
3. Elegí: `juego isla para roblox\EscapeIsland.rbxlx`
4. Pulsá **F5** para jugar

No uses **“Abrir con Rojo”** del plugin si te trae el otro juego.

### 2b. Crear lugar nuevo (solo si usás Rojo en vivo)

### 3. Sincronizar con Rojo (si te trae el OTRO juego)

El plugin de Studio **siempre usa el puerto 34872**. Si el otro juego tiene `rojo serve` activo, Studio muestra ese juego aunque abras Baseplate nueva.

**Solución:** usar el script de esta carpeta, que **cierra** lo que esté en 34872 y arranca **Escape Island** ahí.

1. Abrí solo esta carpeta en Cursor: `juego isla para roblox` (o `EscapeIsland.code-workspace`).
2. **No** ejecutes `rojo serve` en la carpeta del otro juego.
3. En esta carpeta:

```powershell
.\iniciar-rojo.ps1
```

(o doble clic en `iniciar-rojo.bat`)

4. Esperá el mensaje: `Rojo server listening on 127.0.0.1:34872`
5. En Studio (Baseplate nueva) → plugin **Rojo** → **Connect** (34872, el predeterminado).

**Comprobación:** en el Explorer deberías ver `EscapeIsland`, `Server`, `GameUI`.  
Si ves `AldeaConquest` u otra cosa, el otro Rojo sigue activo: cerrá esa terminal y volvé a ejecutar `iniciar-rojo.ps1`.

### 4. Probar

Pulsá **Play (F5)**. Deberías:

- Aparecer en una **balsa** que llega a la playa (primera vez).
- Ver el **HUD** (inventario, crafteo, progreso).
- Explorar zonas con etiquetas (Playa, Selva, Río, etc.).
- Tocar **checkpoints** azules para guardar.
- Usar **ProximityPrompt** para recolectar y resolver puzzles.

## Estructura del proyecto

```
src/
  shared/Config/GameConfig.lua   ← Desafíos, recursos, islas, recetas
  server/                        ← Lógica servidor, mapa, puzzles
  client/                        ← UI y notificaciones
  gui/                           ← Interfaz (StarterGui)
  remotes/                       ← RemoteEvents
```

## Cómo funciona el juego

| Sistema | Descripción |
|--------|-------------|
| **12 desafíos** (Isla 1) | Playa → Selva → Río → Piedras → Laguna → Cuevas → Castillo → Persecución → Dodge → Volcán → Interior → Escape |
| **Recursos** | Madera, piedra, liana, concha, mineral, cristal, brasa |
| **Crafteo** | Antorcha, balsa, puente, máscara, llave, escudo térmico, bote |
| **Checkpoints** | Una parte por desafío; botón "Checkpoint" para reaparecer |
| **Islas** | Al completar Isla 1 se desbloquea **Isla Helada** (botón "Isla 2") |

### Enigmas incluidos (ejemplos)

- **Selva**: activar señales en orden 1→5.
- **Laguna**: conchas en orden 3, 1, 4, 2.
- **Castillo**: estatuas en orden 2, 4, 1, 3.

## Decoración procedural (Isla 1)

El módulo `src/server/Map/PropGenerator.lua` genera automáticamente:

- **~45 palmeras** dispersas + palmeras por zona (playa, selva, laguna, persecución…)
- **Rocas** con varios estilos (musgo, volcánica, arena, gris)
- **Volcán** con cono en capas, cráter con lava, humo, fuego y sendero en espiral
- **Selva**: laberinto con copas de árbol, helechos, arbustos
- **Río** con orillas, rocas y anclas de puente
- **Laguna** con orilla, juncos y conchas brillantes
- **Cuevas** con arco de entrada, estalactitas, cristales y antorchas
- **Castillo** en ruinas (torres, murallas, patio, puerta)
- **Parkour** con piedras irregulares y musgo
- **Colinas**, senderos de tierra entre zonas y costa rocosa

Cada vez que iniciás el servidor, el mapa se **regenera** (se destruye el anterior y se crea uno nuevo).

## Hacer el mapa aún más grande en Studio

El `MapBuilder` genera una isla de ~1300 studs con zonas separadas. Para pulir visualmente:

1. En **Workspace → EscapeIsland**, editá cada carpeta en `Zones`.
2. Usá el **Editor de Terreno** para selva, ríos, playa y volcán.
3. Importá modelos gratis del **Toolbox** (ruinas, cuevas, palmeras).
4. Mantené los nombres importantes:
   - `Spawn`, `ZoneBounds`, `Finish`, `Checkpoints`
   - Partes `Lava` o atributo `IsLava`
   - `Resource_Wood` con atributo `ResourceId`

## Varias islas (recomendación)

El juego ya soporta:

- **Isla 1 — Tropical** (completa, 12 desafíos)
- **Isla 2 — Helada** (esqueleto; expandir en Studio)
- **Isla 3 — Desierto** (configurada, bloqueada hasta completar Isla 2)

**Sugerencia:** no repetir el mismo layout; cambiar mecánicas (hielo resbaladizo, tormentas de arena, dunas). Así evitás monotonía sin rehacer todo el código.

## Publicar

1. Activá **Game Settings → Security → Enable Studio Access to API Services** (para DataStore en pruebas reales).
2. **File → Publish to Roblox**.
3. En producción, los datos se guardan con DataStore `EscapeIsland_v1`.

## Comandos útiles

```powershell
rojo serve          # Sincronizar en vivo
rojo build -o EscapeIsland.rbxlx   # Exportar lugar
```

## Próximos pasos sugeridos

- [ ] Terreno artístico por zona en Studio
- [ ] Música y sonidos por bioma
- [ ] Animaciones del guardián de persecución
- [ ] Más desafíos en Isla 2 y 3
- [ ] Tienda de gamepasses (pistas, skins)

---

Proyecto generado para curso / desarrollo en Roblox Studio con **Rojo + Luau**.
