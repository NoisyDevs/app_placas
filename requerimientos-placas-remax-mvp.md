# Requerimientos del proyecto: Generador de Placas para Agentes RE/MAX (MVP)

## Resumen ejecutivo

Herramienta self-serve que le permite a un agente inmobiliario RE/MAX generar placas de marketing (feed, story, WhatsApp) en pocos minutos, sin depender de Canva ni de diseño manual. El agente carga los datos y fotos de una propiedad, elige un template pre-diseñado y alineado a la identidad RE/MAX, y descarga las imágenes listas para publicar con sus datos de contacto estampados. Además de placas de **publicación** de una propiedad, soporta placas de **búsqueda** ("busco para un cliente"). En el roadmap post-MVP suma la generación de descripciones del aviso con IA (tier de suscripción superior).

El producto ataca un dolor diario, repetitivo y visible, y apunta a un público que puede comprar por impulso: el agente individual. El modelo es freemium (10 placas gratis por mes, **sin marca de agua** para respetar la identidad RE/MAX; upgrade mensual para uso ilimitado). El crecimiento se apoya en el boca a boca dentro de las oficinas y en el canal de distribución (contacto que revende en su oficina).

## Usuarios y roles

- **Agente RE/MAX (usuario principal, único rol del MVP)**: agente inmobiliario individual que gestiona sus propias propiedades y su propia presencia en redes/WhatsApp. Self-serve, sin onboarding asistido. Trabaja mayormente desde el celular. No requiere conocimientos de diseño.

> Nota: en el MVP no hay rol de oficina/broker ni de administrador. Se difiere a versiones futuras (ver "Fuera de alcance").

## Alcance del MVP

### Incluye

- Registro / login del agente (cuenta persistente).
- Perfil del agente **persistente** (se carga una vez, se reutiliza en todas las placas): foto, nombre, WhatsApp, red social opcional.
- Carga **one-shot** de una propiedad (los datos NO se guardan; se usan solo para generar y se descartan).
- Generación de dos tipos de placa: **publicación** (propiedad concreta, con fotos) y **búsqueda** (busco para un cliente, sin fotos, con placeholder ilustrativo según tipo).
- Opción de generar la placa **con o sin los datos de contacto del agente** (manteniendo la matrícula), para compartir entre colegas.
- Catálogo de **templates fijos** pre-diseñados con identidad RE/MAX (el agente elige, no personaliza).
- Generación de la placa en dos relaciones de aspecto: **1:1 (feed)** y **9:16 (story / estado de WhatsApp)**.
- Preview antes de generar.
- Descarga y/o compartir de las imágenes generadas.
- Modelo **freemium**: 10 placas gratis por mes, **sin marca de agua**; upgrade a plan pago (uso ilimitado).

### Fuera de alcance (versiones futuras)

- Cartera de propiedades persistente (guardar y reutilizar propiedades).
- Personalización de templates por el agente (colores, posición, fuentes).
- Ficha/landing pública por propiedad con QR.
- Reporte de actividad para el propietario.
- CRM / seguimiento de buscadores.
- Rol de oficina/broker, gestión multi-agente, white-label.
- Collage avanzado / carruseles multi-slide.
- **Descripciones con IA** a partir de fotos + datos: se difiere a post-MVP, como tier de suscripción superior (ver Épica 4). Pendiente análisis de costo por generación.

## Épicas y User Stories

### Épica 1: Cuenta y perfil del agente

**Historia 1.1 — Registro e inicio de sesión**

Como agente,
quiero crear una cuenta e iniciar sesión,
para que mi perfil y mi uso queden asociados a mí y no tener que recargar mis datos.

Criterios de aceptación:
- [ ] Puedo registrarme con email (magic link o email + contraseña).
- [ ] Puedo volver a iniciar sesión y recuperar mi perfil.
- [ ] La sesión persiste entre usos (no me pide login cada vez).
- [ ] Mis datos están aislados de los de otros agentes.

**Historia 1.2 — Completar y editar mi perfil**

Como agente,
quiero cargar una vez mi foto, nombre y contacto,
para que se estampen automáticamente en todas mis placas sin recargarlos.

