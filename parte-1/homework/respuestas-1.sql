-- ## Semana 1 - Parte A


-- 1. Mostrar todos los productos dentro de la categoria electro junto con todos los detalles.
select * from stg.product_master where category = 'Electro'

-- 2. Cuales son los producto producidos en China?
select product_code from stg.product_master where origin = 'China'

-- 3. Mostrar todos los productos de Electro ordenados por nombre.
select product_code from stg.product_master where category = 'Electro' order by name asc

-- 4. Cuales son las TV que se encuentran activas para la venta?
select * from stg.product_master where subcategory = 'TV' and is_active = true

-- 5. Mostrar todas las tiendas de Argentina ordenadas por fecha de apertura de las mas antigua a la mas nueva.
select * from stg.store_master where country = 'Argentina' order by start_date ASC

-- 6. Cuales fueron las ultimas 5 ordenes de ventas?
select order_number  from stg.order_line_sale order by date DESC limit 5

-- 7. Mostrar los primeros 10 registros de el conteo de trafico por Super store ordenados por fecha.
select store_id, date, traffic from stg.super_store_count group by store_id, date, traffic order by date, store_id limit 10

-- 8. Cuales son los producto de electro que no son Soporte de TV ni control remoto.
select * from stg.product_master where category = 'Electro' AND subsubcategory NOT IN ('Soporte', 'Control remoto')

-- 9. Mostrar todas las lineas de venta donde el monto sea mayor a $100.000 solo para transacciones en pesos.
select * from stg.order_line_sale WHERE currency = 'ARS' AND sale > 100000

-- 10. Mostrar todas las lineas de ventas de Octubre 2022.
SELECT * from stg.order_line_sale where  date_part('month', date) = 10

-- 11. Mostrar todos los productos que tengan EAN.
select * from stg.product_master WHERE ean IS NOT null

-- 12. Mostrar todas las lineas de venta que que hayan sido vendidas entre 1 de Octubre de 2022 y 10 de Noviembre de 2022.
select * from stg.order_line_sale WHERE date BETWEEN '2022-10-01' AND '2022-11-10'


-- ## Semana 1 - Parte B

-- 1. Cuales son los paises donde la empresa tiene tiendas?
select distinct country from stg.store_master

-- 2. Cuantos productos por subcategoria tiene disponible para la venta?
select count(distinct product_code), subsubcategory from stg.product_master where is_active = true group by subsubcategory

-- 3. Cuales son las ordenes de venta de Argentina de mayor a $100.000?
select order_number from stg.order_line_sale ln
left join stg.store_master sm
on ln.store = sm.store_id
where sm.country = 'Argentina'
and ln.sale > 100000

-- 4. Obtener los decuentos otorgados durante Noviembre de 2022 en cada una de las monedas?
select date, currency, promotion from stg.order_line_sale WHERE date BETWEEN '2022-11-01' AND '2022-11-30' and promotion  is not null

-- 5. Obtener los impuestos pagados en Europa durante el 2022.
select tax from stg.order_line_sale where currency = 'EUR' and date_part('year', date) = 2022 and tax is not null

-- 6. En cuantas ordenes se utilizaron creditos?
select count(order_number) from stg.order_line_sale where credit is not null

-- 7. Cual es el % de descuentos otorgados (sobre las ventas) por tienda?
select store, sum(sale) * 1.0 / sum(promotion) as porcentaje from stg.order_line_sale group by store order by store 

-- 8. Cual es el inventario promedio por dia que tiene cada tienda?
with promedio as (
select store, date, sum(quantity) as qty from stg.order_line_sale group by store, date 
)
select store, date, avg(qty) as inventario from promedio group by store, date order by store , date

-- 9. Obtener las ventas netas y el porcentaje de descuento otorgado por producto en Argentina.
with vtas_netas as (
select order_number, (sale - coalesce(promotion,0) - coalesce(tax,0)) as netas  from stg.order_line_sale ls
left join stg.store_master sm
on ls.store = sm.store_id
where sm.country = 'Argentina' 
)

select ols.order_number, vn.netas * 100 / ols.promotion as porcentaje
from stg.order_line_sale ols
inner join vtas_netas vn
on ols.order_number = vn.order_number

-- 10. Las tablas "market_count" y "super_store_count" representan dos sistemas distintos que usa la empresa para contar la cantidad de gente que ingresa a tienda, uno para las tiendas de Latinoamerica y otro para Europa. Obtener en una unica tabla, las entradas a tienda de ambos sistemas.
select store_id, date(date::TEXT), traffic
from stg.super_store_count
union
select store_id, date(date::TEXT), traffic
from stg.market_count

-- 11. Cuales son los productos disponibles para la venta (activos) de la marca Phillips?
select product_code
from stg.product_master
where is_active = true
AND name like '%PHILIPS%'

-- 12. Obtener el monto vendido por tienda y moneda y ordenarlo de mayor a menor por valor nominal de las ventas (sin importar la moneda).
select store, sum(sale), currency
from stg.order_line_sale
group by store, currency
order by sum(sale) desc

