set sql_safe_updates = 0;
-- Generación de las tablas F_ que son las GOLD donde trabajaremos los modelos de ciencias de datos.


 -- -------------------------
 -- CREAMOS F_PERIODOS
 -- ------------------------

-- Arrancamos con creando los PERIODOS de interés
create view vperiodos as
select acad_career, strm
from estudiantes e
union 
select  acad_career, strm
from matriculas_estud;
-- 60 periodos.

select acad_career, strm
from periodos 
where (acad_career, strm) not in (
   select acad_career, strm
   from vperiodos);
-- 179 filas NO estan en periodos aunque si aparecen en ESTUDIANTES o en MATRICULAS_ESTUD

select acad_career, strm
from vperiodos 
where (acad_career, strm) not in (
   select acad_career, strm
   from periodos);
-- en cambio, todos los periodos en VPERIODOS están en PERIODOS, que son los que usaríamos

-- El siguiente query nos genera una tabla en EXCEL que nos permite realmente determinar qué periodos dejar
select v.acad_career, v.strm, p.descr, p.descrshort, p.term_begin_dt, p.term_end_dt, p.term_category
from vperiodos v
left join periodos p
on p.acad_career = v.acad_career
and p.strm = v.strm;

-- entonces, las asignaturas vista en un periodo de validación se meten en el periodo corresondiente con marca VALIDADO
-- y solo quedan periodos regules o de curso de verano, y van seguidos.

-- se crea manualmente la tabla CONVERSION_PERIODOS que permite reducir a CV y RE los periodos, y que no tengan nada que ver
-- con PRE o POST, pues en este conjunto de datos no se requiere.

create table f_periodos as
select distinct periodo, term_begin_dt fecha_inicio, term_end_dt fecha_final, term_category tipo, orden, ordenRE
from conversion_periodos
where term_category in ('RE','CV')
and acad_career = 'UGRD';

-- ya tenemos nuestra primera tabla bien creada, que es F_PERIODOS que solo tienen periodos regulares y de curso de verano
-- y que tienen un orden incluyendo ambos o solo tomando en cuenta regulares.   no se repite por UGRD y GRAD.alter

-- y la tabla CONVERSION_PERIODOS permite convertir los períodos que vengan de las otras tablas a alguno de estos.


 -- -------------------------
 -- CREAMOS F_MATRICULASASIGNATURAS
 -- ------------------------

-- MATRICULAS ASIGNATURAS
-- esta se origina de las tablas ESTUDIANTES, que tiene la infrmación de las matriculas en las asignaturas 300MAG006 Y 300MAG007 y
-- de la tabla MATRICULAS_ESTUD que tiene las otras asignaturas que esos estudiantes tomaron.  Vamos a dejarlas todas en una sola

drop table f_matriculasAsignaturas;
create table f_matriculasAsignaturas as
select DISTINCT me.key key_estudiante, p.periodo, me.class_nbr grupo, me.strm,
       me.stdnt_enrl_status estado, me.catalog_nbr asignatura, me.crse_grade_off nota, 
       me.unt_taken creditos, 0 key_docente, 0 analizar
from matriculas_estud me 
left join conversion_periodos p
on p.acad_career = me.acad_career
and p.strm = me.strm
union -- evita repetidos
select  DISTINCT e.key key_estudiante, p.periodo, e.class_nbr grupo, e.strm,
		e.stdnt_enrl_status estado, ct.catalog_nbr asignatura, e.crse_grade_off nota, 
		  e.unt_taken creditos, 0 key_docente, 0 analizar
	from estudiantes e
	left join conversion_periodos p
	on p.acad_career = e.acad_career
	and p.strm = e.strm
	left join  class_tbl ct
	on ct.ACAD_CAREER = e.acad_career
	and ct.strm = e.strm;
-- 97450 filas creadas