Criterios de aceptación:
- [ ] Puedo subir/cambiar mi foto de perfil.
- [ ] Puedo cargar/editar: nombre, número de WhatsApp, red social (opcional), matrícula (opcional).
- [ ] Si el template lo requiere, la matrícula se estampa automáticamente en la placa.
- [ ] Los datos se guardan y se reutilizan en cada placa que genero.
- [ ] Puedo editar mi perfil en cualquier momento.
- [ ] La app me avisa si intento generar una placa con el perfil incompleto (falta foto o WhatsApp).

### Épica 2: Generación de placas (core)

**Historia 2.1 — Cargar los datos de una propiedad**

Como agente,
quiero cargar los datos de una propiedad,
para generar una placa con esa información.

Criterios de aceptación:
- [ ] Puedo ingresar: operación (venta/alquiler), tipo (casa, depto, PH, lote, etc.), precio (con opción de ocultarlo / mostrar "Consultar"), moneda (USD/ARS), zona/barrio (no dirección exacta).
- [ ] Puedo ingresar características: ambientes, dormitorios, baños, m², cochera (los campos vacíos no se muestran en la placa).
- [ ] Puedo subir fotos de la propiedad; la cantidad admitida depende del template elegido (algunos usan 1 foto principal, otros permiten varias).
- [ ] Los datos cargados NO se persisten después de generar (one-shot).

**Historia 2.2 — Elegir un template**

Como agente,
quiero elegir entre varios templates pre-diseñados,
para que la placa tenga una estética profesional y alineada a RE/MAX sin que yo tenga que diseñar.

Criterios de aceptación:
- [ ] Veo un catálogo de templates fijos (3–5 en el MVP).
- [ ] Cada template respeta la identidad de marca RE/MAX aprobada.
- [ ] Al seleccionar un template, veo cómo queda con mis datos reales (preview).
- [ ] No puedo modificar colores/posición del template (personalización difererida).

**Historia 2.3 — Previsualizar y generar**

Como agente,
quiero ver la placa antes de generarla y luego obtenerla en los formatos que uso,
para publicarla directo en mis redes y WhatsApp.

Criterios de aceptación:
- [ ] Veo un preview con mis datos + los de la propiedad + mi contacto estampado.
- [ ] Genero la placa en formato 1:1 (feed) y 9:16 (story/estado).
- [ ] La generación tarda un tiempo razonable (objetivo: pocos segundos).
- [ ] Las placas no llevan marca de agua en ningún tier (para respetar la identidad RE/MAX).

**Historia 2.4 — Descargar / compartir**

Como agente,
quiero descargar o compartir la placa generada,
para publicarla sin fricción.

Criterios de aceptación:
- [ ] Puedo descargar las imágenes a mi dispositivo.
- [ ] Puedo compartir directo (share sheet del sistema: Instagram, WhatsApp, etc.).
- [ ] Las imágenes salen en buena resolución para redes.

**Historia 2.5 — Generar placa de búsqueda**

Como agente,
quiero generar una placa de "búsqueda" (busco una propiedad para un cliente),
para conseguir propiedades que matcheen lo que busca mi cliente y mostrar actividad.

Criterios de aceptación:
- [ ] Al crear una placa, puedo elegir el tipo: **publicación** (propiedad concreta) o **búsqueda**.
- [ ] En búsqueda ingreso: operación buscada (compra/alquiler), tipo buscado (casa, depto, PH, lote), zona, rango de presupuesto (opcional), características deseadas (ambientes/dormitorios).
- [ ] La placa de búsqueda no lleva fotos: usa un placeholder ilustrativo según el tipo buscado (casa, depto, lote, etc.), alineado a la estética RE/MAX.
- [ ] Elijo un template de búsqueda y genero en 1:1 y 9:16, igual que una publicación.

**Historia 2.6 — Placa sin datos de contacto (compartir entre colegas)**

Como agente,
quiero poder generar una placa sin mis datos de contacto (pero con matrícula si el template la requiere),
para compartirla con colegas y que circule entre agentes (co-broke).

Criterios de aceptación:
- [ ] Al generar, puedo activar/desactivar "incluir mis datos de contacto".
- [ ] Con la opción desactivada, la placa no muestra foto, nombre, WhatsApp ni redes del agente.
- [ ] La matrícula se mantiene aunque los datos de contacto se oculten, si el template la requiere (obligación legal).
- [ ] Con la opción activada (default), la placa incluye mis datos como siempre.

