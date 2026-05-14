# Error de red en Flutter (Panel representante / Dashboard)

**Con el prompt del final de este documento puedes corregir el flujo de forma sistemática.**  
Este archivo resume por qué aparece *"Error de red"* aunque a veces el fallo no sea “internet”, y qué debe hacer tu app móvil alineada con **este backend**.

---

## 1. Qué significa realmente “Error de red” en la app

En muchas apps Flutter, **“Error de red”** es un mensaje **genérico** que el código muestra cuando:

- falló `http.Client` / `Dio` (sin conexión, timeout, DNS, certificado), **o**
- el desarrollador mapea **cualquier excepción** (incluso **404, 401, 500 con body vacío**) a “Error de red” por simplificar.

Por eso puede “botar cada rato” aunque el Wi‑Fi esté bien: **el servidor responde mal o la petición está mal formada**, y la UI lo etiqueta mal.

---

## 2. Causas probables (ordenadas por frecuencia con este backend)

### A) URL base incorrecta o mezclada

- **Emulador Android** → backend local: suele ser `http://10.0.2.2:5070` (no `localhost`).
- **Dispositivo físico** → backend local: debe ser la **IP de tu PC** en la LAN, no `10.0.2.2`.
- **Producción (Azure)** → debe ser exactamente el host que da el portal, por ejemplo:
  `https://budgetly-api-dev-dxcfedfvdxeebad5.chilecentral-01.azurewebsites.net`  
  (no el nombre corto `*.azurewebsites.net` si tu recurso usa **hostname único seguro** con sufijo regional).

Si la base URL está mal, obtendrás fallo repetido en **todas** las pantallas que llamen API.

### B) Peticiones autenticadas sin `Authorization: Bearer <token>`

Tu API usa middleware que exige JWT en la mayoría de rutas. Si el dashboard del representante llama a un endpoint protegido **sin token** o con token **expirado**, el servidor puede responder **401** o fallar de forma que el cliente lo trate como error genérico.

### C) El backend devuelve 500 con `content-length: 0`

Ya viste este patrón en `sign-in` cuando las credenciales no cuadran: el servidor responde **500 sin body**. Si el cliente solo parsea JSON de error, falla y a veces se muestra como “red”.

### D) Android: tráfico HTTP claro (`http://`) bloqueado

Si apuntas a `http://10.0.2.2:5070` sin configurar **cleartext** en Android, puede fallar de forma opaca según cómo manejes la excepción.

### E) Timeout demasiado bajo o cold start en Azure (plan F1)

El primer request tras inactividad puede tardar; si el timeout es corto, verás error repetido hasta que “despierte” el sitio.

### F) Endpoint o verbo incorrecto

Rutas bajo `/api/v1/...`: los **segmentos que salen del nombre del controller** usan **_snake_case_** (`house_hold`, `household_member`, `income_allocation`, etc.); excepciones literales **`user-income`** e **`invitations`**. Un path mal copiado da **404**; si el mapper dice “Error de red”, confunde el diagnóstico.

---

## 3. Checklist rápido (5 minutos)

1. Imprimir/loguear (solo en debug): **URL completa** + **método** + **status code** + **primeros 200 chars del body** (sin token).
2. Confirmar que **después del login** el token se guarda y el interceptor añade:
   `Authorization: Bearer <access_token>`.
3. Probar el mismo endpoint con **Postman/curl** contra la misma base URL.
4. Si usas Azure HTTPS, no mezcles certificados autofirmados en local sin trust.
5. Revisar si “Error de red” está en un `catch (e)` que atrapa **todo**; sustituir por ramas por tipo de error y por código HTTP.

---

## 4. Contratos que debe respetar el cliente (este repo backend)

- **Sign-up:** `POST /api/v1/authentication/sign-up`  
  - `role` debe ser exactamente: `Admin`, `Representative`, `Member` (respetar mayúsculas en el flujo que persiste usuario).
  - Si `role` es `Member`, `householdId` debe existir en BD o vendrá `"Household not found."`.
- **Sign-in:** `POST /api/v1/authentication/sign-in`  
  - Puede responder **500** sin cuerpo en credenciales inválidas; el cliente debe tratarlo como fallo de login controlado, no como “sin internet”.
