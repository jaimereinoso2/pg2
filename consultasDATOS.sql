-- --------------------
-- 0
-- ----------------

SELECT  ma.key_estudiante, ma.periodo, ma.asignatura, 
		TIMESTAMPDIFF(YEAR,e.birthdate,p.fecha_inicio) estudiante_edad, 
        e.sex,
        ma.key_docente, d.sex,
        TIMESTAMPDIFF(YEAR,d.birthdate,p.fecha_inicio) docente_edad
FROM f_matriculasAsignaturas ma
INNER JOIN f_estudiantes e
ON e.key_estudiante = ma.key_estudiante
LEFT JOIN f_docentes d 
ON d.key_docente = ma.key_docente
INNER JOIN f_periodos p
ON p.periodo = ma.periodo
WHERE ma.analizar = 1;

SELECT  AVG(
        TIMESTAMPDIFF(YEAR,d.birthdate,p.fecha_inicio)) docente_edad
FROM f_matriculasAsignaturas ma
INNER JOIN f_estudiantes e
ON e.key_estudiante = ma.key_estudiante
LEFT JOIN f_docentes d 
ON d.key_docente = ma.key_docente
INNER JOIN f_periodos p
ON p.periodo = ma.periodo
WHERE ma.analizar = 1;

select distinct cod_colegio, LENGTH(cod_colegio)
from f_estudiantes;

SELECT  ma.key_estudiante, ma.periodo, ma.asignatura, 
		TIMESTAMPDIFF(YEAR,e.birthdate,p.fecha_inicio) estudiante_edad, 
        e.sex estudiante_genero, IFNULL(e.cod_colegio,'Ninguno') colegio,
        IFNULL(ma.key_docente,'Ninguno') key_docente, IFNULL(d.sex,1) docente_genero,
        IFNULL(TIMESTAMPDIFF(YEAR,d.birthdate,p.fecha_inicio),43) docente_edad, 
        ma.estado, CAST(ma.nota AS DECIMAL(10,2)) nota
    FROM f_matriculasAsignaturas ma
    INNER JOIN f_estudiantes e
    ON e.key_estudiante = ma.key_estudiante
    LEFT JOIN f_docentes d 
    ON d.key_docente = ma.key_docente
    INNER JOIN f_periodos p
    ON p.periodo = ma.periodo
    WHERE ma.analizar = 1;
    
    -- ----------------
    -- 2 ICFES
    -- --------------------

select  key_estudiante, CONCAT(test_id,'_',test_component) item, score
from f_icfes
order by test_id, CONCAT(test_id,'_',test_component);