### Épica 3: Monetización (freemium)

**Historia 3.1 — Límite del tier gratuito**

Como negocio,
quiero limitar la cantidad de placas gratis por mes (sin usar marca de agua),
para incentivar el upgrade sin tocar la identidad RE/MAX de las piezas.

Criterios de aceptación:
- [ ] El usuario gratuito puede generar hasta **10 placas por mes**.
- [ ] Las placas gratuitas NO llevan marca de agua (decisión tomada para evitar fricción con la marca RE/MAX).
- [ ] Al alcanzar el límite, se le ofrece hacer upgrade.
- [ ] El contador se reinicia mensualmente.

**Historia 3.2 — Upgrade a pago**

Como agente,
quiero pasar a un plan pago,
para generar placas sin límite mensual.

Criterios de aceptación:
- [ ] Puedo ver el precio (~USD 10/mes, expresado en ARS con cláusula de tipo de cambio) y qué desbloquea el plan pago.
- [ ] Puedo suscribirme (medio de pago a definir; ej. Mercado Pago).
- [ ] Al ser pago: uso ilimitado de placas (publicación y búsqueda), todos los templates y formatos.
- [ ] Si vence/cancelo, vuelvo a las condiciones del tier gratuito (10 placas/mes).

### Épica 4: Descripciones con IA (POST-MVP — tier de suscripción superior)

> **Fuera del MVP.** Feature con **costo por generación** (llamada a modelo con visión). Se difiere a una fase posterior y se ofrecería en un tier de suscripción superior al plan pago base. Requisito previo: analizar el costo por generación para dimensionar el precio de ese tier.

**Historia 4.1 — Generar descripción de la propiedad con IA**

Como agente,
quiero que una IA me genere una descripción de la propiedad (compacta y extendida) a partir de los datos y las fotos,
para publicar el aviso sin tener que redactarlo.

Criterios de aceptación:
- [ ] A partir de los datos cargados + las fotos, la IA genera dos versiones: **compacta** (redes/WhatsApp) y **extendida** (portales/aviso).
- [ ] Las descripciones están en español (Argentina), con tono profesional inmobiliario.
- [ ] La IA se basa en los datos reales cargados y en lo observable en las fotos; no inventa características que no estén presentes.
- [ ] Puedo copiar cada versión con un toque.
- [ ] El acceso a esta feature está sujeto al gating definido (pago o cupo), por su costo por uso.

## Requerimientos no funcionales

- **Plataforma**: Flutter, con **dos destinos desde una sola base de código**: (1) una **app mobile nativa** (Android/iOS, instalable desde las tiendas) y (2) una **web app** (se usa desde el navegador). No es una única página web responsive haciendo de ambas: son dos productos. La web app, además, debe ser **responsive** (adaptarse a laptop, tablet y navegador de celular). Nota para el arquitecto: confirmar que el codebase único cubre bien las diferencias por plataforma (subida de fotos, compartir/share, descarga en web).
- **Performance**: generación de una placa en pocos segundos (objetivo <5 s). Concurrencia baja al inicio; escalable.
- **Seguridad / aislamiento**: Supabase Auth + RLS. Cada agente accede solo a su perfil y su uso (aislamiento por `agent_id`, alineado al patrón multi-tenant ya conocido).
- **Privacidad de datos**: las fotos de propiedad son efímeras (one-shot). Se procesan para generar y se descartan / no se almacenan de forma permanente.
- **Datos sensibles**: no se manejan datos financieros ni personales sensibles del comprador; los datos de contacto del agente son públicos por naturaleza.
- **Disponibilidad**: no requiere 24/7 crítico ni offline en el MVP.
- **Integraciones**: share sheet nativo para publicar; modelo de IA con visión para las descripciones (Épica 4, post-MVP).
- **Integración de pagos (Mercado Pago Suscripciones)**: el cobro del plan pago se hace con el producto de **suscripciones / pagos recurrentes de Mercado Pago** (endpoint `preapproval`), integrable desde el backend FastAPI. El agente autoriza una vez y MP cobra automáticamente cada mes, con reintentos ante rechazos. El dinero se acredita en la cuenta de Mercado Pago de Agus y de ahí se transfiere al banco (CBU). Consideraciones: (a) la comisión de MP + IVA (y retenciones provinciales) debe estar contemplada en el precio; (b) conviene evaluar el plazo de acreditación para reducir comisión, ya que una suscripción mensual no exige liquidez inmediata; (c) es necesario emitir factura por cada cobro (AFIP/monotributo), idealmente conectando facturación al cobro; (d) las cuentas **Pro de cortesía** (ej. el contacto) se marcan manualmente en el backend, sin pasar por el flujo de pago.
- **Costo variable de IA**: a diferencia de las placas (compositing, costo casi nulo por unidad), las descripciones con IA tienen costo por generación. Requiere gating (pago o cupo) y control de consumo para no erosionar el margen.