- **JWT:** enviar Bearer en rutas protegidas.

---

# Prompt maestro — “Con esto corriges todo” (copiar desde aquí)

```text
Eres un Senior Flutter Engineer. Debes corregir de raíz el problema de la pantalla "Panel representante → Dashboard" que muestra "Error de red" repetidamente, y dejar la capa de red + auth alineada a un backend ASP.NET Core en Azure.

## Contexto del backend (no inventar)
- Base URL producción (ejemplo real del despliegue):
  https://budgetly-api-dev-dxcfedfvdxeebad5.chilecentral-01.azurewebsites.net
- Base URL desarrollo emulador Android típico:
  http://10.0.2.2:5070
- Rutas bajo /api/v1/... — segmentos derivados del controller en snake_case (underscores); ver catálogo en este mismo .md después de "## 5".
- Auth:
  POST /api/v1/authentication/sign-in
  POST /api/v1/authentication/sign-up
- La mayoría de endpoints requieren header:
  Authorization: Bearer <JWT>
- Errores conocidos del backend:
  - sign-in con credenciales inválidas puede devolver HTTP 500 con body vacío.
  - sign-up con role inválido o household inexistente devuelve JSON { "message": "..." }.

## Objetivo
1) Eliminar el falso positivo "Error de red" cuando el fallo es HTTP/negocio/sesión.
2) Asegurar que TODAS las llamadas del dashboard representante usan base URL correcta por entorno y Bearer token cuando aplique.
3) Instrumentar logs solo en debug con: URL, método, statusCode, body snippet (sin token).
4) Mapear errores:
   - SocketException / Timeout / Handshake → "Sin conexión o servidor no disponible"
   - 401/403 → "Sesión expirada o no autorizado" + logout limpio
   - 404 → "Recurso no encontrado (revisa endpoint)"
   - 500 con body vacío en login → "Credenciales inválidas o error del servidor"
   - 500 con JSON message → mostrar message
5) Revisar Android: si usas http:// en debug, configurar cleartext solo para debug si hace falta.
6) Revisar timeouts razonables (p.ej. 30s) y reintento manual con backoff simple (no spam).

## Tareas concretas en el código Flutter
- Localizar dónde se lanza el string "Error de red." y reemplazar por clasificación de errores.
- Verificar ApiConfig / environment: una sola fuente de verdad (dart-define o flavor).
- Verificar que el token se persiste tras login y se inyecta en HttpClient/Dio antes del dashboard.
- Añadir prueba manual documentada: login → navegar dashboard → ver request en logs con 200 o error real.

## Entregables
- Lista de archivos cambiados
- Diff conceptual por archivo
- Pasos de verificación en emulador y en release build
- Si falta endpoint real para dashboard representante, NO simules datos: muestra error claro "Endpoint no configurado" y deja TODO con ruta esperada según Swagger.

Empieza por instrumentación + corrección del mapper de errores, luego auth header, luego URL por entorno. No cambies UI bonita hasta que el dashboard reciba statusCode real y estable.
```

---

## 5. Cómo usar este archivo

1. Copia solo el bloque del **Prompt maestro** (entre las comillas triples) **y**, si necesitas todas las rutas y atributos de body/query, también todo lo que sigue al marcador **`<!-- PROMPT_CATÁLOGO_API_INJECT -->


## Catálogo API v1 — prompt extendido para Flutter

Este catálogo recorre **52** operaciones HTTP del backend **com.split.backend**.

### Rutas (`LowercaseUrls` + snake_case del nombre del controller)

Los segmentos vienen de `KebabCaseRouteNamingConvention` que aplica **`ToSnakeCase()`** al nombre del controller (`HouseHoldController` ⇒ `house_hold`). No confundir con guiones tipo kebab salvo rutas literales (**user-income**, **invitations**).

### JSON

Petición y respuesta usan habitualmente **camelCase** (`personName`, `houseHoldId`, etc.). Excepciones puntuales: `JsonPropertyName("createdAt")` etc. aplican igual en camelCase.

### Middleware

`RequestAuthorizationMiddleware` exige header `Authorization: Bearer <jwt>` salvo rutas marcadas con el **AllowAnonymous del namespace IAM** (no el de Microsoft). Los filtros `[Authorize]` IAM cargan usuario desde `HttpContext.Items["User"]`.


──────────────────────────────────────────────────────────────────────────────
### 1. Sign-in
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `POST` `/api/v1/authentication/sign-in`

**Middleware / auth:** Anónimo (`[AllowAnonymous]` IAM).

**Cabeceras:** `Content-Type: application/json`

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"email":"","password":""}
```