-- 13. Cual es el precio promedio de venta de cada producto en las distintas monedas? Recorda que los valores de venta, impuesto, descuentos y creditos es por el total de la linea.
with vta_neta as (
select product, (sale - coalesce(promotion,0) - coalesce(tax,0) - coalesce(credit,0)) as neta
from stg.order_line_sale
)
select ols.product, (neta / quantity) as promedio, currency
from stg.order_line_sale ols
inner join vta_neta vn
on ols.product = vn.product
group by ols.product, ols.currency, vn.neta, ols.quantity
order by currency

-- 14. Cual es la tasa de impuestos que se pago por cada orden de venta?
select order_number, coalesce(tax,0) as tasa
from stg.order_line_sale
group by order_number, tax

-- ## Semana 2 - Parte A

-- 1. Mostrar nombre y codigo de producto, categoria y color para todos los productos de la marca Philips y Samsung, mostrando la leyenda "Unknown" cuando no hay un color disponible
select name, product_code, category,
 CASE WHEN color IS NULL THEN 'Unknown'
 ELSE color
 END
from stg.product_master
where name like '%PHILIPS%' OR name like '%Samsung%' OR name like '%SAMSUNG%'

-- 2. Calcular las ventas brutas y los impuestos pagados por pais y provincia en la moneda correspondiente.
select sm.country, sm.province, ols.currency, sum(ols.sale) as vta_bruta, sum(ols.tax) as impuestos
from stg.order_line_sale ols
left join stg.store_master sm
on ols.store = sm.store_id
group by sm.country, sm.province, ols.currency
order by sm.country, sm.province

-- 3. Calcular las ventas totales por subcategoria de producto para cada moneda ordenados por subcategoria y moneda.
select pm.subcategory, ols.currency, sum(ols.sale - ols.promotion - ols.tax - ols.credit) as vta_total
from stg.order_line_sale ols
left join stg.product_master pm
on ols.product = pm.product_code
group by pm.subcategory, ols.currency
order by pm.subcategory, ols.currency
  
-- 4. Calcular las unidades vendidas por subcategoria de producto y la concatenacion de pais, provincia; usar guion como separador y usarla para ordernar el resultado.
select pm.subcategory, CONCAT(sm.country,'-', sm.province), sum(ols.quantity) as Cantidad
from stg.order_line_sale ols
left join stg.product_master pm
on ols.product = pm.product_code
left join stg.store_master sm
on ols.store = sm.store_id
group by pm.subcategory, sm.country, sm.province
order by CONCAT(sm.country,'-', sm.province)
  
-- 5. Mostrar una vista donde sea vea el nombre de tienda y la cantidad de entradas de personas que hubo desde la fecha de apertura para el sistema "super_store".
  
-- 6. Cual es el nivel de inventario promedio en cada mes a nivel de codigo de producto y tienda; mostrar el resultado con el nombre de la tienda.
  
-- 7. Calcular la cantidad de unidades vendidas por material. Para los productos que no tengan material usar 'Unknown', homogeneizar los textos si es necesario.
  
-- 8. Mostrar la tabla order_line_sales agregando una columna que represente el valor de venta bruta en cada linea convertido a dolares usando la tabla de tipo de cambio.
  
-- 9. Calcular cantidad de ventas totales de la empresa en dolares.
  
-- 10. Mostrar en la tabla de ventas el margen de venta por cada linea. Siendo margen = (venta - descuento) - costo expresado en dolares.
  
-- 11. Calcular la cantidad de items distintos de cada subsubcategoria que se llevan por numero de orden.
  

-- ## Semana 2 - Parte B

-- 1. Crear un backup de la tabla product_master. Utilizar un esquema llamada "bkp" y agregar un prefijo al nombre de la tabla con la fecha del backup en forma de numero entero.
  
-- 2. Hacer un update a la nueva tabla (creada en el punto anterior) de product_master agregando la leyendo "N/A" para los valores null de material y color. Pueden utilizarse dos sentencias.
  
-- 3. Hacer un update a la tabla del punto anterior, actualizando la columa "is_active", desactivando todos los productos en la subsubcategoria "Control Remoto".
  
-- 4. Agregar una nueva columna a la tabla anterior llamada "is_local" indicando los productos producidos en Argentina y fuera de Argentina.
  
-- 5. Agregar una nueva columna a la tabla de ventas llamada "line_key" que resulte ser la concatenacion de el numero de orden y el codigo de producto.
  
-- 6. Crear una tabla llamada "employees" (por el momento vacia) que tenga un id (creado de forma incremental), name, surname, start_date, end_name, phone, country, province, store_id, position. Decidir cual es el tipo de dato mas acorde.
  
-- 7. Insertar nuevos valores a la tabla "employees" para los siguientes 4 empleados:
    -- Juan Perez, 2022-01-01, telefono +541113869867, Argentina, Santa Fe, tienda 2, Vendedor.
    -- Catalina Garcia, 2022-03-01, Argentina, Buenos Aires, tienda 2, Representante Comercial
    -- Ana Valdez, desde 2020-02-21 hasta 2022-03-01, España, Madrid, tienda 8, Jefe Logistica
    -- Fernando Moralez, 2022-04-04, España, Valencia, tienda 9, Vendedor.

  
-- 8. Crear un backup de la tabla "cost" agregandole una columna que se llame "last_updated_ts" que sea el momento exacto en el cual estemos realizando el backup en formato datetime.
  
-- 9. En caso de hacer un cambio que deba revertirse en la tabla "order_line_sale" y debemos volver la tabla a su estado original, como lo harias?
