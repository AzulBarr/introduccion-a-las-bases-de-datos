/**
CREACION Y POBLACION DE TABLAS
**/

-- si estab en máquina propia, creen este esquema y establezcan el path de búsqueda, luego creen las dos tablas con los scripts que siguen
CREATE SCHEMA empleado;
SET SEARCH_PATH = empleado;

-- si están en los labos de la FCEN, creen las dos tablas en el esquema public (para esto no hace falta especificar esquema, pero cambienle el nombre agregandole un prefijo o sufijo único para cada uno de ustedes
-- 			(por ej, sus iniciales) y luego en cada SELECT, ajusten los nombres de las tablas al que le dieron ustedes.


DROP TABLE empleado;
DROP TABLE division;

CREATE TABLE division (
    id_division SMALLINT PRIMARY KEY,
    nombre VARCHAR(50) 
);


CREATE TABLE empleado.empleado (
    legajo INTEGER,
    apellido VARCHAR(50),
    nombre VARCHAR(50),
    anio_ingreso SMALLINT, 
    id_division SMALLINT,
  FOREIGN KEY (id_division) REFERENCES division (id_division)
);

--TRUNCATE TABLE division;
--TRUNCATE TABLE empleado;

INSERT INTO empleado.division (id_division, nombre)
SELECT
    generate_series(1, 50) AS id_division,
    'Division '||generate_series(1, 50) AS nombre
    ;

 
INSERT INTO empleado (legajo, apellido, nombre, anio_ingreso, id_division)
SELECT
    generate_series(1, 100000) AS legajo,
    SUBSTR('AAEIOUA', (RANDOM() * 6)::INTEGER+1,1)||'pellido'||generate_series(1, 100000) AS apellido,
    'Nombre'||generate_series(1, 100000) AS nombre,
    (random() * (2023 - 2000 + 1) + 2000)::INTEGER AS anio_ingreso,
    (RANDOM() * 49)::INTEGER+1 id_division ;


SELECT count(*)
from division;

SELECT count(*)
from empleado;

/**
CONSULTAS Y PLANES DE EJECUCION
**/

---------------------
-- RECOPILACION ESTADISTICAS
---------------------

ANALYZE VERBOSE empleado.empleado;

ANALYZE VERBOSE empleado.division;



---------------
-- PASO 1
---------------

EXPLAIN    
 SELECT *
 FROM empleado
; 

/**
 resultado posible...
 
--Seq Scan on empleado (cost=0.00..1824.00 rows=100000 width =32)

¿ les dio esto mmismo? Veamos que hace y como se interpreta

¿qué está haciendo?? recorre toda la tabla

-- Cómo interpretamos este plan de ejecucion?
-- costo - primer número: costo estimado para iniciar la fase de output
-- costo - segundo número: costo estimado para completar la fase de output, asumiendo que se ejecuta hasta el final
-- rows: cantidad de filas estimadas del output
-- width: ancho estimado de cada fila del output (en bytes)
-- el costo está medido en unidades arbitrarias definidas por el planificador de consultas. 
-- por default, las  variables de costo están basadas en el costo de lecturas de las páginas de disco.
-- Por convención, el valor de realizar el fetch de una (1) página de datos se considera "1". El resto de las variables de costo se establecen en referencia a ese costo 
-- las estimaciones reflejan los costos propios de componentes del motor de base de datos que pueden variar con los diferentes planes de ejecución.
-- y no cuestiones externas o cuestiones que no dependen del plan elegido (como ser el tiempo en transmitir el resultado al cliente)

**/

---------------
-- PASO 2
---------------
--Ejecutar ANALYZE... y volver a ver el plan de ejecucion

ANALYZE;

EXPLAIN    
 SELECT *
 FROM empleado
; 

-- ¿Les dio igual que antes? ¿Qué es lo que pasó?

--Seq Scan on empleado (cost=0.00..1824.00 rows=100000 width =32)

-- igual, atencion con el ANALYZE, ya que genera estadisticas a partir de un muestreo aleatorio de la tabla, cuando es grande


EXPLAIN ANALYZE
 SELECT *
 FROM empleado
; 

---------------
-- PASO 3
---------------
-- De donde saca los valores para las estimaciones?
-- De estadisticas y metadata...

SELECT relpages, reltuples FROM pg_class WHERE relname = 'empleado';

/**
relpages
824

reltuples
100000

-- calculo:
-- (disk pages read * seq_page_cost) + (rows scanned * cpu_tuple_cost)
-- POr default, seq_page_cost vale 1.0 y  cpu_tuple_cost vale 0.01

SELECT   (824 * 1.0) + (100000 * 0.01) ;
-- 1824.00

**/

---------------
-- PASO 4
---------------

EXPLAIN    
 SELECT *
 FROM empleado
 WHERE legajo<10
 ; 

-- Seq Scan on empleado  (cost=0.00..2074.00 rows=10 width=32)
--   Filter: (legajo < 10)
 
-- en el plan se agregó "Filter", asociado al WHERE
-- devuelve muchas menos filas, pero el costo es algo mayor...
-- ¿qué paso?
-- Tiene que recorrer igual la tabla completa...
-- Y adicionalmente, tiene que realizar una operación de evaluación del filtro, lo cual tiene un costo asociado...
-- calculo:
-- (disk pages read * seq_page_cost) + (rows scanned * cpu_tuple_cost) + (rows scanned * cpu_operator_cost)
-- Por default, seq_page_cost vale 1.0, cpu_tuple_cost vale 0.01 y cpu_operator_cost vale 0.0025

-- en casos siguientes no vamos a ver este detalle, las fórmulas se hacen más complejas...
-- nos concentraremos en ver los costos e interpretar qué es lo que hace y por qué...

SELECT   (824 * 1.0) + (100000 * 0.01) + (100000 * 0.0025) ;


---------------
-- PASO 5
---------------
-- ¿podemos mejorar el costo?
--¿que pasa si creamos un indice por  legajo?
 CREATE INDEX empleado_leg_idx ON empleado(legajo);
 
 EXPLAIN    
 SELECT *
 FROM empleado
 WHERE legajo<10
 ; 
 -- aqui vemos que usa el indice, tiene mucho menor costo
 -- Index Scan using empleado_leg_idx on empleado  (cost=0.29..8.47 rows=10 width=32)
 --   Index Cond: (legajo < 10)
 
 ---------------
-- PASO 6 a
---------------
-- veamos esta otra consulta
-- ¿que piensan que va a hacer?
 SELECT *
 FROM empleado
 WHERE legajo>10
 ; 

---------------
-- PASO 6 b
---------------
-- veamos...
EXPLAIN    
 SELECT *
 FROM empleado
 WHERE legajo>10
 ; 
--aquí no usa el indice.... ¿por que ?
 -- Seq Scan on empleado  (cost=0.00..2074.00 rows=99989 width=32)
 --   Filter: (legajo > 10)
 -- 
 
 ---------------
-- PASO 7
---------------

-- buscamos ahora por el campo string... no tiene indice

 EXPLAIN  
 SELECT *
 FROM empleado
 WHERE apellido = 'Apellido11';
 
-- Seq Scan on empleado  (cost=0.00..2074.00 rows=1 width=32)
--   Filter: ((apellido)::text = 'Apellido11'::text)

---------------
-- PASO 8
---------------

EXPLAIN  
 SELECT *
 FROM empleado
 WHERE apellido LIKE 'Apellido%';
 
-- Seq Scan on empleado  (cost=0.00..2074.00 rows=33333 width=32)
--   Filter: ((apellido)::text ~~ 'Apellido%'::text)

---------------
-- PASO 9
---------------

-- crearemos un índice por apellido y veremos qué pasa

CREATE INDEX empleado_ape_idx ON empleado(apellido);

 EXPLAIN  
 SELECT *
 FROM empleado
 WHERE apellido = 'Apellido11';
 
  -- ¿qué es lo que hace ahora? ¿mejora el costo?
 
 -- Index Scan using empleado_ape_idx on empleado  (cost=0.42..8.44 rows=1 width=32)
 --   Index Cond: ((apellido)::text = 'Apellido11'::text)
 
---------------
-- PASO 9
---------------
-- y que pasa aquí?

 EXPLAIN  
 SELECT *
 FROM empleado
 WHERE apellido LIKE 'Apellido%';
 
  -- Seq Scan on empleado  (cost=0.00..2074.00 rows=33333 width=32)
 --   Filter: ((apellido)::text ~~ 'Apellido%'::text)
 
 -- cuál es la explicacion?
 
---------------
-- PASO 10 a
---------------
 -- y aqui... que pensamos que va a hacer? que es lo que hace?
 SELECT *
 FROM empleado
 WHERE apellido IN ('Apellido11', 'Epellido23', 'Upellido41');


---------------
-- PASO 10 b
---------------
-- veamos qué pasa
 EXPLAIN  
 SELECT *
 FROM empleado
 WHERE apellido IN ('Apellido11', 'Epellido23', 'Upellido41');


--un plan posible...
-- Index Scan using empleado_ape_idx on empleado  (cost=0.42..25.01 rows=3 width=32)
 --   Index Cond: ((apellido)::text = ANY ('{Apellido11,Epellido23,Upellido41}'::text[]))
 -- otro...
 -- Bitmap Heap Scan on empleado  (cost=13.28..24.77 rows=3 width=32)
 --   Recheck Cond: ((apellido)::text = ANY ('{Apellido11,Epellido23,Upellido41}'::text[]))
 --   ->  Bitmap Index Scan on empleado_ape_idx  (cost=0.00..13.28 rows=3 width=0)
 --         Index Cond: ((apellido)::text = ANY ('{Apellido11,Epellido23,Upellido41}'::text[]))

---------------
-- PASO 11 a
---------------
 -- y aqui... que pensamos que va a hacer? que es lo que hace?
 SELECT *
 FROM empleado
 WHERE UPPER(apellido) = 'APELLIDO11';

---------------
-- PASO 11 b
---------------

EXPLAIN  
 SELECT *
 FROM empleado
 WHERE UPPER(apellido) = 'APELLIDO11';
 -- Seq Scan on empleado  (cost=0.00..2324.00 rows=500 width=32)
 --   Filter: (upper((apellido)::text) = 'APELLIDO11'::text)
 
 -- ¿por que no uso el indice?
 -- Las condiciones tienen que matchear con las expresiones de los índices para que los use
 ---------------
-- PASO 12
---------------

EXPLAIN  
 SELECT *
 FROM empleado
 WHERE apellido BETWEEN  'Apellido1' AND 'Apellido3';
 
 -- Bitmap Heap Scan on empleado  (cost=199.13..1138.31 rows=7679 width=32)
 --   Recheck Cond: (((apellido)::text >= 'Apellido1'::text) AND ((apellido)::text <= 'Apellido3'::text))
 --   ->  Bitmap Index Scan on empleado_ape_idx  (cost=0.00..197.21 rows=7679 width=0)
 --         Index Cond: (((apellido)::text >= 'Apellido1'::text) AND ((apellido)::text <= 'Apellido3'::text))
 
-- ¿qué hace acá?

 ---------------
-- PASO 13
---------------
-- como estima la selectividad de una condicion?
-- se basa en las estadisticas

-- por ej, para rangos o desigualdades, principalmente usa histogramas
SELECT histogram_bounds FROM pg_stats
WHERE tablename='empleado' AND attname='apellido';

-- por ej, para consultas por "=" usa most common values (MCVs) 
SELECT null_frac, n_distinct, most_common_vals, most_common_freqs FROM pg_stats
WHERE tablename='empleado' AND attname='anio_ingreso';
 --si el valor buscado es MCV, tiene la frecuencia directamente
 -- si no es MCV, se estima a partir de las frecuencias de todos los MCVs (su complemento a 1) y la cantidad de diferentes valores distintos no MCV
-- para consultas por desigualdades, se complementan los histogramas con mcvs (histogramas no incluyen a los mcvs)



---------------
-- PASO 14 a
---------------
-- y aca que piensan que va a pasar?

 SELECT *
 FROM empleado
 WHERE legajo <10 and anio_ingreso=2017
 ;

---------------
-- PASO 14 b
---------------
-- veamos que pasa
EXPLAIN  
 SELECT *
 FROM empleado
 WHERE legajo <10 and anio_ingreso=2017
 ;
 -- que es lo que hace acá?
 -- Index Scan using empleado_leg_idx on empleado  (cost=0.29..8.47 rows=1 width=32)
 --   Index Cond: (legajo < 10)
 --   Filter: (anio_ingreso = 2017)
 -- si hay condiciones por campos diferentes, el calculo de selectividad se realiza asumiendo independencia de variables
 -- atencion... para la selectividad en el escaneo de un indice solo se consideran los campos de filtro que pertenecen al indice
 
 ---------------
-- PASO 14 a
---------------
-- y aca que piensan que va a pasar?
 SELECT *
 FROM empleado
 WHERE legajo <10 OR anio_ingreso=2017
 ;

---------------
-- PASO 14 b
---------------
-- veamos
EXPLAIN  
 SELECT *
 FROM empleado
 WHERE legajo <10 OR anio_ingreso=2017
 ;
 
 
 -- Seq Scan on empleado  (cost=0.00..2324.00 rows=4252 width=32)
 --   Filter: ((legajo < 10) OR (anio_ingreso = 2017))
 
 -- al cambiar la condición por OR, que vemos? por qué pasa esto?


---------------
-- PASO 15
---------------
-- y si agregamos un indice por anio_ingreso?
 CREATE INDEX emp_anio_ingreso_idx on empleado (anio_ingreso);
 
  EXPLAIN  
 SELECT *
 FROM empleado
 WHERE legajo <10 OR anio_ingreso=2017
 
 -- que está haciendo acá?
 -- Bitmap Heap Scan on empleado  (cost=54.60..942.38 rows=4252 width=32)
 --   Recheck Cond: ((legajo < 10) OR (anio_ingreso = 2017))
 --   ->  BitmapOr  (cost=54.60..54.60 rows=4252 width=0)
 --         ->  Bitmap Index Scan on empleado_leg_idx  (cost=0.00..4.36 rows=9 width=0)
 --               Index Cond: (legajo < 10)
 --         ->  Bitmap Index Scan on emp_anio_ingreso_idx  (cost=0.00..48.11 rows=4243 width=0)
 --               Index Cond: (anio_ingreso = 2017)
 
---------------
-- PASO 16
---------------
-- ¿entonces siemopre vamos a crear indices por todos los campos?
-- los indices ayudan, pero ojo que no es gratis... ocupan lugar, a veces mucho...
 
 SELECT c.relname, c.relkind,  ns.nspname, c.relpages, c.reltuples,
 			pg_size_pretty(pg_total_relation_size(c.oid)- pg_indexes_size(c.oid)) AS tamaño
FROM pg_class c
	LEFT JOIN pg_namespace ns
    	on ns.oid=c.relnamespace
WHERE ns.nspname='empleado';    

-- a tener en cuenta en la consulta anterior
-- la funcion pg_total_relation_size devuelve el tamaño total de una tabla incluyendo tambien el tamaño de sus indices... 
-- por eso se le restó el tamaño de los indices, para quedarnos con el tamaño neto de la tabla


---------------
-- PASO 17
---------------
 
-- qué pasa si incluimos una junta?
EXPLAIN
SELECT e.*, d.nombre
 FROM empleado e
 	join division d
    	on d.id_division=e.id_division
;

-- Hash Join  (cost=2.12..2110.88 rows=100000 width=43)
--   Hash Cond: (e.id_division = d.id_division)
--   ->  Seq Scan on empleado e  (cost=0.00..1824.00 rows=100000 width=32) 
--   ->  Hash  (cost=1.50..1.50 rows=50 width=13)
--         ->  Seq Scan on division d  (cost=0.00..1.50 rows=50 width=13)

--acá para acceder a los datos de división generó una tabla hash ad-hoc a partir de hacerle un scan a la tabla
-- no usó el índice b+ que estaba creado para la PK de la tabla division

---------------
-- PASO 18
---------------
-- ¿que pasa si intercambiamos la tabla externa e interna en la clausula join?
EXPLAIN
SELECT e.*, d.nombre
 FROM division d
 	 join empleado e
    	on d.id_division=e.id_division
;

-- Hash Join  (cost=2.12..2110.88 rows=100000 width=43)
--   Hash Cond: (e.id_division = d.id_division)
--   ->  Seq Scan on empleado e  (cost=0.00..1824.00 rows=100000 width=32) 
--   ->  Hash  (cost=1.50..1.50 rows=50 width=13)
--         ->  Seq Scan on division d  (cost=0.00..1.50 rows=50 width=13)

--no cambió nada, el optimizador realiza permutaciones para encontrar el plan optimizado

---------------
-- PASO 19
---------------
-- que pasa con una subconsulta en el select?

EXPLAIN  
SELECT e.*, (SELECT nombre FROM division d WHERE d.id_division=e.id_division) nombre_div
FROM empleado e 

-- Seq Scan on empleado e  (cost=0.00..164324.00 rows=100000 width=150)
--   SubPlan 1
--     ->  Seq Scan on division d  (cost=0.00..1.62 rows=1 width=11)
--           Filter: (id_division = e.id_division)
-- JIT: 
--   Functions: 8
--   Options: Inlining false, Optimization false, Expressions true, Deforming true

-- JIT (Just-In-Time compilation): postgresql realiza una compilacion al vuelo del codigo para optimizar la ejecucion

EXPLAIN ANALYZE
SELECT e.*, (SELECT nombre FROM division d WHERE d.id_division=e.id_division) nombre_div
FROM empleado e 


-- Seq Scan on empleado e  (cost=0.00..164324.00 rows=100000 width=150) (actual time=0.029..594.404 rows=100000 loops=1)"
--  SubPlan 1"
--     ->  Seq Scan on division d  (cost=0.00..1.63 rows=1 width=11) (actual time=0.002..0.003 rows=1 loops=100000)"
--           Filter: (id_division = e.id_division)"
--           Rows Removed by Filter: 49"
-- Planning Time: 0.105 ms"
-- Execution Time: 597.282 ms"

--AHI SE VEN LAS 100 mil ejecucions de la subconsulta!!

---------------
-- PASO 20
---------------
-- y si en ves de subconsulta hacemos un join? que es lo que vemos? 
EXPLAIN 
SELECT e.*, d.nombre nombre_div
 FROM empleado e
 	join division d
    	on d.id_division=e.id_division
		
-- Hash Join  (cost=2.12..2110.88 rows=100000 width=43) 
--   Hash Cond: (e.id_division = d.id_division)
--   ->  Seq Scan on empleado e  (cost=0.00..1824.00 rows=100000 width=32)
--   ->  Hash  (cost=1.50..1.50 rows=50 width=13)
--         ->  Seq Scan on division d  (cost=0.00..1.50 rows=50 width=13)


---------------
-- PASO 21
---------------
 
EXPLAIN
SELECT max(anio_ingreso) max_anio 
 FROM empleado e;

-- Aggregate  (cost=2074.00..2074.01 rows=1 width=2)"
--   ->  Seq Scan on empleado e  (cost=0.00..1824.00 rows=100000 width=2)"

-- aqui realiza un escaneo de la tabla y realiza la agregacion. en este caso lo haría "al vuelo", 
-- pero la operación de buscar el máximo le aplica un extra-costo

---------------
-- PASO 22
---------------
 
EXPLAIN
SELECT max(anio_ingreso) max_anio , min(anio_ingreso) min_anio 
 FROM empleado e;

-- Aggregate  (cost=2324.00..2324.01 rows=1 width=4)"
--   ->  Seq Scan on empleado e  (cost=0.00..1824.00 rows=100000 width=2)"

-- aqui es similar a la anterior, aprovecha el mismo escaneo para ambos cálculos
-- pero la operación de buscar el máximo al ejecutarse dos veces le aplica un extra-costo mayor

---------------
-- PASO 21
---------------
 
EXPLAIN
SELECT e.id_division,  max(anio_ingreso) max_anio 
 FROM empleado e 
 GROUP BY e.id_division;
 
-- HashAggregate  (cost=2324.00..2324.50 rows=50 width=4)"
--   Group Key: id_division"
--   ->  Seq Scan on empleado e  (cost=0.00..1824.00 rows=100000 width=4)"

-- aqui realiza un escaneo de la tabla y realiza la agregacion. pero en este caso usa un HashAggregate
-- porque esta segmentando, y para la segmentación se vale de un hash que calcula en memoria
-- esta operación genera un extra-costo mayor que la agregacion simple 

EXPLAIN
SELECT d.nombre nombre_div,  max(anio_ingreso) max_anio 
 FROM empleado e 
 	JOIN division d
		ON  d.id_division=e.id_division
 GROUP BY d.nombre;


-- HashAggregate  (cost=2610.88..2611.38 rows=50 width=13)"
--   Group Key: d.nombre"
--   ->  Hash Join  (cost=2.13..2110.88 rows=100000 width=13)"
--         Hash Cond: (e.id_division = d.id_division)"
--         ->  Seq Scan on empleado e  (cost=0.00..1824.00 rows=100000 width=4)"
--         ->  Hash  (cost=1.50..1.50 rows=50 width=13)"
--               ->  Seq Scan on division d  (cost=0.00..1.50 rows=50 width=13)"

-- aqui la penalización es similar a lo anterior, solo qeu se parte de una base de mayor costo
-- fijarse que el plan comprendido por el "Hash Join" es el mismo que se veía cuando hacíamos el join sin agregar


---------------
-- PASO 23
---------------
-- y si llevamos la subconsulta inicial al from?  
EXPLAIN ANALYZE
SELECT e.*
 FROM empleado e
 WHERE e.anio_ingreso = (select max(anio_ingreso)  from empleado z)  
 
 
-- Seq Scan on empleado e  (cost=2074.01..4148.01 rows=4000 width=32)"
--   Filter: (anio_ingreso = $0)"
--   InitPlan 1 (returns $0)"
--     ->  Aggregate  (cost=2074.00..2074.01 rows=1 width=2)"
--           ->  Seq Scan on empleado z  (cost=0.00..1824.00 rows=100000 width=2)"

-- aqui se ve que resuelve la subconsulta igual que antes
-- y luego usa ese resultado para filtrar empleado (y ahi lo resuelve similar a los filtros simples de antes)
-- notar que el costo inicial para empezar a generar datos es igaul al costo total de la subconsulta
-- ya que tiene que esperar a la finalizacion de la subconsulta para poder resolver


---------------
-- PASO 23
---------------

EXPLAIN 
SELECT e.* 
 FROM empleado e
 WHERE e.anio_ingreso > (select AVG(anio_ingreso)  from empleado z WHERE z.id_division=e.id_division)  
 
 
-- Seq Scan on empleado e  (cost=0.00..207903574.00 rows=33333 width=32)"
--   Filter: ((anio_ingreso)::numeric > (SubPlan 1))"
--   SubPlan 1"
--     ->  Aggregate  (cost=2079.00..2079.01 rows=1 width=32)"
--           ->  Seq Scan on empleado z  (cost=0.00..2074.00 rows=2000 width=2)"
--                 Filter: (id_division = e.id_division)"

-- MIRAR EL COSTO FINAL!!!!!!
-- esta subconsulta es muy pesada para ejecutarse una vez por cada registro de empleado (intenten ejecutarla, sin el explain...)

---------------
-- PASO 23
---------------

-- alternativa usando funciones de ventana

EXPLAIN 
WITH DATOS AS(
SELECT e.*, avg(anio_ingreso) OVER (PARTITION BY e.id_division) prom_anio_ing_division
 FROM empleado e
)
SELECT legajo, apellido, nombre, anio_ingreso, id_division 
FROM DATOS
WHERE anio_ingreso > prom_anio_ing_division
  
-- Hash Join  (cost=2325.75..4423.01 rows=33333 width=32)"
--   Hash Cond: (e.id_division = e_1.id_division)"
--   Join Filter: ((e.anio_ingreso)::numeric > (avg(e_1.anio_ingreso)))"
--   ->  Seq Scan on empleado e  (cost=0.00..1824.00 rows=100000 width=32)"
--   ->  Hash  (cost=2325.13..2325.13 rows=50 width=34)"
--         ->  HashAggregate  (cost=2324.00..2324.63 rows=50 width=34)"
--               Group Key: e_1.id_division"
--               ->  Seq Scan on empleado e_1  (cost=0.00..1824.00 rows=100000 width=4)"

-- EL COSTO ES  MENOR en este caso!!! 
-- aqui se ve que primero realiza el group by, luego lo resuelve como uno de los joins vistos antes