-- creamos indices para agilizar las operaciones
ALTER TABLE `proyectodegrado2`.`f_matriculasAsignaturas` 
CHANGE COLUMN `key_estudiante` `key_estudiante` VARCHAR(100) NULL DEFAULT NULL ,
CHANGE COLUMN `periodo` `periodo` VARCHAR(10) NULL DEFAULT NULL ,
CHANGE COLUMN `grupo` `grupo` INT NULL DEFAULT NULL ,
CHANGE COLUMN `estado` `estado` VARCHAR(10) NULL DEFAULT NULL ,
CHANGE COLUMN `asignatura` `asignatura` VARCHAR(20) NULL DEFAULT NULL ,
CHANGE COLUMN `nota` `nota` VARCHAR(10) NULL DEFAULT NULL ,
CHANGE COLUMN `creditos` `creditos` INT NULL DEFAULT NULL ,
CHANGE COLUMN `key_docente` `key_docente` VARCHAR(100) NOT NULL DEFAULT '0' ,
CHANGE COLUMN `analizar` `analizar` INT NOT NULL DEFAULT '0' ,
ADD INDEX `i1` (`key_estudiante` ASC, `periodo` ASC, `asignatura` ASC, `grupo` ASC, `estado` ASC) VISIBLE;
;

          
-- las asiganturas vienen con un caracter especial al principio y hay que quitar eso.
UPDATE f_matriculasAsignaturas ma
SET asignatura = REGEXP_REPLACE(asignatura, '^[^a-zA-Z0-9]+', '') ;
commit;
-- 96378 filas actualizadas.
          
-- las materias 300MAG006 y 300MAG007 se colocan como analizar = 1
update f_matriculasAsignaturas
set analizar = 1
where asignatura = '300MAG006'
OR asignatura = '300MAG007';
-- 8069 FILAS ACTUALIZADAS
commit;
 
 -- veamos que no se repita key_estudiante, periodo, asignatura
 select ma.key_estudiante, ma.periodo, ma.asignatura, estado, count(*)
 from f_matriculasAsignaturas ma
 group by ma.key_estudiante, ma.periodo, ma.asignatura, estado
 having count(*) > 1;
 -- aparecen 753 filas con count > 1.. la máxima tiene 2.
 
 -- VEAMOS UN CASO
 select *
 from f_matriculasAsignaturas
 where key_estudiante = '0163D087A12913268CBEB4C483BE1F6B6A4EB7F2'
 and periodo = '20231' 
 and asignatura  = '300MAG006';
 -- este caso aparece enrolada dos veces en el mismo periodo 20231 sin nota en dos grupos distintos..  
 
-- eliminamos casos en que aparece en el mismo periodo enrolada (E) en la misma asigantura en dos grupos,  o con 'D' la misma asignatura y dos grupos.  se elimina uno aleatorio
-- Primero averiguamos cuando un estudiante en un mismo periodo aparece mas de una vez con una misma asignatura y el mismo estado
drop table temp2;
create table temp2 as
select key_estudiante, periodo, asignatura,  estado
	from f_matriculasAsignaturas ma
	group by key_estudiante, periodo, asignatura, estado
	having count(*) > 1;

-- y ahora, creamos otra tabla con los anteriores, incluyendo qué grupos son
drop table temp;
create table temp as
select ma.key_estudiante, ma.periodo, ma.asignatura, ma.grupo, ma.estado
from f_matriculasAsignaturas ma
inner join temp2 t
on t.key_estudiante = ma.key_estudiante
and t.periodo = ma.periodo
and t.asignatura = ma.asignatura
and t.estado = ma.estado;
-- 

-- borramos entonces las filas en donde ya hay una fila igual estudiant,e periodo, asignatura, estado y diferente grupo
delete from f_matriculasAsignaturas ma
where exists (
   select 'x'
   from temp ma2
   where ma2.key_estudiante = ma.key_estudiante -- mismo estudiante
   and ma2.periodo = ma.periodo			-- mismo periodo
   and ma2.asignatura = ma.asignatura 	-- misma asignatura
   and ma2.grupo != ma.grupo			-- diferentes grupo
   and ma2.estado = ma.estado) 			-- el mismo estado
;
commit;
-- 876 filas borradas

 -- REVISEMOS OTRA VEz: veamos que no se repita key_estudiante, periodo, asignatura
 select ma.key_estudiante, ma.periodo, ma.asignatura, count(*)
 from f_matriculasAsignaturas ma
 group by ma.key_estudiante, ma.periodo, ma.asignatura
 having count(*) > 1;
 -- aparecen 468 filas en donde se repite el estudiante, periodo, asignatura
 
 -- veamos un caso
