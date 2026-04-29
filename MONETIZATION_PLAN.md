# Plan de Monetización y Proyecciones - Mis Finanzas

Este documento detalla la estrategia de negocio para la transición de la aplicación de una infraestructura 100% Firebase a un modelo híbrido "Local-First" con suscripción Premium.

## 1. Estrategia de Producto: Modelo Freemium

El objetivo es reducir los costos operativos a casi cero para usuarios gratuitos y ofrecer valor agregado tangible para los suscriptores.

### Niveles de Servicio (Tiering)

| Característica | Versión Gratuita (Local) | Versión Premium (Suscripción) |
| :--- | :--- | :--- |
| **Almacenamiento** | Local (SQLite/Isar) | Nube (Firebase Firestore) |
| **Sincronización** | No (Solo un dispositivo) | Multi-dispositivo (Móvil + Web) |
| **Seguridad** | Riesgo de pérdida (sin backup) | Backup automático y persistente |
| **Acceso Web** | No disponible | **Acceso total vía Web** |
| **Multiusuario** | No | Modo familiar (Hogar compartido) |
| **Exportación** | CSV Básico | PDF detallado + Reportes Excel |

---

## 2. Análisis de Costos e Infraestructura

### Costos Fijos (Distribución)
*   **Google Play Store:** $25 (pago único).
*   **Apple App Store:** $99 (anuales).
*   **Dominio Web:** ~$12 (anuales) para una URL personalizada (ej. `misfinanzas.app`).

### Costos Variables (Firebase Blaze Plan)
Al mover a los usuarios gratuitos a local, los costos de Firebase solo se activan para usuarios que generan ingresos.
*   **Firestore:** Costos mínimos basados en uso (centavos por usuario).
*   **Hosting/Auth:** Incluidos mayoritariamente en capas gratuitas o de bajo costo.

---

## 3. Proyecciones Financieras (Mensuales)

*Base de cálculo: Suscripción de USD 1.99/mes o USD 14.99/año. Ingreso neto estimado tras comisiones (15%) e impuestos: **USD 1.20 por suscriptor/mes**.*

| Suscriptores Premium | Ingreso Neto Tiendas | Costos Firebase/GCP | Costos Fijos (Amort.) | Ganancia Neta Mensual |
| :--- | :--- | :--- | :--- | :--- |
| **100** | $120 | $0 (Capa gratuita) | $8.25 | **$111.75** |
| **500** | $600 | $1 - $3 | $8.25 | **$588.75** |
| **1,000** | $1,200 | $5 - $10 | $8.25 | **$1,181.75** |
| **2,000** | $2,400 | $15 - $25 | $8.25 | **$2,366.75** |
| **5,000** | $6,000 | $40 - $60 | $8.25 | **$5,931.75** |
| **10,000** | $12,000 | $80 - $120 | $8.25 | **$11,871.75** |

---

## 4. Hoja de Ruta Técnica (Roadmap)

1.  **Abstracción de Datos:** Implementar un *Patrón de Repositorio* para desacoplar la lógica de negocio de la fuente de datos (Local vs Firebase).
2.  **Persistencia Local:** Integrar una base de datos local (Isar o SQLite) para el funcionamiento sin login.
3.  **Módulo de Migración:** Crear el flujo para subir datos locales a Firebase tras la suscripción.
4.  **Gestión de Pagos:** Implementar `in_app_purchase` para suscripciones en iOS y Android.
5.  **Versión Web:** Desplegar en Firebase Hosting para acceso exclusivo de usuarios Premium.

---

## 5. Gestión del Dominio Web

El dominio (ej. `misfinanzas.app`) es la dirección profesional de la plataforma web, fundamental para generar confianza en los suscriptores Premium.

*   **Costo:** Aproximadamente **USD 12/año** para extensiones `.com` o `.app`. Para dominios locales `.com.uy`, el costo asciende a **USD 20-30/año** (vía NIC.uy).
*   **Proveedores (Registrars):** Cloudflare, Namecheap o Squarespace (ex Google Domains).
*   **Integración con Firebase:**
    1.  Se adquiere el nombre en el proveedor externo.
    2.  Se vincula en la consola de Firebase Hosting mediante registros DNS (A y CNAME).
    3.  **Seguridad:** Firebase provee el certificado **SSL (HTTPS)** de forma gratuita y automática para el dominio personalizado.
*   **Valor Estratégico:** Facilita el acceso multi-dispositivo y permite alojar una página de aterrizaje (Landing Page) para captación de nuevos usuarios.

---
*Este plan busca maximizar la rentabilidad mediante la asimetría de costos: ingresos lineales con costos sub-lineales.*
