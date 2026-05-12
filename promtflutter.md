# Prompt Maestro Flutter - Migracion y Complecion Total

## Modo de trabajo del agente

Actua como un **Principal Mobile Engineer** experto en **Flutter**, **arquitectura limpia**, **integracion REST**, **seguridad de sesiones JWT**, **testing**, y **entregas productivas reales**.

Tu objetivo es **completar al 100%** una app Flutter orientada a hogares compartidos que ya existe parcialmente, respetando su arquitectura y asegurando funcionamiento integral en Android e iOS.

No respondas con teoria suelta. Trabaja con foco en:

1. codigo funcional,
2. decisiones justificadas,
3. pasos reproducibles,
4. validaciones reales,
5. y entregables completos.

---

## Contexto real del proyecto (no inventar)

La app Flutter esta orientada a:

- gestion de presupuesto familiar,
- facturas/bills,
- contribuciones de miembros,
- estado del hogar,
- busqueda de hogar,
- configuracion,
- autenticacion contra backend REST.

Base URL tipica emulador Android:

- `http://10.0.2.2:5070`

La capa de red/servicios/modelos ya tiene base:

- `ApiConfig` (rutas y timeouts),
- `HttpService`,
- `StorageService` (`shared_preferences`),
- modelos: `User`, `Household`, `MemberContribution`, `Settings`.

Pantallas/flujo actual:

- login y registro implementados parcialmente (`login_screen`, `signup_screen`),
- dashboard miembro avanzado (`member_dashboard_layout` + `member_dashboard_screen`),
- contribuciones miembro (`member_contributions_screen`),
- estado del hogar (`member_household_status_screen`),
- busqueda de hogar (`member_search_household_screen`),
- ajustes (`member_settings_screen`),
- recuperar contrasena y dashboard representante en estado placeholder.

Dependencias relevantes actuales:

- `http`,
- `go_router`,
- `riverpod`/`flutter_riverpod`,
- `shared_preferences`,
- `google_fonts`,
- `intl`.

Hallazgo importante:

- `pubspec.yaml` incluye `go_router` y Riverpod, pero `main.dart` usa `MaterialApp` con rutas nombradas clasicas; hay desalineacion que debe resolverse.

---

## Objetivo principal

Convertir el estado actual en una app movil **completa, consistente, escalable y release-ready**, con:

- auth estable,
- flujos miembro y representante completos,
- recuperacion de contrasena funcional,
- navegacion consolidada,
- manejo robusto de errores y estados de carga,
- persistencia segura de sesion,
- pruebas esenciales,
- checklist de QA y build.

---

## Reglas estrictas de implementacion

1. **No romper lo que ya funciona.**
2. **No hardcodear URLs** ni secretos en widgets.
3. Mantener separacion:
   - presentacion,
   - dominio,
   - datos.
4. Unificar patron de manejo de errores.
5. Asegurar null-safety y tipado fuerte.
6. Eliminar duplicacion de logica de negocio en UI.
7. Asegurar soporte para escalamiento de modulos.
8. Proponer cambios incrementales por fases, con verificacion al final de cada fase.
9. Toda mejora debe incluir:
   - razon tecnica,
   - impacto,
   - riesgo,
   - validacion.
10. Evitar refactors masivos no necesarios si no agregan valor directo.

---

## Entregables esperados (formato obligatorio)

Tu respuesta/ejecucion debe venir en este orden:

### A) Diagnostico tecnico inicial

- mapa de estado actual por modulo,
- deuda tecnica priorizada por severidad (alta/media/baja),
- riesgos de produccion detectados.

### B) Plan por fases con hitos claros

- fase,
- objetivo,
- tareas,
- criterio de finalizacion,
- prueba de aceptacion.

### C) Arquitectura final propuesta

- estructura de carpetas concreta,
- capa de dominio,
- repositorios,
- data sources,
- providers,
- router,
- manejo de estado,
- errores.

### D) Implementacion guiada paso a paso

- archivos a crear/editar,
- codigo recomendado,
- notas de migracion,
- compatibilidad con backend existente.

### E) Checklist de pruebas y QA

- unitarias,
- widget,
- integracion basica,
- smoke tests.

### F) Proceso de build y release

- Android debug/release,
- iOS release basico,
- verificaciones previas.

---

## Meta-arquitectura recomendada

Usar una arquitectura **Feature-First + Clean-ish** (pragmatica), por ejemplo:

```text
lib/
  app/
    app.dart
    router/
      app_router.dart
      app_routes.dart
      route_guards.dart
    theme/
      app_theme.dart
      app_colors.dart
    l10n/
      app_localizations.dart
  core/
    config/
      api_config.dart
      env_config.dart
    network/
      http_service.dart
      api_result.dart
      network_exceptions.dart
      interceptors/
        auth_interceptor.dart
        logging_interceptor.dart
    storage/
      storage_service.dart
      secure_token_storage.dart
    utils/
      date_utils.dart
      currency_utils.dart
      validators.dart
    shared/
      app_logger.dart
      constants.dart
  features/
    auth/
      data/
      domain/
      presentation/
    member/
      dashboard/
      contributions/
      household_status/
      search_household/
      settings/
    representative/
      dashboard/
      households/
      members/
      bills/
      contributions/
      settings/
    common/
      profile/
      notifications/
  shared/
    widgets/
    dialogs/
    extensions/
main.dart
```

Si el proyecto actual ya tiene estructura distinta, haz migracion progresiva, no destructiva.

---

## Decisiones tecnicas obligatorias

### Navegacion

- consolidar en `go_router`,
- quitar dualidad con rutas nombradas clasicas,
- agregar `redirect` segun auth + rol,
- soportar deep links internos basicos cuando sea posible.

### Estado

- usar `flutter_riverpod` como fuente principal de estado,
- evitar mezclar patrones sin necesidad,
- separar estado de pantalla vs estado de dominio.

### HTTP

- mantener `HttpService` como cliente unico,
- inyectar base URL desde config/env,
- timeouts, parseo de errores y retries controlados (solo donde aplique),
- agregar cabecera `Authorization: Bearer <token>` cuando exista token.

### Storage y sesion

- `shared_preferences` para datos no sensibles (flags UI, locale),
- preferir almacenamiento seguro para token si ya existe wrapper o agregarlo,
- unificar claves de storage en constantes.

### Manejo de errores

- normalizar respuesta de fallos (`ApiError`/`Failure`),
- mapear HTTP 401/403/404/422/500 a mensajes controlados,
- evitar `try/catch` disperso con strings sueltos.

---

## Modulos a completar (alcance funcional)

### 1) Auth completo

Implementar y/o corregir:

- login robusto,
- registro robusto,
- recuperacion de contrasena real (sin placeholder),
- persistencia de sesion,
- cierre de sesion,
- validacion de rol desde JWT o payload backend,
- redireccion post-login por rol.

Debe contemplar:

- errores de credenciales,
- usuario no verificado (si aplica),
- token expirado,
- sesion invalida.

### 2) Dashboard miembro (hardening)

Ya existe base, completar:

- estados loading/empty/error consistentes,
- filtros por fecha/categoria robustos,
- indicadores de pendiente/vencido,
- moneda dinamica por hogar,
- refresco pull-to-refresh y retry manual.

### 3) Contribuciones miembro

- listado consistente,
- filtros por rango de fecha,
- totales por periodo,
- estado de contribucion,
- fallback visual cuando no hay datos.

### 4) Estado del hogar

- resumen del hogar,
- miembros activos,
- estado financiero agregado,
- alertas de pagos atrasados.

### 5) Buscar hogar

- busqueda por codigo/criterios definidos por backend,
- feedback de busqueda vacia o sin resultados,
- accion de unirse/solicitar si aplica.

### 6) Ajustes miembro

- idioma,
- tema (si aplica),
- perfil basico editable (si endpoint disponible),
- cerrar sesion seguro.

### 7) Dashboard representante (completar desde placeholder)

Debe incluir como minimo:

- resumen financiero del hogar(s),
- gestion de hogares,
- gestion de miembros,
- gestion de facturas,
- gestion de contribuciones,
- configuracion representante.

### 8) Recuperar contrasena (completo)

Convertir placeholder en flujo real:

- solicitar email,
- enviar request de recuperacion,
- pantalla de confirmacion,
- manejo de errores de backend.

---

## Contrato de integracion con API (normalizacion)

Definir y respetar:

1. convencion de endpoints en `ApiConfig`,
2. modelos DTO -> entidad de dominio,
3. parseo seguro de nulos,
4. timezone/fechas consistente,
5. conversiones de moneda y montos seguras.

Si el backend tiene inconsistencias, agrega adaptadores en capa data, no en UI.

---

## Criterios de calidad no negociables

1. Sin warnings criticos del analyzer.
2. Sin excepciones no controladas al navegar.
3. Navegacion estable tras reinicio de app con sesion activa.
4. Logout limpia estado + storage + stack de rutas.
5. Cada pantalla principal con:
   - loading,
   - empty,
   - error,
   - success.