select *
 from f_matriculasAsignaturas
 where key_estudiante = '00DD41EB408DC808AAFA86EBDEF8D81780D27951'
 and periodo = '20171' 
 and asignatura  = '300TEG001';
 -- aparece con un D de un grupo, y un E en otro grupo con nota.  Deben borrarse los D 
 
 -- obtenemos las asignaturas con E 
 drop table temp;
 create table temp as
 select key_estudiante, periodo, asignatura, grupo
 from f_matriculasAsignaturas 
 where estado = 'E';
 
 -- borramos las filas con D del mismo studiante, periodo, asignatura y que exista un grupo con E en el mismo periodo asignatura
 delete from f_matriculasAsignaturas ma
 where exists(
    select 'x'
    from temp ma2
    where ma2.key_estudiante = ma.key_estudiante
    and ma2.periodo = ma.periodo
    and ma2.asignatura =ma.asignatura
    and ma2.grupo != ma.grupo) 
and ma.estado = 'D';
-- 168 filas borradas.
commit;

 -- REVISEMOS OTRA VEz: veamos que no se repita key_estudiante, periodo, asignatura
 select ma.key_estudiante, ma.periodo, ma.asignatura, count(*)
 from f_matriculasAsignaturas ma
 group by ma.key_estudiante, ma.periodo, ma.asignatura
 having count(*) > 1;
 -- 320 filas repetidas
 
  -- veamos un caso
select *
 from f_matriculasAsignaturas
 where key_estudiante = '009CE2DA29044E33DCAABDE9DF4DB11C1E3FC7D0'
 and periodo = '20222' 
 and asignatura  is null;
 
 -- vemos que se trata de matrículas con asignatura null.  Eso no nos sirve y deben eliminarse.
 delete from f_matriculasAsignaturas
 where asignatura is null;
 -- 1072 filas borradas
 
  -- REVISEMOS OTRA VEz: veamos que no se repita key_estudiante, periodo, asignatura
 select ma.key_estudiante, ma.periodo, ma.asignatura, count(*)
 from f_matriculasAsignaturas ma
 group by ma.key_estudiante, ma.periodo, ma.asignatura
 having count(*) > 1;
 -- 0 filas repetidas
 commit;
 
 
 -- para que las cosas queden bien, es mejor poner las notas en null 
-- en f_matriculasAsignaturas si el estado es D
update f_matriculasAsignaturas
set nota = null
where estado = 'D';
-- 5093 
commit;
 
 select count(*)
 from f_matriculasAsignaturas;
 -- 95334
 
 SELECT distinct key_estudiante
 from f_matriculasAsignaturas;
 -- 1944 estudiantes
 
 -- -------------------------
 -- CREAMOS F_ESTUDIANTES.  
 -- ------------------------
 
 -- se crea a partir de datos_estudiantes y se toma la que tenga menor fecha admision.   hay 
 -- 3 error del mismo estudiante con difernete colegio
 drop table f_estudiantes;
 create table f_estudiantes as
 select   e.key key_estudiante, e.sex, e.birthdate, e.birthplace, MIN(e.cod_colegio)
from datos_estudiantes e
where e.key in (
   select ma.key_estudiante
   from f_matriculasAsignaturas ma)
group by e.key, e.sex, e.birthdate, e.birthplace;
-- 1944 FILAS CREADAS

ALTER TABLE `proyectodegrado2`.`f_estudiantes` 
ADD COLUMN `fecha_icfes` DATE NULL AFTER `cod_colegio`,
CHANGE COLUMN `MIN(e.cod_colegio)` `cod_colegio` TEXT NULL DEFAULT NULL ;
   
-- revisemos que no se quedaron estudiantes repetidos
select key_estudiante, count(*)
from f_estudiantes
group by key_estudiante
having count(*) > 1;
-- 0 filas repetidas

-- AHORA CREEMOS LA COLUMNA departamento, la cual se extrae del nombre de la asignatura
ALTER TABLE `proyectodegrado2`.`f_matriculasAsignaturas` 
ADD COLUMN `departamento` VARCHAR(45) NULL AFTER `nivel_nota`;
select distinct asignatura, substring(asignatura, 1,3), substring(asignatura,4,3)
from f_matriculasAsignaturas;

update f_matriculasAsignaturas
set departamento = substring(asignatura,4,3);
commit;

select distinct departamento
from f_matriculasAsignaturas;
-- 149 departamentos

-- coloquemos la fecha icfes a cada estudiante, con el icfes presentado más reciente
drop table borrar;
create table borrar as
select  i.key, max(i.date_loaded) date_loaded
from icfes i
group by i.key;

