# Configuracion Firebase AI para TECHNOVATE

## 1. SDK agregado en Flutter

El proyecto usa estos paquetes:

- `firebase_ai`
- `firebase_app_check`
- `firebase_core`
- `cloud_firestore`

La app inicializa Firebase y App Check en `lib/main.dart`. En modo debug usa `AndroidDebugProvider`; en release usa `AndroidPlayIntegrityProvider`.

## 2. Activar Firebase AI Logic

En Firebase Console:

1. Abre el proyecto `empresa-s`.
2. Entra a Servicios de IA > AI Logic.
3. Presiona Get started.
4. Selecciona Gemini Developer API.
5. Habilita las APIs que Firebase solicite.
6. En la lista de apps, verifica que la app Android `com.example.flutter_firebase` tenga el SDK agregado.

## 3. Registrar App Check

En Firebase Console > App Check:

1. Registra la app Android `com.example.flutter_firebase`.
2. Para desarrollo local, ejecuta la app en debug y copia el token que Firebase imprime en consola.
3. En App Check, abre el menu de la app Android y entra a Manage debug tokens.
4. Agrega ese token debug.
5. Cuando vayan a publicar, usa Play Integrity para release.
6. Activa enforcement para Firebase AI Logic cuando ya hayan probado que el token funciona.

## 4. API key

No pegues una Gemini API key manual en el codigo de Flutter.

Con Firebase AI Logic, el SDK usa la configuracion de Firebase (`google-services.json`) y App Check protege las solicitudes. Si algun dia necesitan una clave realmente secreta, debe vivir en backend, por ejemplo Cloud Functions, no dentro del APK.

## 5. Modelo usado

El asistente usa:

```text
gemini-3.1-flash-lite
```

Se evita usar modelos 2.0 porque Firebase avisa que dejan de estar disponibles el 1 de junio de 2026.

## 6. Funcion del asistente

El asistente:

- Recomienda productos segun presupuesto y uso.
- Sugiere productos disponibles del catalogo Firestore `digizone_productos`.
- Explica por que recomienda cada opcion.
- Advierte compatibilidad basica para componentes de PC.
- Si Firebase AI Logic aun no esta listo, responde con reglas locales para no romper la app.
