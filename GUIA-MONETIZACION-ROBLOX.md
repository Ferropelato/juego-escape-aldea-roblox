# Guía: Configurar monetización en Roblox Creator Dashboard

Esta guía conecta la tienda de **Escape Island** con Roblox. Los productos ya están programados en el juego; solo falta crearlos en el dashboard y pegar los IDs en el código.

**Archivo a editar después:** `src/shared/Config/MonetizationConfig.lua`

---

## Requisitos previos

1. Tener una cuenta de Roblox con **13+ años** (o permisos de desarrollador en el grupo).
2. El juego publicado o al menos creado en [create.roblox.com](https://create.roblox.com).
3. **API de acceso a los servicios** activada:
   - Creator Dashboard → tu experiencia → **Configuración** → **Seguridad**
   - Activar **Enable Studio Access to API Services** (necesario para DataStore y compras en pruebas).

---

## Resumen de productos a crear

| # | Nombre en Roblox | Tipo | Precio sugerido | Campo en el código |
|---|------------------|------|-----------------|-------------------|
| 1 | Explorador VIP | Gamepass | 99 R$ | `Gamepasses.VipExplorer.gamePassId` |
| 2 | Maestro de rastros | Gamepass | 79 R$ | `Gamepasses.TrailMaster.gamePassId` |
| 3 | Pack explorador | Developer Product | 49 R$ | `DeveloperProducts.StarterBundle.productId` |
| 4 | Token de rescate | Developer Product | 25 R$ | `DeveloperProducts.ReviveToken.productId` |
| 5 | Badge Supporter | Developer Product | 35 R$ | `DeveloperProducts.SupporterBadge.productId` |

---

## Parte 1 — Crear los Gamepasses

### Paso 1: Abrir la sección de pases

1. Entrá a [create.roblox.com](https://create.roblox.com).
2. **Experiencias** → seleccioná **Escape Island** (o el nombre de tu juego).
3. Menú lateral: **Monetización** → **Pases**.
4. Clic en **Crear un pase**.

### Paso 2: Gamepass «Explorador VIP»

| Campo | Valor |
|-------|-------|
| **Nombre** | Explorador VIP |
| **Descripción** | Badge VIP en el HUD, rastro dorado y respawn más rápido (1.5s). Sin ventajas de combate ni desbloqueo de zonas. |
| **Precio** | 99 Robux |
| **Icono** | Imagen 512×512 (estrella dorada o brújula) |

1. Guardá el pase.
2. En la lista de pases, abrí **Explorador VIP**.
3. Copiá el **ID del pase** (número en la URL o en los detalles, ej. `https://www.roblox.com/game-pass/123456789/...` → el ID es `123456789`).

### Paso 3: Gamepass «Maestro de rastros»

Repetí el proceso:

| Campo | Valor |
|-------|-------|
| **Nombre** | Maestro de rastros |
| **Descripción** | Desbloquea 4 colores de rastro cosmético: Océano, Brasa y Escarcha (el dorado viene con VIP). |
| **Precio** | 79 Robux |

Copiá su **ID del pase**.

---

## Parte 2 — Crear Developer Products

### Paso 1: Abrir productos del desarrollador

1. En la misma experiencia: **Monetización** → **Productos para desarrolladores**.
2. Clic en **Crear un producto**.

> Los Developer Products son compras **consumibles** (se pueden comprar varias veces). El juego los procesa con `ProcessReceipt` en el servidor (ya implementado).

### Paso 2: Producto «Pack explorador»

| Campo | Valor |
|-------|-------|
| **Nombre** | Pack explorador |
| **Descripción** | Madera×5, Liana×3, Piedra×2. Ayuda para empezar — no salta zonas ni desafíos. |
| **Precio** | 49 Robux |

Guardá y copiá el **ID del producto**.

### Paso 3: Producto «Token de rescate»

| Campo | Valor |
|-------|-------|
| **Nombre** | Token de rescate |
| **Descripción** | Una reaparición instantánea en checkpoint sin esperar cooldown. |
| **Precio** | 25 Robux |

Copiá el **ID del producto**.

### Paso 4: Producto «Badge Supporter»

| Campo | Valor |
|-------|-------|
| **Nombre** | Badge Supporter |
| **Descripción** | Título 💖 permanente en tu HUD. ¡Gracias por apoyar el juego! |
| **Precio** | 35 Robux |

Copiá el **ID del producto**.

---

## Parte 3 — Pegar los IDs en el código

Abrí `src/shared/Config/MonetizationConfig.lua` y reemplazá cada `0` por el ID real:

```lua
MonetizationConfig.Gamepasses = {
	VipExplorer = {
		-- ...
		gamePassId = 123456789,  -- ← ID de Explorador VIP
	},
	TrailMaster = {
		-- ...
		gamePassId = 123456790,  -- ← ID de Maestro de rastros
	},
}

MonetizationConfig.DeveloperProducts = {
	StarterBundle = {
		-- ...
		productId = 234567891,  -- ← ID de Pack explorador
	},
	ReviveToken = {
		-- ...
		productId = 234567892,  -- ← ID de Token de rescate
	},
	SupporterBadge = {
		-- ...
		productId = 234567893,  -- ← ID de Badge Supporter
	},
}
```

Guardá el archivo. Si usás Rojo, los cambios se sincronizan solos a Studio.

---

## Parte 4 — Probar compras

### En Studio (pruebas locales)

1. Ejecutá `iniciar-rojo.ps1` y conectá Rojo en Studio.
2. **Iniciar** (Play) — la tienda mostrará los productos.
3. Las compras reales **no funcionan** con IDs en `0`. Con IDs reales:
   - Publicá el juego como **Privado** o **Público**.
   - En Studio: **Juego** → **Configuración de prueba** → activá compras de prueba si está disponible.
   - O probá en el juego publicado con una cuenta secundaria.

### En juego publicado (recomendado)

1. Publicá la experiencia (aunque sea en privado para testers).
2. Entrá al juego desde la web/app de Roblox (no solo Studio).
3. Abrí **🛒 Tienda** en el HUD.
4. Comprá con Robux de prueba o reales.

### Qué verificar después de cada compra

| Producto | Comportamiento esperado |
|----------|-------------------------|
| Explorador VIP | Título «⭐ VIP» en HUD, rastro dorado, respawn ~1.5s |
| Maestro de rastros | Sección de rastros en tienda con 4 colores |
| Pack explorador | +5 Madera, +3 Liana, +2 Piedra en inventario |
| Token de rescate | +1 token; botón ↩ CP sin espera una vez |
| Badge Supporter | Prefijo 💖 en el título del HUD |

---

## Parte 5 — Checklist antes de lanzar

- [ ] Los 5 IDs están en `MonetizationConfig.lua` (ninguno en `0`).
- [ ] API Services activada en configuración de la experiencia.
- [ ] Juego publicado al menos una vez (para que `ProcessReceipt` funcione en vivo).
- [ ] Probaste al menos 1 gamepass y 1 developer product en el juego publicado.
- [ ] Descripciones en Roblox coinciden con lo que hace el juego (sin prometer ventajas P2W).
- [ ] Iconos de gamepass subidos (512×512 PNG).

---

## Parte 6 — Textos sugeridos para la página del juego

Podés usar esto en la descripción de la experiencia en Roblox:

```
🏝️ ESCAPE ISLAND — Escapá de 3 islas misteriosas

Explorá, recolectá, crafteá y superá desafíos hasta lograr la libertad.

⭐ TIENDA ÉTICA (opcional):
• VIP: cosméticos y respawn más rápido
• Rastros de colores para tu personaje
• Packs de ayuda que NO saltan progresión

¡Todo el contenido se puede completar gratis!
```

---

## Preguntas frecuentes

### «La tienda dice: Configurá el Gamepass ID en Studio»

Los IDs siguen en `0`. Completá la Parte 3 con los números reales del dashboard.

### Compré un producto y no recibí nada

1. Verificá que `productId` en el código sea **exactamente** el del dashboard.
2. El servidor debe estar en un juego **publicado** (ProcessReceipt no procesa en Studio vacío).
3. Revisá la salida de Studio/servidor por `[EscapeIsland] Producto desconocido`.

### ¿Puedo cambiar precios después?

Sí, desde el Creator Dashboard. Los precios en `MonetizationConfig.lua` (`priceRobux`) son solo para mostrar en la UI; Roblox cobra el precio configurado en el dashboard.

### ¿Necesito habilitar algo más para DataStore?

Sí: la misma opción **Enable Studio Access to API Services** sirve para guardado y monetización en pruebas.

---

## Referencia rápida de archivos del proyecto

| Archivo | Función |
|---------|---------|
| `src/shared/Config/MonetizationConfig.lua` | IDs, precios y textos de la tienda |
| `src/server/Services/MonetizationService.lua` | Verificación de gamepasses y `ProcessReceipt` |
| `src/client/Controllers/ShopController.lua` | UI de la tienda |
| `src/client/Controllers/CosmeticController.lua` | Rastros y badges VIP/Supporter |

---

*Escape Island — monetización ética, sin pay-to-win.*
