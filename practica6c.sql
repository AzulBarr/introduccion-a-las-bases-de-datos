--Listar todos los nombres de los artistas que comienzan con la letra M y la cantidad de tracks, con mas de 25, ordenado por la cantidad de tracks descendente.
--Hint: Utilizar HAVING
SELECT ar.name, COUNT(*) cantidad_tracks
FROM chinook.artist ar
JOIN chinook.album al
	ON al.artist_id = ar.artist_id
JOIN chinook.track t
	ON al.album_id = t.album_id
WHERE ar.name LIKE 'M%' 
GROUP BY ar.artist_id
HAVING COUNT(*) > 25
ORDER BY cantidad_tracks DESC


--Encontrar otra opción para el ejer 13 que no sea la de utilizar consultas anidadas
--listo
SELECT ar.*
FROM chinook.artist ar
WHERE ar.artist_id NOT IN(
				SELECT DISTINCT al.artist_id FROM chinook.album al
)

--Agregar para cada genero, la lista con todos los tracks de cada genero con su duracion en mili segundos.
SELECT g.name, COUNT(*) cantidad_tracks, STRING_AGG(t.name||' - ' || t.milliseconds||' ms', ', ')
FROM chinook.track t
JOIN chinook.genre g
	ON g.genre_id = t.genre_id
GROUP BY g.name


SELECT json_build_object('nombre', 'Thu', 'duracion', 197);
--genera json array
SELECT json_agg(
	json_build_object('nombre', 'Thu', 'duracion', 197)
)

SELECT g.name, COUNT(*) cantidad_tracks, 
	json_agg(
	json_build_object('track', t.name, 'duracion', t.milliseconds)
) documento
FROM chinook.track t
JOIN chinook.genre g
	ON g.genre_id = t.genre_id
GROUP BY g.name

--CTE: Obtener las playlists mas caras.
WITH precio_playlist AS(
	SELECT pt.playlist_id, SUM(t.unit_price) precio
	FROM chinook.playlist_track pt
	JOIN chinook.track t
		ON t.track_id = pt.track_id
	GROUP BY pt.playlist_id
)
SELECT * 
FROM precio_playlist pp

--Promedio de albumes por playlist
WITH cantidad_albumes_playlist AS(
	SELECT pt.playlist_id, COUNT(DISTINCT t.album_id) cant
	FROM chinook.playlist_track pt
	JOIN chinook.track t
		ON pt.track_id = t.track_id
	GROUP BY pt.playlist_id
)
SELECT SUM(cap.cant)/COUNT(cap.playlist_id) cant_alb_play
FROM cantidad_albumes_playlist cap


WITH cantidad_albumes_playlist AS(
	SELECT pt.playlist_id, COUNT(DISTINCT t.album_id) cant
	FROM chinook.playlist_track pt
	JOIN chinook.track t
		ON pt.track_id = t.track_id
	GROUP BY pt.playlist_id
)
SELECT AVG(cap.cant) cant_alb_play
FROM cantidad_albumes_playlist cap


--Obtener los datos de todos los tracks del álbum 'Led Zeppelin I'
SELECT t.*, a.title
FROM chinook.track t
JOIN chinook.album a
	ON a.album_id = t.album_id
WHERE a.title = 'Led Zeppelin I'

SELECT *
FROM chinook.track t
WHERE t.album_id = (SELECT a.album_id
					FROM album a
					WHERE a.title = 'Led Zeppelin I'
					)

--Obtener los nombres, en mayuscula, de los tracks que se llaman igual que el album al que pertenecen.
SELECT UPPER(t.name)
FROM chinook.track t
WHERE t.name IN (SELECT a.title
				 FROM album a
				 WHERE t.album_id = a.album_id
				)

--Ordenar los generos segun la cantidad de facturas generadas
SELECT g.name, COUNT(DISTINCT il.invoice_id) cant_fact
FROM chinook.genre g
JOIN chinook.track t
	ON t.genre_id = g.genre_id
JOIN chinook.invoice_line il
	ON il.track_id = t.track_id
GROUP BY g.name
ORDER BY cant_fact DESC