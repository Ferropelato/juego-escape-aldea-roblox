# Escape Island — Roblox

Juego de escape por islas: llegás en balsa, recorrés mapas generados proceduralmente, superás desafíos con dificultad creciente, recolectás recursos, crafteás objetos y guardás progreso en checkpoints. Tres islas desbloqueables con mecánicas únicas, sistema de logros, tienda ética y recompensas diarias con racha.

> **Repositorio:** https://github.com/Ferropelato/juego-escape-aldea-roblox  
> **Estado actual:** producción-ready salvo los ítems marcados en [Checklist de publicación](#checklist-de-publicación)

---

## Índice

1. [Requisitos](#requisitos)
2. [Instalación y desarrollo local](#instalación-y-desarrollo-local)
3. [Arquitectura del proyecto](#arquitectura-del-proyecto)
4. [Sistemas implementados](#sistemas-implementados)
5. [Auditoría técnica — lo que se hizo](#auditoría-técnica--lo-que-se-hizo)
6. [Checklist de publicación](#checklist-de-publicación)
7. [Guía de publicación en Roblox](#guía-de-publicación-en-roblox)
8. [Comandos útiles](#comandos-útiles)

---

## Requisitos

- [Roblox Studio](https://create.roblox.com/)
- [Rojo](https://rojo.space/) 7.x
- [Aftman](https://github.com/LPGhatguy/aftman) (gestor de herramientas, recomendado)

---

## Instalación y desarrollo local

### 1. Instalar herramientas

```powershell
aftman install
```

Si no tenés Aftman, instalá Rojo manualmente desde https://github.com/rojo-rbx/rojo/releases

### 2. Iniciar Rojo

```powershell
.\iniciar-rojo.ps1
# o directamente:
rojo serve default.project.json
```

El servidor queda en `localhost:34872`.

### 3. Conectar Studio

1. Abrí Roblox Studio → **New Baseplate**
2. Plugin **Rojo** → **Connect** (puerto 34872, predeterminado)
3. Verificá en el Explorer que ves `EscapeIsland`, `Server`, `Client`
4. Pulsá **F5** para probar

### 4. Exportar lugar (.rbxlx)

```powershell
rojo build -o EscapeIsland.rbxlx
```

Doble clic en `ABRIR-EN-STUDIO.bat` para compilar y abrir directo sin el plugin.

---

## Arquitectura del proyecto

```
src/
├── shared/
│   ├── Config/
│   │   └── GameConfig.lua        ← Desafíos, recursos, islas, recetas, tienda, logros
│   └── Types/
│       └── PlayerData.lua        ← Tipos y datos por defecto del jugador
├── server/
│   ├── Services/                 ← Lógica de servidor (18 módulos)
│   │   ├── DataService.lua       ← Persistencia con DataStore
│   │   ├── ChallengeService.lua  ← Progresión de desafíos
│   │   ├── ResourceService.lua   ← Recolección de recursos
│   │   ├── CraftingService.lua   ← Fabricación de objetos
│   │   ├── CheckpointService.lua ← Guardado de progreso
│   │   ├── SpawnService.lua      ← Spawn y reaparición
│   │   ├── AchievementService.lua← Logros
│   │   ├── RewardService.lua     ← Recompensas diarias y por zona
│   │   ├── WildlifeService.lua   ← IA de criaturas
│   │   ├── HazardService.lua     ← Peligros ambientales
│   │   ├── MonetizationService.lua← Gamepasses y productos
│   │   └── ...otros servicios
│   ├── Challenges/
│   │   └── ChallengeBehaviors.lua← Comportamientos por tipo de desafío
│   └── Map/
│       ├── MapBuilder.lua        ← Generación de isla principal
│       └── PropGenerator.lua     ← Decoración procedural
├── client/
│   └── Controllers/              ← Lógica de cliente (13 módulos)
│       ├── HudBuilder.lua        ← Construcción del HUD (responsive)
│       ├── ActionsController.lua ← Botones, recompensa diaria
│       ├── CraftingController.lua← Panel de crafteo
│       ├── ShopController.lua    ← Tienda
│       ├── AchievementController.lua
│       ├── NotificationController.lua
│       ├── ZoneDisplayController.lua
│       └── ...otros controllers
├── remotes/                      ← Definiciones de RemoteEvents/Functions
├── gui/                          ← StarterGui
└── serverstorage/                ← Plantillas de desafíos
```

**Rojo mapea** `src/server` → `ServerScriptService`, `src/client` → `StarterPlayerScripts`, `src/shared` → `ReplicatedStorage/Shared`.

---

## Sistemas implementados

### Contenido de juego

| Sistema | Estado | Descripción |
|---------|--------|-------------|
| **Isla 1 — Tropical** | ✅ Completa | 12 desafíos: Playa → Selva → Río → Piedras → Laguna → Cuevas → Castillo → Persecución → Dodge → Volcán → Interior → Escape |
| **Isla 2 — Helada** | ✅ Jugable | Desafíos de hielo con mecánicas de resbalamiento |
| **Isla 3 — Desierto** | ✅ Jugable | Templo, dunas, tormenta de arena final |
| **Recursos (7 tipos)** | ✅ | Madera, piedra, liana, concha, mineral, cristal, brasa |
| **Crafteo (7 recetas)** | ✅ | Antorcha, balsa, puente, máscara, llave, escudo térmico, bote |
| **13 logros** | ✅ | Con progreso persistente y notificaciones |
| **Onboarding** | ✅ | Tutorial guiado de 5 pasos para jugadores nuevos |
| **Checkpoints** | ✅ | Por desafío; botón de reaparición en HUD |

### Economía y retención

| Sistema | Estado | Descripción |
|---------|--------|-------------|
| **Recompensa diaria** | ✅ | Botón en HUD, pool de recursos aleatorios |
| **Racha de login** | ✅ | Multiplicadores ×1 / ×1.5 / ×2 / ×3 (días 1/2/3/7+) |
| **Recompensas por zona** | ✅ | Recursos al completar cada desafío |
| **Tienda ética** | ✅ | Solo cosméticos y QoL — sin pay-to-win |
| **Gamepasses** | ✅ | VIP, trails — configurar en Creator Dashboard |
| **Productos Dev** | ✅ | Revive token — configurar en Creator Dashboard |

### Técnicos

| Sistema | Estado | Descripción |
|---------|--------|-------------|
| **DataStore** | ✅ | `UpdateAsync` + retry + `BindToClose` |
| **UI Responsive** | ✅ | `UIScale` dinámico, `AnchorPoint`, landscape mobile |
| **Seguridad** | ✅ | Validación server-side en todos los RemoteEvents |
| **IA de criaturas** | ✅ | Throttle 10Hz pasivos / 2Hz agresivos |
| **Peligros** | ✅ | Kill plane único por puente (no 360 spikes) |

---

## Auditoría técnica — lo que se hizo

Esta sección documenta la auditoría completa y las mejoras aplicadas en el commit `5849250`.

### Bugs críticos resueltos

#### ChallengeBehaviors — memory leaks y daño múltiple

| # | Bug | Impacto | Fix |
|---|-----|---------|-----|
| 1 | `Heartbeat` en `startChase` nunca se desconectaba | Leak permanente por sesión | La conexión se guarda y desconecta cuando `zoneFolder.Parent == nil` |
| 2 | Proyectiles en `startDodge` golpeaban múltiples veces | Jugadores morían instantáneamente | Flag `hit = true` por proyectil; un solo impacto |
| 3 | Lava en `startLavaDamage` aplicaba daño 60 veces/segundo | Muerte instantánea en cualquier contacto | Cooldown de 0.6s por personaje con tabla `lavaCooldown` |

#### WildlifeService — IA desbordando el hilo del servidor

| # | Bug | Impacto | Fix |
|---|-----|---------|-----|
| 4 | Bucle de criaturas corriendo a 60Hz para todos los jugadores | CPU del servidor al 100% con pocos jugadores | Throttle 10Hz pasivos (`PASSIVE_TICK = 0.1`), 2Hz para búsqueda de objetivo |
| 5 | Sin cooldown de daño en contacto | Daño instáneo al tocar criatura | Cooldown 1s por personaje |

#### DataService — riesgo de pérdida de datos

| # | Bug | Impacto | Fix |
|---|-----|---------|-----|
| 6 | `SetAsync` sin manejo de condición de carrera | Datos corruptos si dos saves simultáneos | `UpdateAsync` que recibe el valor anterior |
| 7 | Sin `BindToClose` | Datos perdidos al apagar el servidor | `BindToClose` guarda todos los jugadores en cache; espera hasta 25s |
| 8 | Sin retry en caso de fallo | Pérdida silenciosa de progreso | Retry con `task.delay(3)` si el primer save falla |

#### HazardService — colapso de performance

| # | Bug | Impacto | Fix |
|---|-----|---------|-----|
| 9 | 360 spikes (`Part`) generados en bucle anidado por puente | 3000+ partes con `Touched` activo → lag severo | 1 kill plane invisible por puente + 4 spikes decorativos (`CanCollide=false`, sin `Touched`) |

#### AchievementService — lógica rota

| # | Bug | Impacto | Fix |
|---|-----|---------|-----|
| 10 | Logro "Survivor" chequeaba datos persistentes (muertes de sesiones anteriores) | Logro imposible de conseguir en la práctica | `SpawnService.getSessionDeaths()` — contador de muertes por sesión actual |

### Mejoras de gameplay y retención

#### Sistema de racha diaria (retención D1/D7)

- Campo `loginStreak` agregado a `PlayerData`
- Multiplicadores: ×1 (día 1) → ×1.5 (día 2) → ×2 (día 3-6) → ×3 (día 7+)
- La racha se mantiene si el jugador vuelve dentro de 48h (margen de tolerancia)
- Botón prominente en el HUD principal (antes solo estaba en la tienda)

#### Feedback de crafteo

- Antes: `"Faltan recursos"` (genérico)
- Ahora: `"Te falta: 3 Madera, 1 Brasa"` (específico)

#### Feedback de checkpoint

- Antes: guardado silencioso
- Ahora: `"✅ Progreso guardado en: [zona]"` con throttle de 5s (no spam)

#### ResourceService — cleanup de memoria

- Las entradas expiradas del mapa `COOLDOWN` se limpian automáticamente cada 10s para evitar crecimiento de memoria en sesiones largas

### UI Responsive

#### HudBuilder — sistema de escala dinámica

- `UIScale` con `Scale = math.clamp(min(vp.Y/768, vp.X/1200), 0.55, 1.0)`
- Se recalcula en `camera:GetPropertyChangedSignal("ViewportSize")`
- En pantallas < 420px de alto (landscape mobile angosto): HUD se mueve al borde inferior izquierdo para liberar la vista central
- Botones 34px en touch vs 28px en PC (`GuiService.TouchEnabled`)

#### Paneles con AnchorPoint correcto

| Panel | Antes | Después |
|-------|-------|---------|
| CraftingPanel | `Position(0.5,-160, 0,0)` hardcoded | `AnchorPoint(1,0)` → borde derecho, tamaño calculado vs viewport |
| ShopPanel | offset fijo | `AnchorPoint(0.5,0.5)` → centro absoluto |
| AchievementPanel | posición fija | `AnchorPoint(0,1)` → borde inferior izquierdo |
| ZoneHint (zona activa) | `Position(0.5,-160, 0,8)` | `AnchorPoint(0.5,0)` → centrado real |

#### NotificationController — apilado correcto

- `UIListLayout` reemplaza posicionamiento manual hardcoded
- Máximo 4 notificaciones simultáneas (antes podían solaparse infinitamente)
- Fade in/out con `TweenService`

---

## Checklist de publicación

### Obligatorio antes de publicar

- [ ] **Configurar IDs de gamepass en GameConfig.lua**
  - `GAMEPASS_VIP` — crear en Creator Dashboard → Monetización → Gamepasses
  - `GAMEPASS_TRAILS` — ídem
  - Reemplazar los valores `0` placeholder por los IDs reales

- [ ] **Configurar ID de producto Dev (Revive Token)**
  - `DEV_PRODUCT_REVIVE` en `GameConfig.lua`
  - Crear en Creator Dashboard → Monetización → Productos de desarrollador

- [ ] **Habilitar DataStore en Game Settings**
  - Studio → Game Settings → Security → **Enable Studio Access to API Services** ✓
  - En producción se activa automáticamente; en pruebas de Studio es manual

- [ ] **Probar DataStore en modo servidor real**
  - Play → Start Server (no Solo) para verificar que los datos persisten entre sesiones
  - Verificar que `BindToClose` guarda correctamente (detener servidor durante juego)

- [ ] **Poblar el mapa en Studio**
  - El mapa se genera proceduralmente en runtime, pero las zonas necesitan revisión visual
  - Ajustar colisiones de partes generadas que puedan atrapar al jugador
  - Verificar que los checkpoints y puzzles sean alcanzables

- [ ] **Probar en dispositivo mobile real o emulador**
  - Studio → Test → Emulation → iPhone o tablet en landscape
  - Verificar que el HUD no tape zona de juego en 375×667 landscape
  - Verificar que los `ProximityPrompt` sean accesibles en touch

- [ ] **Audio**
  - Agregar `Sound` a las zonas (actualmente sin música)
  - Música por bioma: tropical, helado, desierto
  - SFX: recolección, crafteo, checkpoint, logro

- [ ] **Revisar nombre y descripción del juego**
  - Nombre atractivo y descriptivo
  - Thumbnail/icono (600×600 px mínimo)
  - Descripción con keywords para descubrimiento orgánico

### Recomendado (mejora retención)

- [ ] **Animaciones de personaje por desafío**
  - Guardián de persecución: animación de correr personalizada
  - Celebración al completar isla

- [ ] **Efectos de partículas**
  - Recolección de recursos
  - Crafteo exitoso
  - Logro desbloqueado

- [ ] **Leaderboard / tabla de puntajes**
  - `OrderedDataStore` con tiempo de completado por isla
  - Incentiva rejugabilidad y competencia

- [ ] **Sistema de amigos**
  - Mostrar progreso de amigos en el menú
  - Aumenta retención social

- [ ] **Pruebas de carga**
  - Usar Studio → Test → Start 5+ players para verificar que `WildlifeService` y `HazardService` no causan lag con múltiples jugadores simultáneos
  - Verificar que `DataService` maneja saves concurrentes sin errores

- [ ] **Testear los 13 logros**
  - Verificar que cada logro se puede desbloquear en condiciones normales
  - Verificar que "Survivor" requiere 0 muertes en la sesión actual

- [ ] **Completar Isla 2 e Isla 3**
  - Isla 2 (Helada): agregar mecánica de hielo resbaladizo, más desafíos
  - Isla 3 (Desierto): expandir templo, agregar más puzzles de dunas

### Opcional (post-lanzamiento)

- [ ] **Analytics de jugadores** (via `AnalyticsService` o servicio externo)
- [ ] **A/B testing de dificultad** en desafíos con más abandono
- [ ] **Evento de temporada** (Halloween, Navidad) con isla temporal
- [ ] **Sistema de guilds/equipos** para modo coop

---

## Guía de publicación en Roblox

### 1. Compilar el lugar

```powershell
rojo build -o EscapeIsland.rbxlx
```

### 2. Publicar desde Studio

1. Abrir `EscapeIsland.rbxlx` en Studio
2. **File** → **Publish to Roblox As...**
3. Completar nombre, descripción, genre
4. Subir thumbnail

### 3. Configurar el lugar publicado

En [create.roblox.com](https://create.roblox.com):

- **Monetización** → crear gamepasses y productos Dev → copiar IDs a `GameConfig.lua`
- **Settings** → Access: **Public** cuando esté listo
- **Settings** → Max Players: recomendado 10-20 para mantener buen rendimiento de IA

### 4. Verificar antes de hacer público

```
Studio → Home → Game Settings → Security
  ✓ Allow HTTP Requests  (si se usa API externa)
  ✓ Enable Studio Access to API Services  (solo para pruebas)
```

En producción los DataStores funcionan sin esa opción; en Studio se necesita para testear.

---

## Comandos útiles

```powershell
# Iniciar servidor de desarrollo
rojo serve default.project.json

# Compilar lugar exportable
rojo build -o EscapeIsland.rbxlx

# Script de inicio (cierra Rojo anterior y arranca este)
.\iniciar-rojo.ps1

# Ver logs de Rojo con detalle
$env:RUST_LOG="info"; rojo serve default.project.json
```

---

## Estructura de commits

| Commit | Descripción |
|--------|-------------|
| `98b789b` | Juego funcional base: gameplay, UI, seguridad |
| `56d01de` | Isla 2 jugable, sistema de logros, onboarding |
| `b9b2456` | Isla 3 (Desierto) con templo, dunas y logros finales |
| `769b106` | Monetización ética, recompensas por zona, balance de crafteo |
| `c9bebd0` | Guía de gamepasses en Creator Dashboard |
| `5849250` | **Auditoría completa:** 10 bugs críticos, optimización de performance, UI responsive |

---

*Proyecto desarrollado para curso de Roblox. Stack: Luau + Rojo 7.x + DataStore v2.*
