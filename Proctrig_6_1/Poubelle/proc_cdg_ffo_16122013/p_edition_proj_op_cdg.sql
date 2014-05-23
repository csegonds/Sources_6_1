---16/10/2006 ?????
---A supprimer  ???? CMA


-- Titre edition	: Projet d operation aux CDG (Acquisition,  Rétrocession)
-- Description		: Procédure principale

If Exists (Select 1 From sysobjects  Where type = 'P' and Lower(name) = Lower('p_edition_proj_op_cdg') ) 
	drop procedure p_edition_proj_op_cdg
go 


create procedure p_edition_proj_op_cdg
	@as_identifiant varchar(255),
	@an_identifiant smallint,
	@as_TypeDossier varchar(5)
as
begin

	declare @id_dossier		numeric(15),
			@fg_type_doss	varchar(5)
	declare @cd_session varchar(255)

	-- Initialisation variable
	SELECT @cd_session = convert(varchar,id_session)
	FROM #constante

	-- procédure décomposant la chaîne des identifiants passée en paramètre
	exec p_decompose_string @as_identifiant, @an_identifiant
	
	delete from #cour
	
	-- procédure insérant les interlocuteurs manquants dans les dossiers d acquisition et de retrocession 
	declare curs_dossier cursor for
	select temp_ident.id_identifiant
	from temp_ident
	WHERE temp_ident.cd_session = @cd_session
	
	open curs_dossier
	fetch curs_dossier INTO @id_dossier
	while @@sqlstatus = 0
	begin
			
	SELECT @fg_type_doss = CASE @as_TypeDossier WHEN 'A' THEN 'ACQUI'
												WHEN 'R' THEN 'RETRO'
												ELSE @as_TypeDossier END
												
	exec p_insert_cdg @id_dossier, @fg_type_doss
	
	fetch curs_dossier INTO @id_dossier
	end
	close curs_dossier
	
	-- Acquisitions 
	if @fg_type_doss = 'ACQUI'
	Begin
	insert into #cour(
	id_acqui,
	titre,
	nom_interlocuteur_cdg,
	adresse1_interlocuteur_cdg,
	adresse2_interlocuteur_cdg,
	adresse3_interlocuteur_cdg,
	code_postal,
	commune_de_residence,
	id_intl
	) 
	SELECT DISTINCT temp_ident.id_identifiant,
				titr.lb_titr,
				isnull(intv_a.lb_intv_pren,'') + ' ' + intv_a.lb_intv_nom,   
	         adr.lb_adr1,   
	         adr.lb_adr2,   
	         adr.lb_adr3,   
	         adr.cd_post_cmne,   
	         dgi_commune_a.lb_commune,
				intl.id_intl
	    FROM acqui,   
	         cour,   
	         intl,   
	         intv intv_a,   
	         adr,   
	         commune commune_a,   
	         dgi_commune dgi_commune_a,   
	         titr,   
	         temp_ident, mode_acqui
	   WHERE ( acqui.id_acqui = cour.id_doss_cour ) and  
	         ( intl.id_intl = cour.id_intl ) and  
	         ( intl.id_intv = intv_a.id_intv ) and  
	         ( intl.id_adr = adr.id_adr ) and  
	         ( commune_a.id_cmne = adr.id_cmne ) and  
	         ( dgi_commune_a.cd_dept = commune_a.cd_dept ) and  
	         ( dgi_commune_a.cd_commune = commune_a.cd_commune ) and  
	         ( titr.id_titr = intl.id_titr ) and  
	         ( acqui.id_acqui = temp_ident.id_identifiant  ) AND  
	         ( cour.fg_type_doss = 'ACQUI' ) 
		AND temp_ident.cd_session = @cd_session
	End
	
	if @@error <> 0 
	begin
		--PRINT '1- erreur proj op cdg - acquisition'
		raiserror 999999 '1- erreur proj op cdg - acquisition'
	end
	
	-- Rétrocession
	if @fg_type_doss = 'RETRO'
	Begin
		insert into #cour(
			id_retro,
			titre,
			nom_interlocuteur_cdg,
			adresse1_interlocuteur_cdg,
			adresse2_interlocuteur_cdg,
			adresse3_interlocuteur_cdg,
			code_postal,
			commune_de_residence,
			id_intl
			) 
		SELECT DISTINCT temp_ident.id_identifiant,
			titr.lb_titr,
			isnull(intv_a.lb_intv_pren,'') + ' ' + intv_a.lb_intv_nom,   
	        adr.lb_adr1,   
	         adr.lb_adr2,   
	         adr.lb_adr3,   
	         adr.cd_post_cmne,   
	         dgi_commune_a.lb_commune,
				intl.id_intl   
		FROM retro,   
	         cour,   
	         intl,   
	         intv intv_a,   
	         adr,   
	         commune commune_a,   
	         dgi_commune dgi_commune_a,   
	         titr,   
	         temp_ident 
		WHERE ( retro.id_retro = cour.id_doss_cour ) and  
	         ( intl.id_intl = cour.id_intl ) and  
	         ( intl.id_intv = intv_a.id_intv ) and  
	         ( intl.id_adr = adr.id_adr ) and  
	         ( commune_a.id_cmne = adr.id_cmne ) and  
	         ( dgi_commune_a.cd_dept = commune_a.cd_dept ) and  
	         ( dgi_commune_a.cd_commune = commune_a.cd_commune ) and  
	         ( titr.id_titr = intl.id_titr ) and  
	         ( retro.id_retro = temp_ident.id_identifiant  ) AND  
	         ( cour.fg_type_doss = 'RETRO' )  
		AND temp_ident.cd_session = @cd_session
	END
	
	if @@error <> 0 
	begin
		--PRINT '2- erreur proj op cdg - retro'
		raiserror 999999 '2- erreur proj op cdg - retro'
	end
	
	/*----- select ----*/
	select distinct titre,
	nom_interlocuteur_cdg,
	adresse1_interlocuteur_cdg,
	adresse2_interlocuteur_cdg,
	adresse3_interlocuteur_cdg,
	code_postal,
	commune_de_residence,
	fonction_ordonnateur_safer,   
	nom_ordonnateur_safer,   
	ville_service_charge_edition,
	id_intl,
	@an_identifiant nb_doss
	from #cour

end
go 

grant execute on p_edition_proj_op_cdg to public
go 

