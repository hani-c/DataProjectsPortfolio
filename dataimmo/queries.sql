
/* Total number of apartments sold in the 1st semester of 2020 */

SELECT COUNT(type_local) AS "Nombre total d'appartments vendus"
FROM bien
JOIN operation ON bien.id_bien = operation.id_operation
WHERE date_mut BETWEEN '2020-01-01' AND '2020-06-30'
AND type_local = 'Appartement';


/* Proportion of apartments sales by number of rooms */

SELECT DISTINCT nb_pieces AS 'Nombres de pièces'
(COUNT(id_bien) OVER (PARTITION BY nb_pieces)/COUNT(id_bien)OVER()) * 100 AS 'Proportion des ventes en %'
FROM bien
WHERE type_local = 'Appartement';


/* List of 10 departments where the square meter price is the highest */

SELECT code_dept AS 'Département', ROUND(AVG(val_fonc /surf_carrez),2) AS 'Prix moyen du m2'
FROM bien
JOIN commune ON bien.id_commune = commune.id_commune
JOIN operation ON operation.id_operation = bien.id_bien
GROUP BY code_dept
ORDER BY 2 DESC
LIMIT 10;

/* Average square meter price of a house in the Ile de France region */

SELECT ROUND(AVG((operation.val_fonc)/(bien.surf_carrez)),2) AS 'Prix moyen du m2 maison en IDF'
FROM bien
JOIN operation ON operation.id_operation = bien.id_bien
JOIN commune ON bien.id_commune = commune.id_commune
WHERE type_local = 'Maison'
AND code_dept IN (75,92,93,94,77,91,78,95);


/* List of the 10 most expensive apartments with their region and area */

SELECT bien.id_bien, val_fonc AS 'Prix de vente', code_dept AS 'Département', surf_carrez AS 'Nombre de m2'
FROM bien
JOIN operation ON operation.id_operation = bien.id_bien
JOIN commune ON bien.id_commune = commune.id_commune
WHERE type_local = 'Appartement'
ORDER BY val_fonc DESC
LIMIT 10;

/* Rate of change in the number of sales between the first and second quarters of 2020 */

WITH
Ventes1T AS (
  SELECT COUNT(*) AS 'ventes1T'
  FROM operation
  WHERE date_mut BETWEEN '2020-01-01' AND '2020-03-31'),
Ventes2T AS (
  SELECT COUNT(*) AS 'ventes2T'
  FROM operation
  WHERE date_mut BETWEEN '2020-04-01' AND '2020-06-30')

SELECT ROUND(((ventes2T - ventes1T)/ventes1T * 100),2) AS 'Taux d''evolution des ventes en 2020 (en%)'
FROM Ventes1T, Ventes2T;


/* List of towns where the number of sales rose by at least 20% between the first and second quarters of 2020 */

WITH
Ventes1T AS (
  SELECT commune AS 'Commune1T', COUNT(id_operation) AS 'Ventes_1T'
  FROM commune
  JOIN bien ON bien.id_commune = commune.id_commune
  JOIN operation ON operation.id_operation = bien.id_bien
  WHERE date_mut BETWEEN '2020-01-01' AND '2020-03-31'
  GROUP BY commune),
Ventes2T AS (
  SELECT commune AS 'Commune2T', COUNT(id_operation) AS 'Ventes_2T'
  FROM commune
  JOIN bien ON bien.id_commune = commune.id_commune
  JOIN operation ON operation.id_operation = bien.id_bien
  WHERE date_mut BETWEEN '2020-04-01' AND '2020-06-30'
  GROUP BY commune)

SELECT Commune1T AS 'Communes', Ventes_1T AS 'ventes 1er trimestre', Ventes2T AS 'ventes 2ème trimestre',
ROUND(((Ventes_2T - Ventes_1T)/Ventes_1T * 100),2) AS 'Taux évolutions ventes'
FROM Ventes1T
JOIN Ventes2T ON Ventes1T.Commune1T = Ventes2T.Commune2T
WHERE ROUND(((Ventes_2T - Ventes_1T)/Ventes_1T * 100),2) > 20;


/* Percentage difference in price per square meter between a 2-room apartment and a 3-room apartment */

WITH
apt2P AS (
  SELECT ROUND(AVG(val_fonc/surf_carrez),2) AS 'PM2P'
  FROM bien
  JOIN operation ON operation.id_operation = bien.id_bien
  WHERE nb_pieces = '2' AND type_local = 'Appartement'),
apt3P AS (
  SELECT ROUND(AVG(val_fonc/surf_carrez),2) AS 'PM3P'
  FROM bien
  JOIN operation ON operation.id_operation = bien.id_bien
  WHERE nb_pieces = '3' AND type_local = 'Appartement'),

SELECT ROUND(((PM3P - PM2P)/PM2P * 100),2) AS 'Différence prix du m2 entre apt 2P et 3P (en %)'
FROM apt2P, apt3P;


/* Average property values for the top 3 municipalities in the departments 6, 13, 33, 59 and 69 */

WITH
valeur_par_ville AS (
  SELECT code_dept, commune.commune AS 'Commune', AVG(operation.val_fonc) AS 'moyavg'
  FROM commune
  JOIN bien ON bien.id_commune = commune.id_commune
  JOIN operation ON operation.id_operation = bien.id_bien
  GROUP BY code_dept, commune)

SELECT code_dept AS 'Département', Commune, ROUND(moyavg,2) AS 'Moyenne valeur foncière'
FROM (
  SELECT code_dept, Commune, moyavg,
  RANK() OVER (PARTITION BY code_dept ORDER BY moyavg DESC) AS rang
  FROM valeur_par_ville) AS result)
WHERE rang <=3 AND code_dept IN (06,13,33,59,69)
