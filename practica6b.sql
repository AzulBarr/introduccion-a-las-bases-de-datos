SELECT * FROM chinook.invoice i
where i.billing_country = 'Italy'

--devolver el campo name de la tabla artist y en otra columna llamada "length" la longitud del string contenido en el campo name.
SELECT a.name, LENGTH(a.name) AS length
FROM chinook.artist a

--devolver el campo ArtistID y el campo Name de la tabla Artist concatenados en una sola columna llamada fullName
SELECT a.artist_id || a.name AS fullName
FROM chinook.artist a

SELECT CONCAT(a.artist_id, '-', a.name) AS fullName
FROM chinook.artist a

--devolver los 3 primeros caracteres del campo name de la tabla artist en mayusculas
SELECT UPPER(SUBSTRING(a.name, 1,3))
FROM chinook.artist a

--seleccionar el nombre, albumId y el compositor de los tracks y el genero del mismo
SELECT t.album_id, t.name, t.composer, g.name AS genero
FROM chinook.track t
INNER JOIN chinook.genre g
	ON t.genre_id = g.genre_id

--agregar MediaType del track
SELECT t.album_id, t.name, t.composer, g.name AS genero, m.name AS media_type
FROM chinook.track t
INNER JOIN chinook.genre g
	ON t.genre_id = g.genre_id
INNER JOIN chinook.media_type m
	ON t.media_type_id = m.media_type_id

--listar la cantidad de tracks que tiene cada genero y el nombre del genero
SELECT G.name AS genero, COUNT(*) AS cant
FROM chinook.track T
INNER JOIN chinook.genre G
	ON T.genre_id = G.genre_id
GROUP BY(G.name)
ORDER BY cant DESC

--obtener artistas que no tienen albumes
SELECT * FROM chinook.artist
EXCEPT
SELECT DISTINCT Ar.*
FROM chinook.artist Ar
INNER JOIN chinook.album Al
	ON Ar.artist_id = Al.artist_id

SELECT * 
FROM chinook.artist
WHERE artist_id not in (SELECT DISTINCT a.artist_id
						FROM chinook.album a)

--listar todos los artistas y para el caso que corresponda, los álbumes asociados que tengan
SELECT Ar.*, Al.title
FROM chinook.artist Ar
LEFT OUTER JOIN chinook.album Al
	ON Ar.artist_id = Al.artist_id

--listar todos los albumes y para el caso que corresponda, los artistas asociados que tengan
SELECT Al.*, Ar.name
FROM chinook.album Al
JOIN chinook.artist Ar --siempre hay artistas
	ON Ar.artist_id = Al.artist_id