**Respuestas de éxito:** 200 + JWT (`AuthenticatedUserResource`).

**Errores / HTTP a clasificar:** 500 body vacío posible credenciales inválidas.

**Forma orientativa respuesta:**
```
{"id":0,"email":"","token":"","isNewUser":false,"householdId":"","role":"","plan":""}
```

**Flutter:** No etiquetar 500 vacío como fallo de internet.


──────────────────────────────────────────────────────────────────────────────
### 2. Sign-up
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `POST` `/api/v1/authentication/sign-up`

**Middleware / auth:** Anónimo.

**Cabeceras:** `Content-Type: application/json`

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"email":"","password":"","name":"","role":"Member","plan":1,"householdId":null}
```

**Respuestas de éxito:** 200 `{"message":"Signed up successfully"}`

**Errores / HTTP a clasificar:** 400 `{message}`; role exacto Admin|Representative|Member.

**Forma orientativa respuesta:**
```
{"message":""}
```

**Flutter:** plan 1=Free 2=Premium.


──────────────────────────────────────────────────────────────────────────────
### 3. Get user by id
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/user/user/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + Accept

**Parámetros (query / ruta):** `id` int (ruta duplicada user/user).

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 UserResource

**Errores / HTTP a clasificar:** 401; 404.

**Forma orientativa respuesta:**
```
{"id":0,"email":"","personName":"","houseHoldId":"","role":"","plan":"","photo":"","profileLockedUntil":"","isNewUser":""}
```

**Flutter:** Path literal del controller User.


──────────────────────────────────────────────────────────────────────────────
### 4. Get all users
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/user`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 lista

**Errores / HTTP a clasificar:** 401.

**Forma orientativa respuesta:**
```
[UserResource]
```

**Flutter:** Solo uso admin/debug.


──────────────────────────────────────────────────────────────────────────────
### 5. Get user by household id
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/user/householdid/{houseHoldId}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** houseHoldId string.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 UserResource

**Errores / HTTP a clasificar:** 401; excepción si null.

**Forma orientativa respuesta:**
```
UserResource
```

**Flutter:** Template C# `houseHoldId`.


──────────────────────────────────────────────────────────────────────────────
### 6. Update user by email
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `PUT` `/api/v1/user/byemail/{emailAddress}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** email URL-encoded.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"emailAddress":"","personName":"","password":""}
```

**Respuestas de éxito:** 200 UserResource

**Errores / HTTP a clasificar:** 400 ModelState; 404.

**Forma orientativa respuesta:**
```
UserResource
```

**Flutter:** PersonName en body.


──────────────────────────────────────────────────────────────────────────────
### 7. Delete user by email
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `DELETE` `/api/v1/user/byemail/{email}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** email ruta.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 204 NoContent

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
—
```

**Flutter:** Invalidar token local.


──────────────────────────────────────────────────────────────────────────────
### 8. Create user income
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `POST` `/api/v1/user-income`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"id":"","userId":0,"income":0}
```

**Respuestas de éxito:** 201 UserIncomeResource

**Errores / HTTP a clasificar:** 400.

**Forma orientativa respuesta:**
```
{"id":"","userId":0,"income":0,"createdDate":"","updatedDate":""}
```

**Flutter:** Body inferido sin [FromBody] explícito.


──────────────────────────────────────────────────────────────────────────────
### 9. Get user income by id
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/user-income/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** id string.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
UserIncomeResource
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 10. Get user income by user id
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/user-income/byuserid/{userId}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** userId long.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 o 204 NoContent

**Errores / HTTP a clasificar:** 401.

**Forma orientativa respuesta:**
```
UserIncomeResource
```

**Flutter:** 204 = sin fila, no error red.


──────────────────────────────────────────────────────────────────────────────
### 11. Update user income
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `PUT` `/api/v1/user-income/byid/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** id ruta.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"id":"","income":0}
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 400; 404.

