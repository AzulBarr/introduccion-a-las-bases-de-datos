SET search_path TO public;


CREATE TABLE "ticket" (
    "ticket_id" SERIAL PRIMARY KEY,
    "cliente_id" INTEGER NOT NULL,
    "fecha_compra" DATE NOT NULL,
    "hora_compra" TIME NOT NULL,
    "monto_total" NUMERIC(10,2) NOT NULL,
    "medio_pago" VARCHAR(20) NOT NULL,
    "localidad" VARCHAR(50) NOT NULL,
    "productos" INTEGER NOT NULL,
    "descuento_aplicado" BOOLEAN NOT NULL,
    "observaciones" TEXT
);



INSERT INTO "ticket" (
    "cliente_id", "fecha_compra", "hora_compra", "monto_total",
    "medio_pago", "localidad", "productos", "descuento_aplicado", "observaciones"
)
SELECT
    FLOOR(RANDOM() * 5000 + 1)::INT AS cliente_id,
    DATE '2024-01-01' + (FLOOR(RANDOM() * 451))::INT AS fecha_compra,
    TIME '08:00' + (FLOOR(RANDOM() * 720)) * INTERVAL '1 minute' AS hora_compra,
   ROUND((RANDOM() * (1000000 - 50000) + 50000)::NUMERIC, 2) AS monto_total,
    (ARRAY[
        'Efectivo', 'TD-Visa', 'TD-Maestro', 'TC-Visa', 'TC-Amex', 'TC-MC',
        'QR-Modo', 'QA-Meli', 'Transferencia', 'Cheque'
    ])[FLOOR(RANDOM() * 10 + 1)::INT] AS medio_pago,
    -- Localidad con espacios agregados
    (CASE
        WHEN RANDOM() < 0.33 THEN ' ' || localidad
        WHEN RANDOM() < 0.66 THEN localidad || ' '
        ELSE ' ' || localidad || ' '
    END) AS localidad,
    FLOOR(RANDOM() * 30 + 1)::INT AS productos,
    (RANDOM() < 0.3)::BOOLEAN AS descuento_aplicado,
    -- Observaciones variadas y aleatorias
    (ARRAY[
        NULL,
        'Cliente habitual', 'cliente habitual', 'Cliente Habitual', 'CLIENTE HABITUAL',
        'Devolución reciente', 'Problema con QR', 'Comprador frecuente',
        'Cliente nuevo', 'Ticket anulado', 'Descuento por volumen'
    ])[FLOOR(RANDOM() * 11 + 1)::INT] AS observaciones
FROM (
    SELECT 
        (ARRAY[
            'CABA', 'La Plata', 'Rosario', 'Córdoba', 'Mendoza', 'Salta', 'Neuquén', 'Bariloche', 'San Luis', 'Santa Fe',
            'Mar del Plata', 'San Juan', 'San Rafael', 'Bahía Blanca', 'Tandil', 'Corrientes', 'Paraná', 'Resistencia',
            'Río Cuarto', 'Formosa', 'Posadas', 'Santiago del Estero', 'Catamarca', 'Jujuy', 'Trelew', 'Comodoro Rivadavia',
            'Puerto Madryn', 'Ushuaia', 'Río Grande', 'Mercedes', 'Villa María', 'Rafaela', 'Pergamino', 'Luján', 'Junín',
            'Avellaneda', 'Lanús', 'Quilmes', 'Morón', 'San Isidro', 'Tigre', 'Escobar', 'Campana', 'Zárate', 'Pilar',
            'General Rodríguez', 'San Fernando', 'Ituzaingó', 'Ezeiza', 'Florencio Varela'
        ])[FLOOR(RANDOM() * 50 + 1)::INT] AS localidad
    FROM generate_series(1, 10000)
) AS datos_base;



--truncate table ticket

--Select * from ticket


