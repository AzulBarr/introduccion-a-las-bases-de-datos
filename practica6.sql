--cuantos dias pasaron desde la compra
SELECT ticket_id, (current_date - fecha_compra) AS "diasPasados"
FROM ticket

--la compra fue por la mañana o la tarde
SELECT *, CASE
				WHEN hora_compra > '12:00:00' THEN 'tarde'
				ELSE 'mañana'
			END AS franja_horaria
FROM ticket

SELECT *, CASE
				WHEN EXTRACT(HOUR FROM hora_compra) > '12' THEN 'tarde'
				ELSE 'mañana'
			END AS franja_horaria
FROM ticket

--cual fue el precio promedio por producto en ese ticket
SELECT *, ROUND(monto_total / NULLIF(productos,0), 2) AS precio_promedio_producto
FROM ticket

--clasificar el ticket según el monto en Alta, Media y Baja
SELECT *, CASE 
				WHEN monto_total > 500000 THEN 'Alta'
				WHEN monto_total > 200000 THEN 'Media'
				ELSE 'Baja'
			END AS tipo_monto
FROM ticket

--limpiar espacios en localidad
SELECT TRIM(localidad)
FROM ticket

SELECT ticket_id, '"' || localidad || '"' AS localidad_original, '"' || TRIM(localidad) || '"' AS localidad_original
FROM ticket

--mostrar las localidades con espacios innecesarios
SELECT ticket_id, '"' || localidad || '"' AS localidad_original, '"' || TRIM(localidad) || '"' AS localidad_trimeada
FROM ticket
WHERE TRIM(localidad) <> localidad

SELECT ticket_id, '"' || localidad || '"' AS localidad_original, 
	'"' || TRIM(localidad) || '"' AS localidad_trimeada,
	LENGTH(localidad) - LENGTH(TRIM(localidad)) AS espacios_trimeados
FROM ticket
WHERE localidad ~ '^|$' --empieza o termina en espacio

--minimo
SELECT MIN(monto_total) FROM ticket

--contar cuantas filas tiene la tabla
SELECT COUNT(ticket_id) 
FROM ticket

SELECT COUNT(*) AS cantidad_observaciones 
FROM ticket

-- contar cuantas observaciones no son null
SELECT COUNT(observaciones) AS cantidad_no_null_obs
FROM ticket

SELECT COUNT(*) AS cantidad_no_null_obs
FROM ticket
WHERE observaciones IS NOT NULL

SELECT table_name
FROM information_schema.tables

