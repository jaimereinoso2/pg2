-- --------------------
-- 0
-- ----------------

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
    WHERE ma.analizar = 1;                    -- solo para filas marcadas como analizar

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

-- --------
-- 3. nivel nota promedio obtenido en semestres anteriores
-- -------
    SELECT  ma.key_estudiante, ma.periodo, ma.asignatura
    , p.ordenRE - p2.ordenRE hace, AVG(ma2.nivel_nota) promedio
    FROM f_matriculasAsignaturas ma						-- tabla base
    INNER JOIN f_periodos p								--  periodo de ma
    ON p.periodo = ma.periodo
    INNER JOIN  f_matriculasAsignaturas ma2				-- las asignaturas que vio antes
    ON  ma2.key_estudiante = ma.key_estudiante
    INNER JOIN f_periodos p2							-- periodo de las asignaturas que vio antes
    ON p2.periodo = ma2.periodo
    WHERE ma.analizar = 1								-- se toman en cuenta solo analizar = 1
    AND p2.tipo = 'RE'									-- solo se miran asig anteriores vistas en períodos regulares
    AND p2.ordenRE < p.ordenRE                          -- solo miramos en el orden correcto
    GROUP BY ma.key_estudiante, ma.periodo, ma.asignatura
    , p.ordenRE - p2.ordenRE
    ;

-- -------------------
-- 4. nivel nota asig anteriores por dpto
-- ------------------- 
SELECT ma.key_estudiante, ma.periodo, ma.asignatura, 
           ma2.departamento, AVG(ma2.nivel_nota) promedio
    FROM f_matriculasAsignaturas ma						-- tabla base
    INNER JOIN f_periodos p								--  periodo de ma
    ON p.periodo = ma.periodo
    INNER JOIN  f_matriculasAsignaturas ma2				-- las asignaturas que vio antes
    ON  ma2.key_estudiante = ma.key_estudiante
    INNER JOIN f_periodos p2							-- periodo de las asignaturas que vio antes
    ON p2.periodo = ma2.periodo
    WHERE ma.analizar = 1								-- se toman en cuenta solo analizar = 1
    AND p2.tipo = 'RE'									-- solo se miran asig anteriores vistas en períodos regulares
    AND p2.ordenRE < p.ordenRE                          -- solo miramos en el orden correcto
    GROUP BY ma.key_estudiante, ma.periodo, ma.asignatura, ma2.departamento;
    
-- -----------------
--  7.  cantidad de cursos que ya había tomado. antes 
-- ----------------

SELECT ma.key_estudiante, ma.periodo, ma.asignatura, count(*)
FROM f_matriculasAsignaturas ma						-- asignaturas a tomar en cuenta
INNER JOIN f_periodos p								--  periodo de ma
ON p.periodo = ma.periodo
INNER JOIN  f_matriculasAsignaturas ma2				-- las asignaturas que vio antes
ON  ma2.key_estudiante = ma.key_estudiante
INNER JOIN f_periodos p2							-- periodo de las asignaturas que vio antes
ON p2.periodo = ma2.periodo
WHERE ma.analizar = 1								-- se toman en cuenta solo analizar = 1
AND p2.orden < p.orden     						-- solo se miran periodos anteriores
GROUP BY ma.key_estudiante, ma.periodo, ma.asignatura;

--  ---------------
--  8. cantidad de semestres regulares que lleva el estudiante en la u
-- ----------------
SELECT key_estudiante, periodo, asignatura, count(*) cuantos
FROM (
    SELECT DISTINCT ma.key_estudiante, ma.periodo, ma.asignatura, ma2.periodo periodo_ant
    FROM f_matriculasAsignaturas ma						-- asignaturas a tomar en cuenta
    INNER JOIN f_periodos p								--  periodo de ma
    ON p.periodo = ma.periodo
    INNER JOIN  f_matriculasAsignaturas ma2				-- las asignaturas que vio antes
    ON  ma2.key_estudiante = ma.key_estudiante
    INNER JOIN f_periodos p2							-- periodo de las asignaturas que vio antes
    ON p2.periodo = ma2.periodo
    WHERE ma.analizar = 1								-- se toman en cuenta solo analizar = 1
    AND p2.orden < p.orden     						-- solo se miran periodos anteriores
) V
GROUP BY key_estudiante, periodo, asignatura;

-- -------------------
-- 9 cadntidad de cursos tomados en periodos tipo CV
-- --------------------alter

SELECT ma.key_estudiante, ma.periodo, ma.asignatura, count(*)
FROM f_matriculasAsignaturas ma
INNER JOIN f_periodos p
ON p.periodo = ma.periodo
INNER JOIN f_matriculasAsignaturas ma2
ON ma2.key_estudiante = ma.key_estudiante
INNER JOIN  f_periodos p2
ON p2.periodo = ma2.periodo
WHERE ma.analizar = 1						-- tomamos en cuenta solo las asignaturas de interés
AND p2.tipo ='CV'							-- los periodos anteriores solo se toman en cuenta los tipo CV
AND p2.orden < p.orden						-- solo tomamos en cuenta periodos anteriores al periodo de la asig
GROUP BY ma.key_estudiante, ma.periodo, ma.asignatura;

