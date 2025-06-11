-- Query to retrieve potential gas station data
-- Replace the variables with notebook parameters before executing
-- Parameters: inuCiclo, inuLocalidad, inuSubcategoria, inuCategoria, inuEstado_corte, inuBarrio, nuContrato, inuProteccion_datos, inuCupo_disponible
-- Example usage:
-- DEFINE inuCiclo = 1;
-- DEFINE inuLocalidad = 10;

      SELECT Cod_dpto, Desc_dpto, Cod_Localidad, Desc_localidad, Cod_barrio, Desc_barrio, Nombre_suscriptor, Cedula, Contrato,  Telefonos,  Correo,  Direccion,
       Ciclo, Mul, Categoria, Subcategoria,Estado_corte,Estado_conexion, Manzana,  Num_predio,  Cuotas_pendientes,  Cupo_asignado,  Cupo_Usado, Cupo_disponible,
       rutareparto,Segmento_comercial, desc_proteccion_datos, Proteccion_Datos,cod_categoria, cod_subcategoria, codestado_corte, cod_segemento_comercial,
       consumo, fecha_instalacion, marca,Pagare_Unico,
       desc_PROTECCION_DATOS_BRILLA,PROTECCION_DATOS_BRILLA, --511306
	   desc_PROTECCION_DATOS_GAS,PROTECCION_DATOS_GAS, --511306
	   NVL(TIEMPO_CUMPL,0) TIEMPO_CUMPL, NVL(COD_TIPO_CLIENT,2) COD_TIPO_CLIENT, CASE WHEN NVL(COD_TIPO_CLIENT,2) = 1 THEN 'BRILLA' ELSE 'NO BRILLA' END DESC_TIPO_CLIENTE, --SAO535031
    COD_DISTRITO,DESC_DISTRITO
    FROM(
      SELECT Cod_dpto,
           (SELECT ge.description FROM Open.ge_geogra_location ge WHERE ge.geograp_location_id = Cod_dpto) Desc_dpto,
           Cod_Localidad,
           Desc_localidad,
           Cod_barrio,
           (SELECT ge.description FROM Open.ge_geogra_location ge WHERE ge.geograp_location_id = Cod_barrio) Desc_barrio,
           Nombre_suscriptor,
           Cedula,
           Contrato,
           Telefonos,
           Correo,
           Direccion,
           Ciclo,
           Mul,
           (select catedesc from open.categori where catecodi = categoria) Categoria,
           (select sucadesc from open.subcateg where sucacodi = subcategoria and sucacate = categoria) Subcategoria,
           (select escodesc from open.estacort where escocodi = estado_corte) Estado_corte,
           (select description from open.ps_product_status where product_status_id = estado_conexion )Estado_conexion,
           Manzana,
           Num_predio,
           Cuotas_pendientes,
           Cupo_asignado,
           Cupo_Usado,
           CASE
           WHEN (Cupo_asignado - Cupo_Usado) <= 0 THEN
          0
           ELSE
           nvl((Cupo_asignado - Cupo_Usado),0)
           END Cupo_disponible,
           RUTAREPARTO,
           decode(Segmentacion,null,open.dald_parameter.fsbgetvalue_chain('DESCRIPC_SEGMENT_NO_EXISTE'),
            (select cond_commer_segm_id||' - '||description from open.ldc_condit_commerc_segm where cond_commer_segm_id = Segmentacion)) Segmento_comercial,

           decode(PROTECCION_DATOS,1,'AUTORIZA',2,'NO AUTORIZA',3,'REVOCA',null) desc_PROTECCION_DATOS,
           PROTECCION_DATOS PROTECCION_DATOS,
           categoria cod_categoria,
           subcategoria cod_subcategoria,
           estado_corte codestado_corte,
           nvl(Segmentacion,-1) cod_segemento_comercial,
           consumo consumo,
           fecha_instalacion fecha_instalacion,
           marca,Pagare_Unico,
           decode(PROTECCION_DATOS_BRILLA,1,'AUTORIZA',2,'NO AUTORIZA',3,'REVOCA',null) desc_PROTECCION_DATOS_BRILLA,
           PROTECCION_DATOS_BRILLA PROTECCION_DATOS_BRILLA  ,
		   decode(PROTECCION_DATOS_GAS,1,'AUTORIZA',2,'NO AUTORIZA',3,'REVOCA',null) desc_PROTECCION_DATOS_GAS,
           PROTECCION_DATOS_GAS PROTECCION_DATOS_GAS,
		   (SELECT time_compliance
			  FROM ldc_contract_increase
	         WHERE ldc_contract_increase_id=id_marcacion) TIEMPO_CUMPL, --SAO535031
		   (SELECT customer_type_id
			  FROM ldc_contract_increase
			 WHERE ldc_contract_increase_id=id_marcacion) COD_TIPO_CLIENT, --SAO535031
			'USUARIO BRILLA - NO BRILLA' DESC_TIPO_CLIENTE,
      (SELECT  D.DISTRITO_ID
           FROM  LDC_FNBDISTRITO D
           WHERE  DISTRITO_ID IN(SELECT DISTRITO_ID
                                 FROM OPEN.LDC_FNBDISTCONF
                                  WHERE DEPT_ID = cod_dpto
                                  AND LOCATION_ID = cod_localidad
								  AND ACTIVE='Y') --Aranda.112506
                                  AND ROWNUM<=1
      ) COD_DISTRITO,
      (SELECT  D.DESCRIPTION
          FROM  LDC_FNBDISTRITO D
          WHERE  DISTRITO_ID IN(SELECT DISTRITO_ID
                          FROM OPEN.LDC_FNBDISTCONF
                          WHERE DEPT_ID = cod_dpto
                          AND LOCATION_ID = cod_localidad
						  AND ACTIVE='Y') --Aranda.112506
                          AND ROWNUM<=1
       ) DESC_DISTRITO
      FROM(
          SELECT /*+
              index (servsusc ix_servsusc12)
              index (suscripc ix_suscripc13)
              use_nl (ge_geogra_location ab_address)
              use_nl(servsusc suscripc)
              index(pr_product pk_pr_product)
              index(ge_subscriber pk_ge_subscriber)
              */
              distinct
              ge_geogra_location.geo_loca_father_id Cod_dpto,
              ge_geogra_location.geograp_location_id Cod_Localidad,
              ge_geogra_location.description Desc_localidad,
              ab_address.neighborthood_id Cod_barrio,
              ge_subscriber.subscriber_name||' '||ge_subscriber.subs_last_name||' '||ge_subscriber.subs_second_last_name Nombre_suscriptor,
              ge_subscriber.identification Cedula,
              suscripc.susccodi Contrato,
              Open.ldc_reportesconsulta.fsbGetPhones(ge_subscriber.subscriber_id) Telefonos,
              ge_subscriber.e_mail Correo,
              ab_address.address_parsed Direccion,
              suscripc.susccicl Ciclo,
              /*decode((SELECT ldc_info_predio.multivivienda
              FROM Open.ldc_info_predio
              WHERE  ldc_info_predio.premise_id = ab_address.address_id), 1, 'MULTIFAMILIAR', 'UNIFAMILIAR') Mul,*/
              decode((SELECT count(1)
              FROM Open.ldc_info_predio,GISPETI.multifamiliar
              WHERE  ldc_info_predio.premise_id = ab_address.estate_number
              and multifamiliar.codigo=Open.ldc_info_predio.MULTIVIVIENDA and codigo<>-1), 1, 'MULTIFAMILIAR', 'UNIFAMILIAR') Mul,
              servsusc.sesucate Categoria,
              servsusc.sesusuca SubCategoria,
              servsusc.sesuesco Estado_corte,
              pr_product.product_status_id Estado_conexion,
              (select allocated_quota
              from open.ldc_quota_fnb where subscription_id=suscripc.susccodi and rownum=1) Cupo_asignado,
              (select quota_used
              from open.ldc_quota_fnb where subscription_id=suscripc.susccodi and rownum=1) Cupo_Usado,
              UNIDADPREDIAL.manzanacatastral Manzana,
              UNIDADPREDIAL.numeropredio Num_predio,
              (SELECT SUM(dif.difenucu - dif.difecupa)
              FROM Open.diferido dif,
                 Open.servsusc ser
              WHERE dif.difesusc = suscripc.susccodi
               AND ser.sesususc = suscripc.susccodi
               AND dif.difenuse = ser.sesunuse
               and dif.difesape>0
               AND ser.sesuserv IN (7055,7056)) Cuotas_pendientes,
              UNIDADPREDIAL.RUTAREPARTO,
              (select SU.segment_id from ldc_segment_susc su where SU.subscription_id = suscripc.susccodi and rownum = 1)Segmentacion,
              (
              SELECT  cod_estado_ley
                FROM  open.ldc_proteccion_datos
               WHERE  id_cliente = suscclie
                 AND  LDC_PROTECCION_DATOS.estado = 'S'
                 AND  rownum < 2
              ) PROTECCION_DATOS,
              --478295
              fnuConsumoMesAnterior(servsusc.sesunuse) CONSUMO,
              servsusc.SESUFEIN FECHA_INSTALACION,
              fsbMarcacionCliente(servsusc.sesunuse) MARCA,
              LDC_PKGPAGARE.fsbContratoPagUniAct(suscripc.susccodi) Pagare_Unico,
              (
              SELECT  cod_estado_ley
                FROM  open.ldc_proteccion_datos
               WHERE  id_cliente = suscclie
                 AND  LDC_PROTECCION_DATOS.estado = 'S'
                 and  instr(DALD_PARAMETER.fsbGetValue_Chain('COD_SERVFINBRPRO'),
                                 TIPO_PRODUCTO) > 0
                 AND  rownum < 2
              ) PROTECCION_DATOS_BRILLA,--511306
			  (
              SELECT  cod_estado_ley
                FROM  open.ldc_proteccion_datos
               WHERE  id_cliente = suscclie
                 AND  LDC_PROTECCION_DATOS.estado = 'S'
                 and  TIPO_PRODUCTO = (select NUMERIC_VALUE from ld_parameter where parameter_id = 'COD_SERV_GAS') --511306
                 AND  rownum < 2
              ) PROTECCION_DATOS_GAS,
			  (SELECT ldc_contract_increase_id
					        FROM ldc_contract_increase
					       WHERE subscription_id=suscripc.susccodi
					         AND ROWNUM<=1) id_marcacion
              --478295
          FROM Open.suscripc,
             Open.servsusc,
             Open.pr_product,
             Open.ge_subscriber,
             Open.ge_geogra_location,
             Open.ab_address,
             GISPETI.UNIDADPREDIAL

          WHERE suscripc.suscclie = ge_subscriber.subscriber_id
            AND suscripc.susccicl = inuCiclo
            AND ge_geogra_location.geograp_location_id = inuLocalidad
            AND servsusc.sesusuca = decode(inuSubcategoria, -1, servsusc.sesusuca,inuSubcategoria)
            AND servsusc.sesucate = decode(inuCategoria, -1, servsusc.sesucate, inuCategoria)
            AND servsusc.sesuesco = decode(inuEstado_corte, -1, servsusc.sesuesco, inuEstado_corte)
            AND ab_address.neighborthood_id = decode(inuBarrio, -1, ab_address.neighborthood_id, inuBarrio)
            AND ab_address.address_id = suscripc.susciddi
            AND suscripc.susccodi = nvl(nuContrato,suscripc.susccodi)
            AND ab_address.geograp_location_id = ge_geogra_location.geograp_location_id
            AND suscripc.susccodi = servsusc.sesususc
            AND servsusc.sesuserv = 7014
            AND servsusc.sesunuse = pr_product.product_id
            AND UNIDADPREDIAL.idaddress(+)= ab_address.address_id --SAO481811
        )
        WHERE (PROTECCION_DATOS = DECODE(inuProteccion_datos,-1,PROTECCION_DATOS,inuProteccion_datos) OR (inuProteccion_datos=-1 AND PROTECCION_DATOS IS NULL))
        AND (PROTECCION_DATOS_BRILLA = DECODE(inuProteccion_datos,-1,PROTECCION_DATOS_BRILLA,inuProteccion_datos) OR (inuProteccion_datos=-1 AND PROTECCION_DATOS_BRILLA IS NULL))--511306
		AND (PROTECCION_DATOS_GAS = DECODE(inuProteccion_datos,-1,PROTECCION_DATOS_GAS,inuProteccion_datos) OR (inuProteccion_datos=-1 AND PROTECCION_DATOS_GAS IS NULL))--511306
      ) WHERE Cupo_disponible >= inuCupo_disponible;
