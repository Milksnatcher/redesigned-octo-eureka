# Compra Conjunta — despliegue con GitHub Pages + Supabase

Esta versión no depende de Claude ni de ningún plan de pago: se aloja gratis
en GitHub Pages y sincroniza los datos en tiempo real usando la capa gratuita
de Supabase (base de datos Postgres alojada).

## 1. Crear la base de datos (Supabase, gratis, sin tarjeta)

1. Ve a https://supabase.com y crea una cuenta gratuita.
2. Crea un nuevo proyecto (elige cualquier nombre y contraseña; guarda la
   contraseña, aunque no la necesitarás para esta app).
3. Cuando el proyecto esté listo, ve a **SQL Editor** (menú lateral) →
   **New query**, pega el contenido de `schema.sql` (incluido en esta carpeta)
   y pulsa **Run**. Esto crea las tablas `users`, `orders` y `payments`, y
   activa la sincronización en tiempo real.

   ⚠️ Si ya tenías una versión anterior de estas tablas (de una versión previa
   de esta app), el esquema ha cambiado de forma incompatible — se ha añadido
   la tabla `users` y varias columnas nuevas. Antes de ejecutar `schema.sql`,
   ejecuta primero esto en el mismo SQL Editor para partir de cero:
   ```sql
   drop table if exists payments;
   drop table if exists orders;
   drop table if exists users;
   ```
   Esto borra cualquier pedido o balance que tuvieras cargado — no hay forma
   de migrar los datos antiguos al nuevo formato automáticamente.
4. Ve a **Project Settings → API**. Copia:
   - **Project URL**
   - **anon public** key (la clave pública, NO la `service_role`)

## 1b. Crear el usuario compartido del grupo

La app ahora exige iniciar sesión antes de ver o tocar nada. En vez de que
cada persona tenga su propia cuenta, creas **un único usuario** y compartes
esas credenciales con el grupo (como una contraseña de wifi).

1. En Supabase, ve a **Authentication → Users**.
2. Haz clic en **Add user → Create new user**.
3. Pon un correo (puede ser cualquiera, ej. `grupo@compra-conjunta.app`) y
   una contraseña.
4. Marca **Auto Confirm User** al crearlo (si no lo marcas, Supabase
   intentará enviar un correo de confirmación que nunca llegará, porque el
   correo no es real). Si se te pasó, puedes editar el usuario después y
   confirmarlo manualmente desde la misma pantalla.
5. Comparte ese correo y contraseña con el grupo — es lo único que
   necesitan para entrar.

Si más adelante quieres cambiar la contraseña compartida, edítala desde el
mismo panel de Authentication → Users, y avisa al grupo.

## 2. Configurar la app

1. Abre `config.js` en esta carpeta.
2. Reemplaza `YOUR_SUPABASE_PROJECT_URL` y `YOUR_SUPABASE_ANON_KEY` con los
   valores que copiaste. Guarda el archivo.

## 3. Subir a GitHub Pages (gratis)

1. Crea un repositorio nuevo en GitHub (puede ser público o privado si tienes
   GitHub Pro; para Pages público, un repo público es lo más sencillo).
2. Sube estos tres archivos a la raíz del repositorio: `index.html`,
   `config.js`, y (opcionalmente, por si necesitas volver a crear las tablas)
   `schema.sql`.
3. Ve a **Settings → Pages** en el repositorio.
4. En "Source", elige la rama `main` (o `master`) y la carpeta `/ (root)`.
   Guarda.
5. Espera un minuto y GitHub te dará una URL del tipo:
   `https://tu-usuario.github.io/nombre-del-repo/`
6. Comparte esa URL con tu grupo. No necesitan cuenta de nada — simplemente
   abren el enlace en el móvil o el ordenador.

## Cómo funciona la sincronización