select p.orden, ma.periodo, ma.asignatura
from f_matriculasAsignaturas ma
inner join f_periodos  p
on p.periodo = ma.periodo
where key_estudiante = 'FAE7093A343E535E85B8FD594D52D976E55D9FAD'
order by p.orden desc;

-- --------------
-- 11
-- --------------
SELECT ma.key_estudiante, ma.periodo, ma.asignatura,  p.ordenRE ,p2.ordenRE , m.promedio_semestre, COUNT(*)
FROM f_matriculasAsignaturas ma
INNER JOIN f_periodos p
ON p.periodo = ma.periodo
INNER JOIN f_matriculas m
ON m.key_estudiante = ma.key_estudiante
INNER JOIN  f_periodos p2
ON p2.periodo = m.periodo
WHERE ma.analizar = 1						-- tomamos en cuenta solo las asignaturas de interés
AND p2.tipo ='RE'							-- los periodos anteriores solo se toman en cuenta los tipo RE
AND p2.orden < p.orden						-- solo tomamos en cuenta periodos anteriores al periodo de la asig
GROUP BY ma.key_estudiante, ma.periodo, ma.asignatura,  p.ordenRE ,p2.ordenRE, m.promedio_semestre
-- HAVING count(*) > 1
;

select *
from f_matriculas m
inner join f_periodos p 
on p.periodo = m.periodo
where key_estudiante = '306023AB9393647A8E4AD19E67EC6AB620240D78'
and p.tipo = 'RE'
order by ordenRE desc;

select estado, nota, count(*)
from f_matriculasAsignaturas
group by estado, nota
order by estado, nota;

select count(*)
from f_matriculasAsignaturas
where analizar = 1;
-- 6989



    SELECT  nota, length(nota)
    FROM f_matriculasAsignaturas ma
    INNER JOIN f_estudiantes e
    ON e.key_estudiante = ma.key_estudiante
    LEFT JOIN f_docentes d 
    ON d.key_docente = ma.key_docente
    INNER JOIN f_periodos p
    ON p.periodo = ma.periodo
    WHERE ma.analizar = 1;
    
    
    select asignatura, periodo, estado, nota,count(*)
    from f_matriculasAsignaturas
    where analizar = 1
    and nota is null
    group by asignatura, periodo, estado, nota
    order by asignatura, periodo, estado, nota;
    
    select periodo, asignatura, count(*)
    from f_matriculasAsignaturas
    where analizar = 1
    group by periodo, asignatura
    order by periodo, asignatura;
    
        SELECT ma.key_estudiante, ma.periodo, ma.asignatura, 
           ma2.departamento, AVG(ma2.nivel_nota) promedio
    FROM f_matriculasAsignaturas ma						-- tabla base
    INNER JOIN f_periodos p								--  periodo de ma
    ON p.periodo = ma.periodo
    INNER JOIN  f_matriculasAsignaturas ma2				-- las asignaturas que vio antes
    ON  ma2.key_estudiante = ma.key_estudiante
    INNER JOIN f_periodos p2							-- periodo de las asignaturas que vio antes
    ON p2.periodo = ma2.periodo
    WHERE ma.analizar = 1								-- se toman en cuenta solo analizar = 1
    AND p2.orden < p.orden                          -- solo miramos en el orden correcto
    GROUP BY ma.key_estudiante, ma.periodo, ma.asignatura, ma2.departamento;
    
    SELECT  ma.key_estudiante, ma.periodo, ma.asignatura,  p.orden - p2.orden hace, m.promedio_semestre
    FROM f_matriculasAsignaturas ma
    INNER JOIN f_periodos p
    ON p.periodo = ma.periodo
    INNER JOIN f_matriculas m
    ON m.key_estudiante = ma.key_estudiante
    INNER JOIN  f_periodos p2
    ON p2.periodo = m.periodo
    WHERE ma.analizar = 1						-- tomamos en cuenta solo las asignaturas de interés
    AND p2.orden < p.orden;
    
    
    select ma.key_estudiante, ma.periodo, ma.asignatura, p.periodo, p.ordenRE
    from f_matriculasAsignaturas ma
    INNER JOIN f_periodos p
    ON p.periodo = ma.periodo
    where ma.key_estudiante = '3749281AB483EED16A7397E22DCB3C0F8E94EBE9'
    and ma.periodo = '20231CV'
    and ma.asignatura = '300MAG006';
    
    select * 
    from f_periodos
    order by ordenRE;
    
-- ------
-- 13. tamaño grupo actual
-- ------
drop table temp;
create table temp as
SELECT ma.key_estudiante, ma.periodo, ma.asignatura, ma.grupo, COUNT(*) cuantos
FROM f_matriculasAsignaturas ma
INNER JOIN f_matriculasAsignaturas ma2
ON ma2.periodo = ma.periodo
AND ma2.asignatura = ma.asignatura
AND ma2.grupo = ma.grupo
GROUP BY ma.key_estudiante, ma.periodo, ma.asignatura, ma.grupo
ORDER BY ma.key_estudiante, ma.periodo, ma.asignatura, ma.grupo;