**Forma orientativa respuesta:**
```
UserIncomeResource
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 12. Get all bills
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/bills`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 lista

**Errores / HTTP a clasificar:** 401; 500 si null en servidor.

**Forma orientativa respuesta:**
```
BillResource
```

**Flutter:** createdAt/updatedAt con JsonPropertyName.


──────────────────────────────────────────────────────────────────────────────
### 13. Get bills by household
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/bills/byhousehold/{householdId}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** householdId.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 lista

**Errores / HTTP a clasificar:** 401; 500 posible.

**Forma orientativa respuesta:**
```
[BillResource]
```

**Flutter:** Dashboard hogar.


──────────────────────────────────────────────────────────────────────────────
### 14. Create bill
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `POST` `/api/v1/bills`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"houseHoldId":"","description":"","amount":0,"createdBy":0,"paymentDate":""}
```

**Respuestas de éxito:** 201 BillResource

**Errores / HTTP a clasificar:** 400 message.

**Forma orientativa respuesta:**
```
BillResource
```

**Flutter:** houseHoldId not householdId.


──────────────────────────────────────────────────────────────────────────────
### 15. Update bill
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `PUT` `/api/v1/bills/byid/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"description":null,"amount":null,"paymentDate":null}
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 400; 404.

**Forma orientativa respuesta:**
```
BillResource
```

**Flutter:** Campos nullables.


──────────────────────────────────────────────────────────────────────────────
### 16. Delete bill
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `DELETE` `/api/v1/bills/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 `{"message":"..."}`

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
{"message":""}
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 17. Get household by id
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/house_hold/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 HouseHoldResource

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
{"id":"","name":"","description":"","memberCount":0,"representativeId":0,"currency":"","startDate":"","createdAt":"","updatedAt":""}
```

**Flutter:** Segmento `house_hold`.


──────────────────────────────────────────────────────────────────────────────
### 18. Create household
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `POST` `/api/v1/house_hold`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"id":null,"name":"","representativeId":0,"currency":"USD","description":null,"memberCount":null,"startDate":null,"createdAt":null,"updatedAt":null}
```

**Respuestas de éxito:** 201

**Errores / HTTP a clasificar:** 400 rep inválido.

**Forma orientativa respuesta:**
```
HouseHoldResource
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 19. Update household
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `PUT` `/api/v1/house_hold/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"name":"","description":"","memberCount":1,"currency":"USD","startDate":null}
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 400; 404.

**Forma orientativa respuesta:**
```
HouseHoldResource
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 20. Households by representative
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/house_hold/representative/{representativeId}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** representativeId long.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 lista (vacía ok)

**Errores / HTTP a clasificar:** 401.

**Forma orientativa respuesta:**
```
[HouseHoldResource]
```

**Flutter:** Panel representante.


──────────────────────────────────────────────────────────────────────────────
### 21. Create household member
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `POST` `/api/v1/household_member`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"householdId":"","userId":0,"isRepresentative":false,"income":0}
```

**Respuestas de éxito:** 201

**Errores / HTTP a clasificar:** 400 message.

**Forma orientativa respuesta:**
```
HouseholdMemberResource
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 22. Get household member by id
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/household_member/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
HouseholdMemberResource
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 23. Members by household
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/household_member/household/{householdId}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** householdId.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 401.

**Forma orientativa respuesta:**
```
[HouseholdMemberResource]
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 24. Detailed members
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/household_member/household/{householdId}/detailed`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** householdId.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 MemberDetailed + pending invites

**Errores / HTTP a clasificar:** 401.

**Forma orientativa respuesta:**
```
MemberDetailedResource
```

**Flutter:** Status Active/Inactive/Pending.


──────────────────────────────────────────────────────────────────────────────
### 25. Members by user
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/household_member/user/{userId}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** userId int.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 401.

**Forma orientativa respuesta:**
```
[HouseholdMemberResource]
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 26. All household members
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/household_member`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 401.