Cada vez que alguien crea un pedido, añade una persona, cambia una cantidad,
o marca algo como pagado, el cambio se guarda directamente en tu base de
datos de Supabase y se retransmite en tiempo real a todos los que tengan la
página abierta. No hace falta exportar ni importar nada manualmente — es
como la versión que probaste, pero sin depender de una cuenta de Claude.

## Novedades de esta versión

- **Pestaña Usuarios**: añade a cada persona una vez (nombre, teléfono,
  usuario de Revolut). El organizador y las personas de cada pedido se
  eligen ahora de una lista desplegable, así los nombres siempre coinciden
  en Balances.
- **Pedidos plegables**: cada pedido se muestra colapsado (nombre +
  organizador); toca para expandir y ver la tabla completa. Botones para
  **Editar** (cambiar transporte, productos, precios) y **Marcar
  completado** (avisa si aún quedan saldos pendientes relacionados, pero
  permite continuar igualmente).
- **Pedidos activos vs. completados**: un pedido marcado como completado
  sigue en "Pedidos" con una insignia verde durante 10 días, y después pasa
  automáticamente a la pestaña **Completados**. Los pedidos completados
  siguen disponibles para copiar al crear uno nuevo.
- **Copiar pedido anterior**: en "Nuevo pedido", un desplegable permite
  copiar el proveedor, el transporte y los productos (editables) de
  cualquier pedido previo. Las personas nunca se copian — siempre empieza
  vacío.
- **Marcar pagado con registro**: al marcar un saldo como pagado, se pide
  quién lo marca y la fecha (hoy por defecto, editable). Queda guardado y
  visible en la lista.
- **Historial de pagos**: un saldo pagado permanece en la lista principal
  10 días y después pasa a un historial aparte, mostrando los 5 más
  recientes con un botón para ir mostrando más de 10 en 10. Se puede
  reabrir ("Marcar pendiente") desde cualquiera de las dos listas.
- **Bizum y Revolut**: si la persona tiene teléfono, aparece un botón
  Bizum que copia un resumen listo para pegar. Si tiene usuario de Revolut,
  aparece un botón que abre un enlace de pago con el importe
  precumplimentado.
- **Exportar cada pedido** a CSV o Excel (.xlsx), con la opción de que los
  productos aparezcan en filas o en columnas, y una columna/fila de
  totales — pensado para pegar en la plantilla propia de cada proveedor.

## Nota sobre el enlace de Revolut

El botón de Revolut usa el formato `https://revolut.me/<usuario>/<importe>EUR`.
Este formato de precumplimentado de importe no está documentado oficialmente
por Revolut de forma pública — funciona en la práctica según integraciones de
terceros, pero **pruébalo una vez con un importe pequeño antes de confiar en
él para el grupo**. Si el importe no se rellena solo, el enlace abrirá igualmente
el perfil de Revolut de la persona para que paguen manualmente.

## Nota de seguridad

La clave `anon` sigue siendo pública por diseño (así funciona Supabase con
apps sin backend propio) y sigue visible en el código de la página — pero
ya no basta por sí sola. Con `schema.sql` actualizado, la base de datos
exige una sesión iniciada (vía el usuario compartido) para leer o escribir
cualquier dato. Alguien con solo el enlace, sin las credenciales, no puede
ver ni tocar nada.

El teléfono sigue siendo solo para generar el texto de Bizum — no se
procesa ningún pago dentro de la app.

Si alguna vez sospechas que la contraseña compartida se ha filtrado más
allá del grupo, cámbiala desde Supabase (Authentication → Users) y
compártela de nuevo solo con quien corresponda.

## Límites del plan gratuito de Supabase

Generosos para este uso: 500 MB de base de datos y hasta 50.000 usuarios
activos al mes en el nivel gratuito. Para un grupo de amigos organizando
compras, no deberías acercarte a esos límites. Si el proyecto queda inactivo
más de una semana, Supabase puede pausarlo automáticamente en el plan
gratuito; basta con entrar al panel y reactivarlo con un clic si eso pasa.
