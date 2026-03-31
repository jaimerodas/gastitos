# Gastitos

Un registro de gastos familiar. Permite llevar un control compartido de ingresos y egresos, organizados por categorías y agrupados por mes con un estado de resultados mensual.

## Requisitos

- Ruby 4.0.2
- SQLite 3

## Instalación

```bash
git clone <repo-url>
cd gastitos
bundle install
bin/rails db:setup
```

## Uso

```bash
bin/rails server
```

Al abrir la app por primera vez, se muestra un formulario para crear el primer usuario. Este usuario se convierte automáticamente en administrador. Los usuarios subsecuentes necesitan ser aprobados por un administrador antes de poder iniciar sesión.

### Transacciones

La pantalla principal es un formulario para registrar transacciones. Cada transacción tiene una fecha, un monto, una categoría y una descripción opcional. Las categorías determinan si la transacción es un ingreso o un gasto — el monto siempre se captura como positivo.

Las categorías se pueden crear directamente desde el formulario de transacciones.

### Periodos mensuales

En la sección de **Meses** se puede ver un estado de resultados por cada mes que tenga transacciones. Cada periodo muestra:

- Saldo inicial
- Ingresos agrupados por categoría
- Gastos agrupados por categoría
- Resultado neto
- Saldo final

Los periodos se crean automáticamente al registrar la primera transacción de un mes y se eliminan si se borran todas sus transacciones.

## Pruebas

```bash
bin/rails test
```