**Forma orientativa respuesta:**
```
[HouseholdMemberResource]
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 27. Update household member
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `PUT` `/api/v1/household_member/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"householdId":null,"userId":null,"isRepresentative":null,"income":null,"allocations":[{"householdId":null,"percentage":0,"userId":null}]}
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 400; 404.

**Forma orientativa respuesta:**
```
HouseholdMemberResource
```

**Flutter:** allocations opcional.


──────────────────────────────────────────────────────────────────────────────
### 28. Delete household member
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `DELETE` `/api/v1/household_member/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 message

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
{"message":""}
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 29. Promote representative
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `POST` `/api/v1/household_member/{id}/promote-representative`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 400; 404.

**Forma orientativa respuesta:**
```
HouseholdMemberResource
```

**Flutter:** POST sin body.


──────────────────────────────────────────────────────────────────────────────
### 30. Demote representative
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `POST` `/api/v1/household_member/{id}/demote-representative`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 400; 404.

**Forma orientativa respuesta:**
```
HouseholdMemberResource
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 31. Income allocations by household
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/income_allocation/byhousehold/{householdId}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** householdId.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 o 204

**Errores / HTTP a clasificar:** 401.

**Forma orientativa respuesta:**
```
IncomeAllocationResource
```

**Flutter:** 204 válido.


──────────────────────────────────────────────────────────────────────────────
### 32. Income allocations by user
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/income_allocation/byuserid/{userId}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** userId long.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 o 204

**Errores / HTTP a clasificar:** 401.

**Forma orientativa respuesta:**
```
[IncomeAllocationResource]
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 33. Create income allocation
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `POST` `/api/v1/income_allocation`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"userId":0,"householdId":"","percentage":0}
```

**Respuestas de éxito:** 201

**Errores / HTTP a clasificar:** 400.

**Forma orientativa respuesta:**
```
IncomeAllocationResource
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 34. Update income allocation
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `PUT` `/api/v1/income_allocation/byid/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"id":"","userId":null,"householdId":null,"percentage":null}
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 400; 404.

**Forma orientativa respuesta:**
```
IncomeAllocationResource
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 35. Delete income allocation
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `DELETE` `/api/v1/income_allocation/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 message

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
{"message":""}
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 36. Get all contributions
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/contribution`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 401; 500 null.

**Forma orientativa respuesta:**
```
[ContributionResource]
```

**Flutter:** strategy es int.


──────────────────────────────────────────────────────────────────────────────
### 37. Get contribution by id
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/contribution/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
ContributionResource
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 38. Contributions by bill
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/contribution/bybillid/{billId}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** billId.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 404 null.

**Forma orientativa respuesta:**
```
[ContributionResource]
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 39. Contributions by household
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/contribution/byhouseholdid/{householdId}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** householdId.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
[ContributionResource]
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 40. Create contribution
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `POST` `/api/v1/contribution`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"billId":"","householdId":"","description":"","deadlineForMembers":null,"strategy":null}
```

**Respuestas de éxito:** 201

**Errores / HTTP a clasificar:** 400.

**Forma orientativa respuesta:**
```
ContributionResource
```

**Flutter:** description default vacío servidor.


──────────────────────────────────────────────────────────────────────────────
### 41. Update contribution
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `PUT` `/api/v1/contribution/byid/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"description":null,"deadlineForMembers":null,"strategy":null}
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 400; 404.

**Forma orientativa respuesta:**
```
ContributionResource
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 42. Delete contribution
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `DELETE` `/api/v1/contribution/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 texto "bill" histórico

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
{"message":""}
```

**Flutter:** Bug copy mensaje.


──────────────────────────────────────────────────────────────────────────────
### 43. Get all member contributions
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/member_contribution`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 401; 500 null.

**Forma orientativa respuesta:**
```
[MemberContributionResource]
```

**Flutter:** campo payedAt.


