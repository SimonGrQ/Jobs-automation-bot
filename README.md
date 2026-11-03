# JobBot

JobBot es un asistente local para descubrir ofertas de MedTech e IA en salud, priorizarlas y hacer seguimiento de candidaturas. Puede buscar en tableros públicos de Greenhouse y Lever y en las páginas públicas de Tecnoempleo, además de importar URL manualmente. El navegador solo rellena campos personales reconocibles y vacíos: **nunca envía una solicitud**.

## Requisitos

- Windows 10/11.
- Python 3.11 o posterior desde [python.org](https://www.python.org/downloads/windows/). En el instalador, activa **Add python.exe to PATH** o instala el lanzador `py`.
- Acceso a Internet para consultar las fuentes públicas y descargar Chromium.

Todo el almacenamiento es local: SQLite en `data\`, informes en `reports\` y logs en `logs\`. El archivo `profile.json`, la base de datos, el navegador persistente y los secretos locales están excluidos de Git.

## Instalación en Windows

Abre PowerShell en la carpeta del proyecto y ejecuta:

```powershell
.\setup_windows.bat
```

El script crea `.venv`, instala las dependencias, instala Chromium para Playwright y copia `profile.example.json` a `profile.json` solo si aún no existe. No instala ni inicia ninguna tarea programada.

Si prefieres los comandos manuales:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
python -m playwright install chromium
Copy-Item profile.example.json profile.json
```

Edita `profile.json` y `config.yaml` antes de usar la aplicación. Rellena los datos personales que quieras que JobBot pueda autorrellenar dentro del objeto `personal`; los campos vacíos no se pueden completar. No añadas datos que no quieras usar en formularios.

## Configuración

### Perfil

El perfil editable está en `profile.json` y se valida al usar el programa. Incluye la formación, las competencias y los proyectos conocidos, pero los campos de contacto están vacíos. Completa únicamente los datos que hayas verificado personalmente. El archivo está ignorado por Git.

Campos personales disponibles: `first_name`, `last_name`, `email`, `phone`, `city`, `linkedin_url` y `website_url`. No añadas contraseñas, cookies, tokens ni respuestas legales sensibles.

### Fuentes Greenhouse y Lever

Edita `config.yaml`:

```yaml
greenhouse_boards:
  - identificador_publico_del_tablero
lever_sites:
  - identificador_publico_de_la_empresa
```

El identificador de Greenhouse es el board token usado por su Job Board API pública. El de Lever es el nombre del sitio usado por su endpoint público. No son credenciales. El acceso a los endpoints puede variar o dejar de estar disponible.

`python -m jobbot.cli test-sources` muestra separadamente las fuentes no configuradas, las consultadas correctamente (también si no devuelven ofertas) y las no disponibles. Una fuente con error no se informa como si hubiera confirmado que no existen ofertas.

### Tecnoempleo

JobBot consulta las páginas públicas de ofertas de Tecnoempleo usando como términos de búsqueda las palabras clave definidas en `scoring.keyword_weights`. Las consultas se limitan a una por término y se espacian para reducir la carga. Los resultados se puntúan con la misma configuración que Greenhouse y Lever. Tecnoempleo está orientado principalmente a España; ajusta las palabras clave para controlar qué ofertas se buscan.

### Importar URL manuales

Crea un CSV con una columna `url` (puedes añadir `title`, `company`, `location`, `description` y `date_posted`) o un JSON:

```json
[
  {
    "url": "https://careers.example.com/jobs/123",
    "title": "Biomedical Engineer",
    "company": "Example"
  }
]
```

Importa los registros con:

```powershell
.\.venv\Scripts\python.exe -m jobbot.cli import-urls .\jobs.csv
```

Se validan URL HTTP(S) y se etiqueta la plataforma probable. Las URL manuales se guardan como ofertas sin intentar extraer datos de la página. Workday, LinkedIn y portales no compatibles requieren revisión manual; no se eluden inicios de sesión, CAPTCHA, controles de acceso o restricciones del sitio.

### Puntuación

`config.yaml` contiene pesos de palabras clave, la penalización para puestos sénior con requisitos explícitos de experiencia extensa y el umbral mínimo. El cálculo es determinista y registra términos coincidentes, desglose y motivo si queda por debajo del umbral. El umbral no elimina la oferta de la base de datos.

### Filtro geográfico

Usa `run --region España`, `run --region Europa`, `run --region "Reino Unido"`, `run --region Italia`, `run --region Francia`, `run --region Suiza` o `run --region Alemania`. Puedes repetir `--region` para incluir varias regiones en la misma búsqueda. El filtro se aplica a la ubicación publicada; ofertas remotas o sin ubicación identificable se excluyen si hay un filtro activo. Los puestos guardados previamente también pueden filtrarse con `top --region ...` y `list --region ...`. Sin filtro se mantienen todas las ubicaciones. Los portales que no permiten una consulta geográfica oficial se filtran localmente por la ubicación de sus resultados públicos.

## Uso de la CLI

Se puede usar `.\.venv\Scripts\python.exe -m jobbot.cli ...` o activar el entorno virtual y ejecutar `python -m jobbot.cli ...`. Todos los subcomandos tienen ayuda; por ejemplo:

```powershell
python -m jobbot.cli --help
python -m jobbot.cli run
python -m jobbot.cli list
python -m jobbot.cli top
python -m jobbot.cli run --region España
python -m jobbot.cli run --region España --region Alemania
python -m jobbot.cli show 1
python -m jobbot.cli status 1 shortlisted
python -m jobbot.cli import-urls .\jobs.json
python -m jobbot.cli report
python -m jobbot.cli test-sources
python -m jobbot.cli search-portals
python -m jobbot.cli search-companies
python -m jobbot.cli search-companies --company "Quibim" --company "Seqera" --open
python -m jobbot.cli assist 1
python -m jobbot.cli web
```

- `run`: consulta fuentes configuradas, puntúa/actualiza la base de datos, muestra las cinco ofertas con mayor puntuación de puestos únicos y genera informes. No abre solicitudes.
- `run --region REGIÓN`: limita las ofertas nuevas guardadas, el top y el informe a la ubicación indicada. Repite `--region` para combinar regiones. Opciones: `España`, `Europa`, `Reino Unido`, `Italia`, `Francia`, `Suiza` y `Alemania`. Sin filtro, incluye todas las regiones.
- `list`, `show ID`: consulta ofertas, puntuación y URL; `list` las ordena de mayor a menor puntuación. `list --region REGIÓN` filtra las ofertas almacenadas.
- `top`: muestra hasta cinco puestos únicos ordenados por puntuación, con su URL. Publicaciones de la misma empresa con el mismo título normalizado (incluidas variantes `(m/f/d)`) aparecen una sola vez; se conserva como representante la de mayor puntuación y las demás siguen disponibles en `list`. Usa `top --region REGIÓN` para filtrar el ranking.
- `status ID ESTADO`: acepta `new`, `shortlisted`, `reviewed`, `application_prepared`, `applied`, `rejected`, `saved` o `closed`. Por ejemplo, después de enviar tú mismo la solicitud, ejecuta `python -m jobbot.cli status 1 applied`.
- `import-urls FILE`: importa un CSV o JSON local.
- `report`: vuelve a crear informes desde SQLite.
- `test-sources`: prueba las fuentes configuradas.
- `search-portals`: muestra enlaces de búsqueda manual para JobLeads, LinkedIn Jobs en Europa e InfoJobs. Añade `--open` para abrirlos en el navegador. La búsqueda, filtros y selección de ofertas se hacen manualmente; importa las URLs seleccionadas con `import-urls`.
- `search-companies`: muestra los portales oficiales de careers/empleo encontrados para las 29 empresas objetivo y enlaces externos cuando no se localizó un portal oficial. Usa `--company "Nombre"` para filtrar (repetible) y `--open` para abrir los enlaces seleccionados. Esta búsqueda es manual y no altera `run`; revisa las ofertas y usa `import-urls` para guardarlas.
- `assist ID`: abre la URL y rellena campos seguros y vacíos con datos verificados del perfil. Usa el ID mostrado por `top` o `list`; revisa el formulario y envíalo tú manualmente.
- `web`: inicia la interfaz web local en `http://127.0.0.1:8765/`. Desde el panel puedes ejecutar búsquedas, filtrar por región/texto/estado, revisar ofertas y actualizar su estado, y editar los campos personales de `profile.json`. Detén el servidor con `Ctrl+C`.

`run_jobbot.bat` ejecuta manualmente el descubrimiento y los informes.

La interfaz web solo escucha en `127.0.0.1`, no en la red local; sirve HTML estático local y no carga librerías de terceros. Los cambios requieren un token de sesión generado al arrancar. El selector de términos carga las palabras clave definidas en `config.yaml`; por defecto usa todas para la búsqueda MedTech/IA en salud. El editor permite añadir, quitar o cambiar pesos y guarda el scoring en `config.yaml`. El botón **Ver top 5** muestra los cinco puestos únicos de mayor puntuación con las regiones seleccionadas, sin depender de los filtros de texto o estado. Cada tarjeta incluye un enlace a la oferta: al abrirlo, la app guarda **Oferta abierta**, pero no lo confunde con una solicitud enviada. La casilla **Solicitud enviada (Sí/No)** se marca manualmente solo después de confirmar que completaste el envío; ese dato y el estado `applied` se guardan en la base SQLite local y aparecen en los informes. Los rechazos se registran eligiendo `rejected` en el estado. El botón **Autorrellenar** abre Chromium y rellena solo campos seguros y vacíos; mantén esa ventana abierta para revisar el formulario. JobBot no envía solicitudes. En Windows también puedes iniciar la interfaz con `run_jobbot_web.bat`.

## Autorrellenado asistido y privacidad

`assist ID` abre Chromium visible y deja la página abierta hasta que pulses Enter en la consola. Solo considera campos de texto/email/teléfono/URL y rellena únicamente valores conocidos, campos vacíos y etiquetas reconocidas. El detector considera etiquetas, `name`, `id`, `autocomplete`, `aria-label`, `aria-labelledby`, `placeholder` y `title`. Los valores existentes se conservan. Si todos los campos personales del perfil están vacíos, JobBot lo informa y no abre el navegador.

Work authorization, patrocinio de visado, salario, datos demográficos, antecedentes, certificaciones, disponibilidad, reubicación y consentimientos se excluyen deliberadamente. Comprueba siempre los datos y la página antes de continuar. El navegador puede requerir que completes manualmente inicio de sesión, MFA o CAPTCHA; JobBot no automatiza ni elude esos pasos.

Por defecto, el contexto del navegador no conserva cookies entre ejecuciones. La opción explícita `assist ID --persistent` conserva datos de sesión localmente en `browser-data\`; utilízala solo en un perfil de Windows privado y recuerda que las cookies permiten acceder a sesiones autenticadas. No se almacenan contraseñas ni se envía el perfil a servicios de IA.

El autorrellenado depende del HTML y accesibilidad de cada portal y no puede reconocer universalmente todos los formularios. En sitios no compatibles, completa la solicitud manualmente.

## Informes y datos

Cada ejecución genera informes `reports\jobbot-AAAA-MM-DD.html` y `.csv`; si ya existen para ese día, añade una marca de tiempo para no sobrescribirlos. El informe HTML incluye los cinco puestos únicos con mayor puntuación (la misma empresa y el mismo título normalizado se muestran una vez), las ofertas ordenadas por puntuación, enlaces, ofertas relevantes nuevas y anteriores, y una sección separada con ofertas excluidas por el umbral y su motivo. El HTML escapa el contenido recibido y los campos de texto CSV se protegen frente a fórmulas de hoja de cálculo. La base de datos conserva estado y notas cuando una oferta se actualiza; las URL normalizan parámetros de seguimiento conocidos, preservando los parámetros funcionales y el enlace original.

Los logs rotativos se escriben en `logs\jobbot.log`; no registran valores personales rellenados. No compartas la base de datos, informes ni logs sin revisarlos.

## Programación diaria a las 09:00

python -m jobbot.cli search-companies
python -m jobbot.cli search-companies --company "Quibim" --company "Seqera" --openLa tarea programada ejecuta únicamente descubrimiento e informes. No abre páginas de solicitud. Instálala explícitamente desde PowerShell:

```powershell
.\schedule_jobbot.ps1 -Action Install
.\schedule_jobbot.ps1 -Action Inspect
.\schedule_jobbot.ps1 -Action Run
.\schedule_jobbot.ps1 -Action Remove
```

El script registra o reemplaza la tarea `JobBot Daily Discovery`, usa el Python de `.venv` y establece la carpeta del proyecto como directorio de trabajo. La hora 09:00 es local. El equipo debe estar encendido y despierto; la tarea no configura el despertar del equipo. Los fallos y resultados se pueden consultar en el historial del Programador de tareas y en `logs\jobbot.log`.

## Pruebas

Con las dependencias instaladas:

```powershell
python -m pytest
```

Las pruebas usan SQLite temporal, respuestas HTTP simuladas y una página HTML local para el autorrellenado. No necesitan credenciales ni sitios de contratación reales. La prueba del navegador requiere Chromium instalado mediante Playwright.

## Limitaciones conocidas

- Greenhouse y Lever se consultan mediante endpoints públicos; la disponibilidad depende de cada proveedor y empresa.
- Tecnoempleo se consulta desde su página pública de ofertas con los términos de `scoring.keyword_weights`; los cambios en su sitio pueden afectar la extracción.
- Las URL importadas manualmente no se extraen ni se enriquecen automáticamente.
- JobLeads, LinkedIn e InfoJobs se ofrecen como enlaces de búsqueda manual; JobBot no extrae automáticamente sus resultados. LinkedIn prohíbe el acceso automatizado sin permiso; InfoJobs no expone en este proyecto una interfaz pública autorizada de búsqueda; JobLeads no proporcionó un endpoint público de búsqueda accesible. InfoJobs está orientado principalmente a España, aunque LinkedIn tiene un enlace de búsqueda para Europa.
- No se automatizan LinkedIn, Workday o formularios protegidos de forma universal.
- No hay envío automático, selección de opciones legales, subida automática de CV ni integración con API privadas de solicitud.
- La revisión humana final es obligatoria.

## Solución de problemas

- **`py` no se reconoce:** instala Python 3.11+ y el lanzador de Windows; vuelve a abrir PowerShell.
- **Falta `profile.json`:** ejecuta `Copy-Item profile.example.json profile.json` y edítalo.
- **No se encuentra Chromium:** activa el entorno virtual y ejecuta `python -m playwright install chromium`.
- **Fuente `not_configured`:** añade el identificador público correspondiente a `config.yaml`.
- **Fuente `unavailable`:** comprueba la conexión, el identificador y el endpoint del proveedor. El resultado no significa que no haya ofertas.
- **Formulario no reconocido o timeout:** completa la página manualmente; no compartas credenciales con JobBot.