## Restricciones y supuestos

- **One-shot**: no se persisten propiedades en el MVP; solo persiste el perfil del agente. El modelo de datos se diseña para poder incorporar cartera persistente más adelante sin rehacer.
- **Templates fijos** en el MVP; la personalización por el agente queda diferida.
- **Separación de marca (app vs. placas)**: la UI de la app usa el **design system propio** (neutral, agnóstico de inmobiliaria). La identidad RE/MAX vive **únicamente dentro de los templates de placa** (el output). Esto permite ofrecer la misma app a otras inmobiliarias cambiando solo el pack de templates, sin rediseñar el producto. RE/MAX es el primer pack, no el tema de la app.
- **Branding RE/MAX pre-armado**: los templates de placa usan identidad RE/MAX. Uso validado a nivel del contacto agente, con una condición clara: **respetar los colores oficiales y no recortar, deformar ni alterar el logo**. Es a la vez un diferencial (placas "aprobadas" vs. improvisar en Canva) y una dependencia de marca a cuidar en cada template.
- **Pricing**: plan pago ~USD 10/mes, expresado en ARS con cláusula de tipo de cambio Banco Nación. Sin marca de agua en ningún tier; el gate del free es el límite de 10 placas/mes.
- **Distribución comercial**: el contacto recibe la versión Pro **sin cargo (canje)** a cambio de publicitar la app en su oficina. No hay comisión ni reparto de ingresos: los agentes que se suscriben pagan directo a Agus, quedándose el precio completo. Implica soportar cuentas marcadas como **Pro de cortesía**, separadas del flujo de pago normal.

## Preguntas abiertas

1. **Placeholders de búsqueda (recomendación)**: la idea inicial es "usar cualquier imagen de Google", pero productizar eso implica riesgo de copyright (la app sirviendo material sin licencia, junto a la marca RE/MAX). **Recomendado**: curar un set de imágenes con licencia libre para uso comercial (Unsplash/Pexels) o ilustraciones propias, por tipo de propiedad. A definir el set concreto.
2. **Costo de la IA (post-MVP)**: analizar el costo por generación (modelo con visión + descripción compacta y extendida) para dimensionar el tier de suscripción superior. No entra al MVP.
3. **Compositing**: server-side (Python/Pillow) vs. client-side (canvas en Flutter). → Se delega al arquitecto.

## Decisiones cerradas

- **Uso de marca RE/MAX**: validado a nivel del contacto agente. Condición: respetar colores oficiales y no recortar/deformar el logo.
- **Distribución**: canje — el contacto usa la Pro sin cargo a cambio de publicitar la app en su oficina. Sin comisión; los agentes pagan directo a Agus. Requiere soportar cuentas Pro de cortesía.
- **Límite del free**: 10 placas por mes.
- **Marca de agua**: no se usa en ningún tier (para no tocar la marca RE/MAX).
- **Precio del plan pago**: ~USD 10/mes (en ARS con cláusula Banco Nación).
- **Plataforma**: dos destinos desde un codebase Flutter único — app mobile nativa (Android/iOS) + web app responsive. No es una sola página responsive.
- **Pagos**: Mercado Pago Suscripciones (pagos recurrentes) para el plan pago; dinero a la cuenta MP → banco. Comisión + IVA contemplados en el precio; facturación por AFIP.
- **Descripciones con IA**: fuera del MVP; futuro tier de suscripción superior.
- **Cantidad de fotos por placa**: depende del template.
- **Matrícula**: se estampa cuando el template la requiere.