──────────────────────────────────────────────────────────────────────────────
### 44. Member contributions by contribution
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/member_contribution/bycontributionid/{contributionId}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** contributionId.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
[MemberContributionResource]
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 45. Member contributions by member
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/member_contribution/bymemberid/{memberId}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** memberId.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
[MemberContributionResource]
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 46. Create member contribution
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `POST` `/api/v1/member_contribution`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"contributionId":"","memberId":"","amount":0}
```

**Respuestas de éxito:** 201

**Errores / HTTP a clasificar:** 400.

**Forma orientativa respuesta:**
```
MemberContributionResource
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 47. Delete member contribution
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `DELETE` `/api/v1/member_contribution/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** id.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 message

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
{"message":""}
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 48. Create invitation
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `POST` `/api/v1/invitations`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"email":"","householdId":"","description":""}
```

**Respuestas de éxito:** 201 InvitationResource

**Errores / HTTP a clasificar:** 400.

**Forma orientativa respuesta:**
```
{"id":0,"email":"","householdId":"","description":"","status":"","token":"","expiresAt":""}
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 49. Get pending invitation
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/invitations/pending`

**Middleware / auth:** ⚠ Bearer puede ser obligatorio (AllowAnonymous mismatch).

**Cabeceras:** Accept + Bearer prudente.

**Parámetros (query / ruta):** Query email y householdId.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200 InvitationResource

**Errores / HTTP a clasificar:** 404.

**Forma orientativa respuesta:**
```
InvitationResource
```

**Flutter:** Validar contra Azure.


──────────────────────────────────────────────────────────────────────────────
### 50. Get settings
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `GET` `/api/v1/settings`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer

**Parámetros (query / ruta):** Query userId>0.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
(vacío)
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 400 string; 404.

**Forma orientativa respuesta:**
```
SettingResource
```

**Flutter:** —