-- un estudainte puede tener varios icfes..  cargamos el último.  
-- pero este pudo ser cargado dos veces, asi que también cargamos el último (pues en borrar está el ultimo 
-- cargado)

update f_estudiantes e
set e.fecha_icfes  = 
   (select MAX(i.test_dt)
    from icfes i
    inner join borrar b
    where i.key = e.key_estudiante
    and b.key = i.key
    and i.date_loaded = b.date_loaded);
-- 1929 filas actualizadas
commit;

select count(*)
FROM F_estudiantes;
-- 1944

--  NOTA, ESTO IMPLICA QUE HAY ESTUDIANTES SIN ICFES
select count(*)
from f_estudiantes
where fecha_icfes is null;
-- 15 = 1944 - 1929

 -- -------------------------
 -- CREAMOS F_ICFES
 -- ------------------------

select key_estudiante, count(*)
from (
	select  i.key key_estudiante, max( test_dt)
	from icfes i
    inner join borrar b
    where b.key = i.key
    and i.date_loaded = b.date_loaded
    group by i.key
    ) v
group by key_estudiante
having count(*) > 1;
-- no hay examenes repetidos

drop table borrar2;
create table borrar2 as
select  i.key, max( i.test_dt) test_dt, b.date_loaded, i.test_id
	from icfes i
    inner join borrar b
    where b.key = i.key
    and i.date_loaded = b.date_loaded
    group by i.key, b.date_loaded, i.test_id;
-- 1929

drop table f_icfes;
create table f_icfes as
select i.key key_estudiante, i.test_id, i.test_component, i.score, i.score_letter
from icfes i
inner join borrar2 b
on i.key = b.key
and i.test_id = b.test_id
and i.date_loaded = b.date_loaded;
-- 16857 filas creadas


select key_estudiante, count(*)
from (
	select distinct key_estudiante, test_id
	from f_icfes) v
group by key_estudiante
having count(*) > 1;
-- no hay etudiantes repetidos, asi que quedó bien


 -- -------------------------
 -- CREAMOS F_PROGRAMAS_ESTUDIANTES
 -- ------------------------
 drop table f_programasEstudiantes;
 create table f_programasEstudiantes as
 select distinct de.key key_estudiante, de.acad_prog programa, 
                 date_format( de.fecha_admision, '%Y-%d-%m') fecha_admision
 from datos_estudiantes de;
 -- 1968
 
 select  key_estudiante, count(*)
 from f_programasEstudiantes
 group by key_estudiante
 having count(*) > 1;
 -- 24 estudiantes tienen doble titulación (max num programas = 2)

 -- -------------------------
 -- CREAMOS F_DOCENTES
 -- ------------------------
drop table f_docentes;
create table f_docentes as
select d.key key_docente, d.sex, d.birthdate
from docentes d;
-- 29 filas

 -- -------------------------
 -- aactualizamos F_MATRICULASASIGNATURAS para key_docente y analizar
 -- ------------------------
 
 select asignatura, count(*)
 from f_matriculasAsignaturas
 where asignatura in ('300MAG006','300MAG007')
 group by asignatura;
 -- 006: 3699
 -- 007: 3446
 -- TOTAL: 7145

-- quitamos el not null de docente y analizar 
ALTER TABLE `proyectodegrado2`.`f_matriculasAsignaturas` 
CHANGE COLUMN `key_docente` `key_docente` VARCHAR(100) NULL DEFAULT '0' ,
CHANGE COLUMN `analizar` `analizar` INT NULL DEFAULT '0' ;

select distinct asignatura, key_docente
from f_matriculasAsignaturas
where asignatura in ('300MAG006','300MAG007');

update f_matriculasAsignaturas
set analizar = 0;

update f_matriculasAsignaturas
set analizar = 1
where asignatura in ('300MAG006','300MAG007');
-- 7145 filas actualizadas
commit;

select  asignatura, count(grupo)
from f_matriculasAsignaturas
where analizar = 1
group by asignatura;

update f_matriculasasignaturas ma
set key_docente = 
   (select distinct dg.key
    from docentes_x_grupo dg
    where dg.strm = ma.strm
    and dg.class_nbr = ma.grupo);
-- 95334 --- hay filas en f_matriuclasAsignaturas que no tienen docente
commit;