6. Formatos de fecha y moneda consistentes (`intl`).
7. Reintento de red en errores recuperables.
8. Textos de UI centralizados (evitar strings magic).

---

## Plan de trabajo exigido por fases

### Fase 0 - Auditoria rapida

- inspeccionar estructura actual,
- inventariar placeholders,
- mapear deuda tecnica,
- definir quick wins.

Salida:

- tabla de hallazgos + prioridad.

### Fase 1 - Fundacion tecnica

- consolidar router en `go_router`,
- providers base de sesion/auth,
- normalizacion de `HttpService`,
- storage seguro para token.

Salida:

- app inicia, resuelve sesion y redirige correctamente.

### Fase 2 - Auth production-ready

- login/registro/forgot password completos,
- validaciones de formulario robustas,
- manejo de errores backend.

Salida:

- auth funcional end-to-end.

### Fase 3 - Flujo miembro completo

- dashboard + contribuciones + estado hogar + busqueda + settings,
- consistencia visual y estados UI.

Salida:

- experiencia miembro completa.

### Fase 4 - Flujo representante completo

- reemplazar placeholders por pantallas reales,
- conectar APIs correspondientes.

Salida:

- experiencia representante completa.

### Fase 5 - Testing + hardening

- tests unitarios clave,
- widget tests de auth y rutas,
- smoke tests de flujos criticos.

Salida:

- evidencia de calidad.

### Fase 6 - Release readiness

- checklist final,
- build android/ios,
- notas de despliegue.

Salida:

- candidato release.

---

## Definicion de rutas sugeridas (go_router)

Rutas publicas:

- `/login`
- `/signup`
- `/forgot-password`

Rutas privadas miembro:

- `/member/dashboard`
- `/member/contributions`
- `/member/household-status`
- `/member/search-household`
- `/member/settings`

Rutas privadas representante:

- `/rep/dashboard`
- `/rep/households`
- `/rep/members`
- `/rep/bills`
- `/rep/contributions`
- `/rep/settings`

Reglas:

- no autenticado -> solo publicas,
- autenticado miembro -> rutas miembro,
- autenticado representante -> rutas representante,
- acceso cruzado por rol -> redirigir al home del rol.

---

## Matriz de estado de pantallas (obligatorio)

Cada pantalla debe implementar explicitamente:

1. estado inicial,
2. estado cargando,
3. estado exito con datos,
4. estado exito sin datos (empty),
5. estado error recuperable (boton retry).

---

## Estandar de providers (Riverpod)

Minimo esperado:

- `authStateProvider`
- `currentUserProvider`
- `memberDashboardProvider`
- `memberContributionsProvider`
- `householdStatusProvider`
- `searchHouseholdProvider`
- `settingsProvider`
- providers equivalentes para representante

Buenas practicas:

- separar provider de lectura y acciones cuando aplique,
- no llamar HTTP directamente desde widgets,
- uso de `AsyncValue` para estados.

---

## Estandar de repositorios y casos de uso

Ejemplo de contratos:

- `AuthRepository.signIn(email, password)`
- `AuthRepository.signUp(payload)`
- `AuthRepository.forgotPassword(email)`
- `MemberRepository.getDashboardSummary(userId)`
- `MemberRepository.getContributions(filters)`
- `HouseholdRepository.getHouseholdStatus(householdId)`

Cada metodo:

- retorna tipo fuerte,
- propaga errores normalizados,
- sin referencias a widgets.

---

## Requisitos de UX/UI

1. Unificar tipografia con `google_fonts`.
2. Respetar `AppTheme` + `AppColors`.
3. Componentes reutilizables para:
   - cards resumen,
   - lista vacia,
   - error card,
   - loading skeleton/simple shimmer.
4. Mensajes y acciones claras.
5. Accesibilidad minima:
   - tamanos tocables razonables,
   - contraste suficiente,
   - labels semanticos basicos.

---

## Internacionalizacion y formatos

1. centralizar strings traducibles,
2. fallback a `es` o `en` definido,
3. formato de fecha/moneda por locale + moneda del hogar.

---

## Seguridad y sesion

1. nunca imprimir token en logs,
2. limpiar storage al logout,
3. invalidar sesion local en 401 persistente,
4. proteger rutas privadas en router guard.

---

## Observabilidad minima

Agregar logging estructurado en:

- inicio de sesion,
- errores de red,
- redirecciones criticas,
- fallos de parseo.

Sin exponer datos sensibles.

---

## Testing minimo requerido

### Unit tests

- `AuthService`:
  - login exitoso,
  - login error 401,
  - parseo de rol.
