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

   ⚠️ If you had an earlier version of these tables, the schema has changed
   again — the net-level `payments` table is gone, replaced by a proper
   per-order, per-person ledger (`order_payments`), and `revolut_handle` has
   been removed from `users`. Run this first to start clean:
   ```sql
   drop table if exists payments;
   drop table if exists order_payments;
   drop table if exists orders;
   drop table if exists users;
   ```
   This deletes any pedidos/balances you had loaded — there's no automatic
   migration from the old shape.
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

- **Fecha límite de pedido**: cada pedido tiene una fecha; pasada esa fecha,
  la tabla de personas/cantidades se bloquea (solo lectura) hasta que edites
  el pedido y amplíes la fecha.
- **Pedido más compacto**, colapsado por defecto mostrando solo el nombre y
  el organizador; toca para expandir.
- **Cierre automático real**: un pedido se marca "Completo" en cuanto todas
  las personas (menos el organizador, que no se paga a sí mismo) han pagado
  su parte — sin que nadie tenga que tocar nada. El botón "Marcar
  completado" sigue existiendo como cierre manual/forzado, y avisa si
  quedan saldos sin cobrar antes de confirmar. Si luego se reabre un pago
  individual, el pedido vuelve a activo automáticamente (salvo que se cerró
  con el botón manual, que es permanente hasta pulsar "Reabrir pedido").
- Dentro de cada pedido expandido: **recaudado / pendiente** en cifras, y
  los nombres se marcan en verde y tachado (pagado) o en rojo (pendiente)
  una vez pasada la fecha límite.
- **Balances en tres bloques**: pagos requeridos (con algún pedido ya
  pasado de fecha), pagos pendientes (todavía en plazo), e historial
  (pagado hace 10+ días). Un saldo neto se archiva al historial solo
  cuando lleva 10 días completamente saldado — si surge una deuda nueva
  entre esas dos personas, vuelve a aparecer como pendiente automáticamente.
- **Cada saldo neto es desplegable**: muestra los pedidos concretos que lo
  componen (proveedor, fecha, quién debe a quién), y cada uno de esos se
  puede desplegar otra vez para ver qué compró esa persona. Cada pedido
  individual dentro del desglose se puede marcar pagado o pendiente por
  separado — con Bizum, quién lo marca y la fecha — sin esperar al saldo
  neto completo. Esto se refleja al instante en el pedido original, en el
  saldo neto, y en las cifras de recaudado/pendiente.
- Los registros de pago dicen ahora **"Marcado por"** en vez de "Por",
  para no dar a entender que esa persona es quien pagó (puede ser el
  organizador confirmando el cobro).
- **Exportar movimientos** por cada saldo neto: descarga un CSV con todos
  los pedidos que componen esa relación entre dos personas, su estado y
  quién los marcó — un extracto de cuenta entre ambos.
- Se han quitado todas las referencias a Revolut (botón, campo de usuario,
  enlaces). Si quieres recuperarlo más adelante, dímelo.

## Importar productos de un proveedor

En "Nuevo pedido" (y al editar uno existente) hay dos formas de traer los
nombres de producto tal cual, sin volver a teclearlos:

- **Pegar lista**: copia la columna de productos de la plantilla del
  proveedor (Excel, Word, PDF con tabla, lo que sea) y pégala en el cuadro
  de texto. Si el precio va en la misma línea (como al copiar una fila de
  Excel o de una tabla de Word), se detecta solo; si no, se importa solo el
  nombre y el precio se rellena a mano.
- **Subir archivo (Excel o CSV)**: sube el archivo del proveedor, aparece
  una vista previa de las primeras filas con columnas A, B, C…, eliges cuál
  es la columna del nombre y, si quieres, la del precio, y desde qué fila
  empezar (para saltar cabeceras). Importa todos los productos de golpe.

En ambos casos, los productos importados se añaden a la lista normal y
siguen siendo editables ahí — puedes corregir un nombre o un precio antes
de crear el pedido, o más tarde volviendo a editarlo.

Los archivos Word (.docx) no se leen directamente todavía — para esos,
usa "Pegar lista": abre la tabla en Word, selecciona la columna, copia y
pega en el cuadro de texto.

La importación asistida por IA (para que reconozca la columna de productos
sola, sin que elijas tú cuál es) necesitaría un pequeño servidor propio
para guardar la clave de la API de forma segura — es un paso más grande,
así que queda para más adelante si te sigue haciendo falta después de
probar estas dos opciones.

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