-- veamos que no nos quedaran key_docentes en matriculasAsignaturas que no existen en docentes
select count(*)
from f_matriculasAsignaturas ma 
where ma.key_docente is not null
and not exists (
   select 'x'
   from f_docentes d
   where d.key_docente = ma.key_docente);
-- R/ 0.   todo matriculasAsignaturas.key_docente está en docentes.key_docente

select distinct sex
from f_docentes;
-- M y F

-- -----------------
-- actualizamos F_ESTUDIANTE y F_DOCENTES genero de estudiante de M, F a 0 1, y también el del docente
-- -----------------
UPDATE f_estudiantes
set sex = 0
WHERE sex = 'F';
-- 567

UPDATE f_estudiantes
set sex = 1
WHERE sex = 'M';
-- 1377

UPDATE f_docentes
set sex = 0
WHERE sex = 'F';
-- 6

UPDATE f_docentes
set sex = 1
WHERE sex = 'M';
-- 23

commit;

-- -----------------
-- actualizamos F_ESTUDIANTES colegio de estudiante pues hay filas con un caracter especial que no se ve y debe ser OTHER
-- -----------------
update f_estudiantes
set cod_colegio = 'OTHR'
where length(cod_colegio) = 1;
-- 2 filas actualizadas
commit;

-- -----------------
-- actualizamo F_MATRICULASASIGNATURAS para que nivel nota 
-- ----------------

select estado, length(estado), count(*)
from f_matriculasAsignaturas
group by estado, length(estado);
-- confirmaos que solo hay dos estados:  E (ENROLL) y D (DROP) y no tienen caracteres especiales

-- creamos la columna NIVEL_NOTA
ALTER TABLE `proyectodegrado2`.`f_matriculasAsignaturas` 
ADD COLUMN `nivel_nota` INT NULL AFTER `analizar`;

UPDATE f_matriculasAsignaturas
SET nivel_nota = -20;
-- 95334 filas actualizadas

-- si canceló, el nivel nota es -5
UPDATE f_matriculasAsignaturas ma
SET nivel_nota = -5
WHERE estado = 'D';
-- 5093 actualizadas

-- si la perdió nivel nota 0
UPDATE f_matriculasAsignaturas ma
SET nivel_nota = 0
WHERE estado = 'E'
AND nota < 3.0;
-- 13726 actualizadas

-- si la ganó con nota entre 3 y antes de 3.8 nivel nota es 1
UPDATE f_matriculasAsignaturas ma
SET nivel_nota = 1
WHERE estado = 'E'
AND nota >=3.0
AND nota < 3.8;
-- 24603 actualizadas

-- si la ganó con nota superior a 3.8 nivel nota es 2
UPDATE f_matriculasAsignaturas ma
SET nivel_nota = 2
WHERE estado = 'E'
AND nota >=3.8;
-- 51912 actualizadas

-- resulta que el periodo 20231 vino  con estado = E pero con nota 0, y seguramente es un error.  NO puede dejarse
-- asi porque introduce un comportamiento extraño que el modelo va a tratar de replicar yq ue no es real.
select periodo, count(*)
from f_matriculasAsignaturas
where nota = 0
group by periodo
order by periodo;
-- 7501 casos para el 20231, comportamiento muy distinto a TODOS los otros periodos.

-- el 20231 entonces se deja todo con asignaturas matriculadas y nota nula
update f_matriculasAsignaturas
set nota = null, 
    estado = 'E',
    nivel_nota = -10
where periodo = '20231';
-- 7699 filas actualizadas (algunas si venian con nota)
commit;

select nivel_nota, count(*)
from f_matriculasAsignaturas
group by nivel_nota;
-- 0: 6222. (la perdieron)
-- 1: 24591 (la ganaron regular)
-- 2: 51729. (la ganaron bien)
-- -5: 4995.  ( la cancelaron)
-- -10: 7797. (la están viendo)

select estado, nota, count(*)
from f_matriculasAsignaturas
group by estado,  nota
order by estado, nota;
-- ahora si está todo en orden entre nota, estado, y el periodo 20231

select periodo, nivel_nota,  count(*)
from f_matriculasAsignaturas
group by periodo, nivel_nota
order by periodo, nivel_nota;

select * 
from f_matriculasAsignaturas
where periodo = '20231'
and nivel_nota = -5;
-- R/ 0.