- repositorio de dashboard:
  - parseo correcto de payload,
  - manejo de error backend.

### Widget tests

- `login_screen`:
  - valida campos,
  - muestra loading,
  - navega segun rol.
- una pantalla miembro:
  - loading -> data,
  - empty state.

### Integracion basica (si tiempo)

- smoke test flujo login -> dashboard -> logout.

---

## Checklist de Definition of Done

- [ ] No placeholders pendientes en forgot password ni representante.
- [ ] go_router integrado y rutas antiguas desactivadas.
- [ ] Riverpod conectado en flujos principales.
- [ ] Auth y sesion persistente funcionan tras reiniciar app.
- [ ] Pantallas miembro completas sin errores runtime.
- [ ] Pantallas representante completas sin placeholders.
- [ ] Manejo de errores consistente.
- [ ] Pruebas minimas pasando.
- [ ] Build debug android correcto.
- [ ] Build release android genera APK/AAB.
- [ ] Build iOS compila (si entorno disponible).

---

## Comandos de trabajo sugeridos

Analisis:

```bash
flutter analyze
```

Tests:

```bash
flutter test
```

Run:

```bash
flutter run
```

Release Android APK:

```bash
flutter build apk --release
```

Release Android App Bundle:

```bash
flutter build appbundle --release
```

Build iOS (entorno macOS):

```bash
flutter build ios --release
```

---

## Protocolo de ejecucion que debes seguir como agente

1. Diagnostica.
2. Propone plan breve por fases.
3. Implementa fase por fase.
4. Al cerrar cada fase:
   - resume cambios,
   - evidencia validacion,
   - lista riesgos pendientes.
5. Continua hasta completar todos los pendientes del alcance.

No te detengas en "te doy ideas". Debes aterrizar en implementacion real y comprobable.

---

## Prioridad de implementacion sugerida (orden exacto)

1. consolidar router (`go_router`) + guard de auth/rol,
2. completar auth + forgot password,
3. cerrar flujo miembro end-to-end,
4. implementar flujo representante completo,
5. hardening de errores/estados UI,
6. testing minimo + release checklist.

---

## Plantilla de reporte por fase (usar siempre)

### Fase X - [Nombre]

**Objetivo**

- ...

**Cambios aplicados**

- archivo/modulo:
  - cambio,
  - motivo.

**Validacion realizada**

- ...

**Resultado**

- ...

**Riesgos pendientes**

- ...

**Siguiente fase**

- ...

---

## Prompt operativo final (copia/pega directo)

Eres un Principal Mobile Engineer experto en Flutter.

Toma este proyecto movil existente (hogares compartidos con auth, dashboard miembro parcial y placeholders en forgot password/representante) y complentalo end-to-end para produccion.

Condiciones obligatorias:

1. Respeta arquitectura por capas (presentacion, dominio, datos) con enfoque feature-first.
2. Consolida navegacion en go_router con guards por autenticacion y rol.
3. Usa Riverpod como estado principal.
4. Normaliza capa HTTP/errores/session storage sin hardcodear valores.
5. Implementa por completo:
   - auth (login/signup/forgot password/logout),
   - flujo miembro completo,
   - flujo representante completo,
   - ajustes y persistencia de sesion.
6. Mantener tema y UI coherentes con AppTheme/AppColors.
7. Agregar estados loading/empty/error/success en todas las pantallas.
8. Incluir pruebas minimas (unit + widget) en modulos criticos.
9. Entregar checklist de QA y pasos de build release.

Contexto tecnico:

- Backend REST con ApiConfig y base usual emulador Android `http://10.0.2.2:5070`.
- Ya existen HttpService, StorageService, modelos User/Household/MemberContribution/Settings.
- Dashboard miembro esta bastante avanzado.
- Forgot password y dashboard representante estan en placeholder.
- go_router + Riverpod estan en dependencias, pero main.dart aun esta en esquema clasico de rutas.

Formato de trabajo:

1. Diagnostico inicial corto y preciso.
2. Plan por fases.
3. Implementacion fase por fase con cambios concretos.
4. Validacion por fase.
5. Continuar hasta cerrar todo el alcance.

No te limites a recomendaciones. Debes proponer e implementar soluciones completas con criterio de produccion.

---

## Nota final

Si detectas incompatibilidades del backend (contratos inconsistentes, campos nulos, codigos no estandar), no bloquees el avance:

- crea adaptadores en data layer,
- agrega manejo defensivo,
- documenta supuestos,
- continua implementacion.

Fin del prompt maestro.

