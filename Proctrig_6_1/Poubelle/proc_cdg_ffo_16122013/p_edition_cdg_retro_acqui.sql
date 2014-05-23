-- Titre edition	: 'Projet Rétrocession'
-- Description		: liste des acquisitions
-- Crée le			: 22/03/2000
-- Référence		: 218033

/* Listes des acquisitions dans un dossier de rétrocession */ 

If Exists (Select 1 From sysobjects  Where type = 'P' and Lower(name) = Lower('p_edition_cdg_retro_acqui') ) 
	drop procedure p_edition_cdg_retro_acqui
go 


CREATE PROCEDURE p_edition_cdg_retro_acqui
	@adc_id_retro numeric(15)
AS
BEGIN
				-- @ln_surf_origine - @ln_surf_dmd_pres
				-- @ln_surf_restante - @ln_surf_retro

	DELETE FROM #acqui_sign

	--PRINT 'Insérer dans la table temporaire les données'

	INSERT INTO #acqui_sign ( 	id_acqui
										,reference_acqui
										,nom_vendeur
										,mode_de_vente
										,surface_acquisition
										,departement_acquisition
										,commune_acquisition
									)
	SELECT	acqui.id_acqui
				,acqui.cd_codf_lett + ' ' + acqui.cd_codf_dept + ' ' + right( acqui.cd_codf_an, 2) 
				+ ' ' + acqui.cd_codf_doss + ' ' + acqui.cd_codf_cptr   
				,intv.lb_intv_nom + ' ' + isnull(intv.lb_intv_pren,'')   
				,mode_acqui.lb_mode_acqui
				,acqui.dc_supf_acqui   
				,dgi_commune.cd_dept   
         	,dgi_commune.lb_commune
    FROM acqui,   
         unit_acqui_fncr,   
         unit_retro_fncr,   
         vedr,   
         mode_acqui,   
         commune,   
         dgi_commune,   
         intv  
   WHERE unit_retro_fncr.id_unit_acqui_fncr = unit_acqui_fncr.id_unit_acqui_fncr
	AND	unit_acqui_fncr.id_acqui = acqui.id_acqui
	AND	unit_acqui_fncr.id_acqui = vedr.id_acqui
	AND	mode_acqui.id_mode_acqui = acqui.id_mode_acqui
	AND	commune.id_cmne = acqui.id_cmne
	AND	commune.cd_dept = dgi_commune.cd_dept
	AND	commune.cd_commune = dgi_commune.cd_commune
	AND	intv.id_intv = vedr.id_intv
	AND	unit_retro_fncr.id_retro = @adc_id_retro
	AND	vedr.bl_vedr_pilt = 1

	If @@error != 0
	Begin
		--PRINT  'erreur sur l''insertion dans #acqui_sign'
		raiserror 99999 'erreur sur l''insertion dans #acqui_sign'
	End

	UPDATE	#acqui_sign
	SET 		date_acquisition = 	CASE	WHEN acqui.dt_sign_acte IS NOT NULL
										THEN convert(varchar(10), acqui.dt_sign_acte, 103) + ' (S)'
									WHEN acqui.dt_sign_prev IS NOT NULL
										THEN convert(varchar(10), acqui.dt_sign_prev, 103) + ' (P)'
									WHEN acqui.dt_sign_prev_init IS NOT NULL
										THEN convert(varchar(10), acqui.dt_sign_prev_init, 103) + ' (P)'
							  END
	From acqui,
	         unit_acqui_fncr,   
        	 unit_retro_fncr
	WHERE 	unit_retro_fncr.id_unit_acqui_fncr = unit_acqui_fncr.id_unit_acqui_fncr
	AND		unit_acqui_fncr.id_acqui = acqui.id_acqui
	AND		unit_retro_fncr.id_retro = @adc_id_retro
	AND        #acqui_sign.id_acqui = acqui.id_acqui



	--PRINT 'Récupérer : somme des superficies des parcelles de l''acquisition affectées dans ce dossier de rétrocession'
	UPDATE	#acqui_sign
	SET 	surface_sans_format = ( select sum(CASE WHEN unit_acqui_fncr.cd_div = '' THEN unit_acqui_fncr.nb_surface ELSE unit_acqui_fncr.nb_surface_dmde END)
									FROM	unit_acqui_fncr,   
											unit_retro_fncr,
											retro
									WHERE #acqui_sign.id_acqui = unit_acqui_fncr.id_acqui
									AND	unit_retro_fncr.id_retro = @adc_id_retro
									AND unit_retro_fncr.id_unit_acqui_fncr = unit_acqui_fncr.id_unit_acqui_fncr
									AND 	unit_retro_fncr.id_retro = retro.id_retro
										)
	If @@error != 0
	Begin
		--PRINT  'erreur sur la mise à jour de #acqui_sign'
		raiserror 99999 'erreur sur mise à jour de #acqui_sign'
	End

	--PRINT 'Surface présentée'
	UPDATE	#acqui_sign
	SET	surface_presentee = isnull( (  SELECT sum(CASE WHEN unit_acqui_fncr.cd_div = '' THEN unit_acqui_fncr.nb_surface ELSE unit_acqui_fncr.nb_surface_dmde END)
					 FROM 	unit_acqui_fncr,   
							unit_retro_fncr
					WHERE 	( unit_acqui_fncr.id_acqui = #acqui_sign.id_acqui) and 
							( unit_retro_fncr.id_unit_acqui_fncr = unit_acqui_fncr.id_unit_acqui_fncr ) and  
  						    ( unit_retro_fncr.id_retro <> @adc_id_retro)	and 
							exists ( select 1 from cour  	
										 where ( unit_retro_fncr.id_retro = cour.id_doss_cour ) and  
		  										 ( cour.fg_type_doss = 'RETRO'  ) 
									 )
								), 0)
	 
	If @@error != 0
	Begin
		--PRINT  'erreur sur la mise à jour de #acqui_sign'
		raiserror 99999 'erreur sur mise à jour de #acqui_sign'
	End

/*----- select ----*/
SELECT 	DISTINCT @adc_id_retro id_retro
			,reference_acqui
			,mode_de_vente
			,departement_acquisition
			,commune_acquisition
			,nom_vendeur
			,date_acquisition
			,surface_acquisition									superficie_origine
			,surface_presentee									demandes_presentees
			,(surface_acquisition - surface_presentee)	superficie_restante
			,surface_sans_format								cession_projetee
			,(surface_acquisition - surface_presentee - surface_sans_format) solde

FROM 	#acqui_sign
order by reference_acqui

END
go 

grant execute on p_edition_cdg_retro_acqui to public
go 