select key_estudiante, periodo, asignatura, count(*)
from temp
group by key_estudiante, periodo, asignatura
having count(*) > 1;
-- efectivamente no hay repetidos por key_estudiante, periodo, asignatura.  PERFECTO.


-- --------------
-- 15 composición por edades del curso actual
-- --------------

    SELECT ma.key_estudiante, ma.periodo, ma.asignatura, ma.grupo, TIMESTAMPDIFF(YEAR, e.birthdate, p.fecha_inicio)  edad, count(*)
    FROM f_matriculasAsignaturas ma
    INNER JOIN f_matriculasAsignaturas ma2
    ON ma2.periodo = ma.periodo
    AND ma2.asignatura = ma.asignatura
    AND ma2.grupo = ma.grupo
    INNER JOIN f_estudiantes e
    ON e.key_estudiante = ma.key_estudiante
    INNER JOIN f_periodos p
    ON p.periodo = ma.periodo
    GROUP BY ma.key_estudiante, ma.periodo, ma.asignatura, ma.grupo, TIMESTAMPDIFF(YEAR, e.birthdate, p.fecha_inicio)
    ORDER BY ma.key_estudiante, ma.periodo, ma.asignatura, ma.grupo;
    
-- --------------
-- 17 carga
-- --------------

    SELECT ma.key_estudiante, ma.periodo, ma.asignatura, ma.grupo, count(*) cuantos
    FROM f_matriculasAsignaturas ma
    INNER JOIN f_matriculasAsignaturas ma2
	ON ma2.key_estudiante = ma.key_estudiante
    AND ma2.periodo = ma.periodo
    WHERE ma.analizar = 1
    GROUP BY ma.key_estudiante, ma.periodo, ma.asignatura, ma.grupo
    ORDER BY ma.key_estudiante, ma.periodo, ma.asignatura, ma.grupo;
    
    select *
    from f_matriculasAsignaturas
    where key_estudiante = '002F74930C7956A25CCEEECF8CEF84C6FC41C66C'
    and periodo = '20181';
    
    -- -------------
    --  19 cuatnas veces ya habñía visto esa asi
    -- --------------
    
	SELECT ma.key_estudiante, ma.periodo, ma.asignatura, count(*) cuantos
    FROM f_matriculasAsignaturas ma
    INNER JOIN f_periodos p
    ON p.periodo = ma.periodo
    INNER JOIN f_matriculasAsignaturas ma2
	ON ma2.key_estudiante = ma.key_estudiante
    AND ma2.asignatura = ma.asignatura
    INNER JOIN f_periodos p2
    ON p2.periodo = ma2.periodo
    WHERE ma.analizar = 1
    AND p2.orden < p.orden 
    GROUP BY ma.key_estudiante, ma.periodo, ma.asignatura
    ORDER BY ma.key_estudiante, ma.periodo, ma.asignatura;
    
    -- un estudiante la había visto 8 veces!!
    select *
    from f_matriculasAsignaturas
    where key_estudiante = '1917B5D7ADFF357668C8A6F0A8EAF0638DF6B1E7'
    and analizar = 1
    order by periodo, asignatura;
    
    select periodo, nivel_nota, asignatura
    from f_matriculasAsignaturas
    where key_estudiante = '00724CD562AF1C6FF4ED73991F1DA0BB174A0727'
    order by periodo desc, nivel_nota;
    
    -- ----------------
    -- 23 experiencia docente este curso
    -- -----------------



SELECT  ma.key_estudiante, ma.periodo, ma.asignatura, da.id_docente, COUNT(*) cuantas
FROM f_matriculasAsignaturas ma
INNER JOIN f_periodos p
ON p.periodo = ma.periodo
INNER JOIN f_docentesAsignaturas da
ON da.key_docente = ma.key_docente		-- el mismo docente
AND da.asignatura = ma.asignatura		-- la misma asignatura
WHERE ma.analizar = 1
AND da.orden < p.orden					-- el docente la dictó en periodos anteriores
GROUP BY ma.key_estudiante, ma.periodo, ma.asignatura, da.id_docente;

-- -----------------
--  25 cursos tomados con ese mismos docente antes
-- ----------------
SELECT  ma.key_estudiante, ma.periodo, ma.asignatura, COUNT(*) cuantas
FROM f_matriculasAsignaturas ma
INNER JOIN f_periodos p
ON p.periodo = ma.periodo
INNER JOIN  f_matriculasAsignaturas ma2
ON ma2.key_estudiante = ma.key_estudiante			-- el mismo estudiante
AND ma2.key_docente = ma.key_docente				-- el mismo docente
INNER JOIN f_periodos p2
ON p2.periodo = ma2.periodo
WHERE ma.analizar = 1								-- solo filas de interés
AND p2.orden < p.orden								-- periodos anteriores
GROUP BY ma.key_estudiante, ma.periodo, ma.asignatura;

    
    