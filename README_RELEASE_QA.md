# Budgetly - QA y Release Checklist

## 1) Validaciones técnicas previas

- Ejecutar análisis estático:
  - `flutter analyze`
- Ejecutar pruebas:
  - `flutter test`
- Verificar que no existan excepciones al navegar:
  - login -> dashboard por rol -> logout.

## 2) Smoke tests funcionales

- **Auth**
  - Login válido miembro redirige a `/member/dashboard`.
  - Login válido representante redirige a `/rep/dashboard`.
  - Forgot password muestra confirmación o error controlado.
  - Logout limpia sesión y vuelve a `/login`.
- **Miembro**
  - Dashboard carga, filtra, refresca y muestra error/retry.
  - Contributions permite refrescar y muestra empty/error/success.
  - Household status carga periodos y permite retry en error.
- **Representante**
  - Dashboard y listados cargan datos.
  - Crear hogar/miembro/contribución muestra feedback y refresca estado.

## 3) Build Android

- Debug:
  - `flutter build apk --debug`
- Release APK:
  - `flutter build apk --release`
- Release AAB:
  - `flutter build appbundle --release`

## 4) Build iOS (solo macOS)

- `flutter build ios --release`

## 5) Criterios de salida (DoD)

- No placeholders en forgot password ni flujo representante.
- Navegación consolidada en `go_router`.
- Estado principal gestionado por Riverpod en auth y módulos críticos.
- Sesión persistente tras reinicio.
- Estados `loading/empty/error/success` en pantallas principales.
- Errores HTTP normalizados y sin logs sensibles.