-- -------------------
-- DOCENTES - CREACIÓN de clave alterna más corta
-- ------------------
ALTER TABLE `proyectodegrado2`.`f_docentes` 
ADD COLUMN `id_docente` INT NOT NULL AUTO_INCREMENT AFTER `birthdate`,
ADD PRIMARY KEY (`id_docente`);
;

-- -----------------
-- F_MATRICULAS
-- -------------------
-- Se usa para calcular promedios por semestre

drop table f_matriculas;
create table f_matriculas as
select ma.key_estudiante, ma.periodo, p.tipo, 
       round(sum(ma.creditos*ma.nota)/sum(creditos),2) promedio_semestre
from f_matriculasAsignaturas ma
inner join f_periodos p
on p.periodo = ma.periodo
group by ma.key_estudiante, ma.periodo, p.tipo;
-- 14812 filas creadas

select estado, nota, count(*)
from f_matriculasAsignaturas
group by estado, nota
order by nota;
-- 4995 filas vienen con nota nula, que corresponden a estado = 'D' y
-- y 7797  son de asignaturas que apeans están viendo.


-- veamos casos en donde el promedio_semestre es nulo
select count(*)
from f_matriculas
where promedio_semestre is null;
-- R/ 1461

-- veamos un caso
select *
from f_matriculas
where promedio_semestre is null;

-- miremos sus asignaturas matriculadas
select *
from f_matriculasAsignaturas
where key_estudiante = '3CD627BF81A83F04D38E9829F1AE45C09EA244B7'
and periodo = '20172';
-- Efectivamente, hay 7 asignaturas en ese periodo de ese estudiante y todas están canceladas
-- Aunque esto puede ser un error, también puede ser que el estudiante realmente canceló todas sus asignaturas
-- Esto implica que el promedio de ese semestre debería ser 0.

-- veamos si los 1461 casos son de ese mismo tipo
select count(*)
from f_matriculas m
where not exists (
   select 'x'
   from f_matriculasAsignaturas ma
   where ma.key_estudiante = m.key_estudiante
   and ma.periodo = m.periodo
   and ma.estado = 'E')
and m.promedio_semestre is null;
-- 205 casos UNICAMENTE..    esto indica que si puede ser un caso normal

-- veamos los otros casos
select *
from f_matriculas m
where m.promedio_semestre is null
and exists (
   select 'x'
   from f_matriculasAsignaturas ma
   where ma.key_estudiante = m.key_estudiante
   and ma.periodo = m.periodo
   and ma.estado = 'E');
-- 1256.  Son todos los casos del periodo 20231 en donde los estudiantes apenas están viendo las asignaturas

select count(*)
from f_matriculas
where periodo = '20231';
-- 1256


-- verifiquemos que toda fila en f_matriculasAsignaturas tiene fila en f_matriculas
select count(*)
from f_matriculasAsignaturas ma
where not exists (
   select 'x'
   from f_matriculas m
   where m.key_estudiante = ma.key_estudiante
   and m.periodo = ma.periodo);
-- 0.  Se confirma que toda fila en f_matriculasAsignaturas tiene una fila en f_matriculas
   
-- confirmemos los promedios
select promedio_semestre, count(*)
from f_matriculas
group by promedio_semestre
order by promedio_semestre;
-- todo f_matriculas tiene un promedio_semestre distinto a nulo, 
-- pero si hay 1114 filas con promedio-semestre = 0.  estudimeos eso.

-- confirmemos
select *
from f_matriculas
where promedio_semestre = 0
order by key_estudiante desc, periodo desc;

select *
from f_matriculasAsignaturas ma
where key_estudiante = 'F5639AFF3A4F2D64BA9477299259937090D8D4E7'
and periodo = '20201';
-- efectivamente, ese estudiante matriculó 75asignaturas y obtuvo cero en todas.  Seguramente el estudiante abandonó sus estudios.

-- veamos en qué periodos ocurrió eso
select periodo, count(*)
from f_matriculas
where promedio_semestre = 0
group by periodo
order by periodo;
-- son muy pocos casos.  1 en 20182, 1 en el 20191, etc.. 

-- en realidad son pocos casos
select count(*)
from f_matriculas
where promedio_semestre = 0;
-- 28 casos.


select nota, count(*)
from f_matriculasAsignaturas
where periodo = '20231'
group by nota
order by nota;
-- todos los casos tienen nota null.

select count(*)
from f_matriculasAsignaturas
where periodo = '20231'
;
-- 7797 filas en el 20231










 
 
 