──────────────────────────────────────────────────────────────────────────────
### 51. Create settings
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `POST` `/api/v1/settings`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** —

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"userId":0,"language":"es","darkMode":false,"notificationEnabled":true}
```

**Respuestas de éxito:** 201 o 200 existente

**Errores / HTTP a clasificar:** 400 texto usuario.

**Forma orientativa respuesta:**
```
SettingResource
```

**Flutter:** POST idempotente-soft.


──────────────────────────────────────────────────────────────────────────────
### 52. Update settings
──────────────────────────────────────────────────────────────────────────────

**HTTP:** `PUT` `/api/v1/settings/{id}`

**Middleware / auth:** Bearer.

**Cabeceras:** Bearer + JSON

**Parámetros (query / ruta):** id long.

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
```
{"userId":0,"language":"","darkMode":false,"notificationEnabled":false}
```

**Respuestas de éxito:** 200

**Errores / HTTP a clasificar:** 404;400 texto.

**Forma orientativa respuesta:**
```
SettingResource
```

**Flutter:** —


### Matrices de errores Flutter (no llamar todo «red»)

| HTTP / situación | Acción cliente |
|------------------|----------------|
| Timeout / Socket | Mensaje sin conectividad |
| 401 | Sesión inválida, limpiar token |
| 403 | Opcional igual logout |
| 404 | Endpoint o recurso incorrecto |
| 204 | Éxito sin cuerpo |
| 500 vacío login | Tratar como fallo login/servidor |
| HTML en body | Cold start/error Azure, no JSON |

### Tabla rápida de todos los endpoints

| # | Método | Ruta |
|---|--------|------|
| 1 | POST | `/api/v1/authentication/sign-in` |
| 2 | POST | `/api/v1/authentication/sign-up` |
| 3 | GET | `/api/v1/user/user/{id}` |
| 4 | GET | `/api/v1/user` |
| 5 | GET | `/api/v1/user/householdid/{houseHoldId}` |
| 6 | PUT | `/api/v1/user/byemail/{emailAddress}` |
| 7 | DELETE | `/api/v1/user/byemail/{email}` |
| 8 | POST | `/api/v1/user-income` |
| 9 | GET | `/api/v1/user-income/{id}` |
| 10 | GET | `/api/v1/user-income/byuserid/{userId}` |
| 11 | PUT | `/api/v1/user-income/byid/{id}` |
| 12 | GET | `/api/v1/bills` |
| 13 | GET | `/api/v1/bills/byhousehold/{householdId}` |
| 14 | POST | `/api/v1/bills` |
| 15 | PUT | `/api/v1/bills/byid/{id}` |
| 16 | DELETE | `/api/v1/bills/{id}` |
| 17 | GET | `/api/v1/house_hold/{id}` |
| 18 | POST | `/api/v1/house_hold` |
| 19 | PUT | `/api/v1/house_hold/{id}` |
| 20 | GET | `/api/v1/house_hold/representative/{representativeId}` |
| 21 | POST | `/api/v1/household_member` |
| 22 | GET | `/api/v1/household_member/{id}` |
| 23 | GET | `/api/v1/household_member/household/{householdId}` |
| 24 | GET | `/api/v1/household_member/household/{householdId}/detailed` |
| 25 | GET | `/api/v1/household_member/user/{userId}` |
| 26 | GET | `/api/v1/household_member` |
| 27 | PUT | `/api/v1/household_member/{id}` |
| 28 | DELETE | `/api/v1/household_member/{id}` |
| 29 | POST | `/api/v1/household_member/{id}/promote-representative` |
| 30 | POST | `/api/v1/household_member/{id}/demote-representative` |
| 31 | GET | `/api/v1/income_allocation/byhousehold/{householdId}` |
| 32 | GET | `/api/v1/income_allocation/byuserid/{userId}` |
| 33 | POST | `/api/v1/income_allocation` |
| 34 | PUT | `/api/v1/income_allocation/byid/{id}` |
| 35 | DELETE | `/api/v1/income_allocation/{id}` |
| 36 | GET | `/api/v1/contribution` |
| 37 | GET | `/api/v1/contribution/{id}` |
| 38 | GET | `/api/v1/contribution/bybillid/{billId}` |
| 39 | GET | `/api/v1/contribution/byhouseholdid/{householdId}` |
| 40 | POST | `/api/v1/contribution` |
| 41 | PUT | `/api/v1/contribution/byid/{id}` |
| 42 | DELETE | `/api/v1/contribution/{id}` |
| 43 | GET | `/api/v1/member_contribution` |
| 44 | GET | `/api/v1/member_contribution/bycontributionid/{contributionId}` |
| 45 | GET | `/api/v1/member_contribution/bymemberid/{memberId}` |
| 46 | POST | `/api/v1/member_contribution` |
| 47 | DELETE | `/api/v1/member_contribution/{id}` |
| 48 | POST | `/api/v1/invitations` |
| 49 | GET | `/api/v1/invitations/pending` |
| 50 | GET | `/api/v1/settings` |
| 51 | POST | `/api/v1/settings` |
| 52 | PUT | `/api/v1/settings/{id}` |

## Apéndice — plantillas Dio/retry


### Checklist automatizable #1

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #2

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #3

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #4

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #5

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #6

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #7

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #8

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #9

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #10

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #11

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #12

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #13

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #14

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #15

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #16

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #17

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #18

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #19

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #20

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #21

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #22

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #23

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #24

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #25

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #26

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #27

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #28

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #29

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #30

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #31

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #32

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #33

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #34

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #35

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #36

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #37

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #38

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #39

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #40

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #41

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #42

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #43

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #44

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #45

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #46

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #47

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #48

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #49

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #50

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #51

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #52

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #53

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #54

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #55

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #56

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #57

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #58

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #59

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #60

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #61

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #62

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #63

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #64

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #65

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #66

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #67

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #68

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #69

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #70

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #71

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #72

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #73

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #74

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #75

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #76

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #77

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #78

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #79

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #80

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #81

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #82

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #83

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #84

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #85

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #86

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #87

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #88

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #89

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #90

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #91

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #92

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #93

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #94

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #95

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #96

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #97

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #98

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #99

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #100

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #101

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #102

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #103

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #104

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #105

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #106

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #107

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #108

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #109

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #110

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #111

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #112

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #113

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #114

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #115

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #116

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #117

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #118

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #119

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).

### Checklist automatizable #120

1. Registrar `response.requestOptions.uri`, `method`, `statusCode`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto `Bearer <token>` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar `houseHoldId` de bills en payloads de contributions sin revisar campo (contribuciones usan `householdId`).


*Documento generado para alinear la app móvil con el comportamiento real del API Budgetly / com.split.backend.*
