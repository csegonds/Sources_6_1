/* Projet d operation aux CDG: Liste des rétrocessions */

If Exists (Select 1 From sysobjects  Where type = 'P' and Lower(name) = Lower('p_edition_cdg_retro') ) 
	drop procedure p_edition_cdg_retro
go 


create procedure p_edition_cdg_retro
	@adc_id_intl numeric(15)
as
begin
	Declare @ln_id_dossier Numeric(15) -- Id du dossier       
	,@lvc_description_reunion VarChar(255) -- description de la reunion

	declare @cd_session varchar(255)

	-- Initialisation variable
	SELECT @cd_session = convert(varchar,id_session)
	FROM #constante

delete from #retroCDG

-- Infos sur les dossiers de retrocession
insert into #retroCDG(
id_retro,
id_cand_attb,
reference_retrocession,
departement,
commune_pilote,
nom_technicien,
nom_departement
)
SELECT retro.id_retro,
		 retro.id_cand_attb,
		 retro.cd_codf_lett + ' ' + retro.cd_codf_dept + ' ' + right( retro.cd_codf_an, 2) + ' ' + retro.cd_codf_doss + ' ' + retro.cd_codf_cptr,
		 dgi_commune.cd_dept,   
		 dgi_commune.lb_commune,   
		 isnull(intv.lb_intv_pren,'') + ' ' + intv.lb_intv_nom,
		 dgi_dept.lb_dept		 	
FROM	 retro,
		 cand_attb,   
       pers,   
       commune,   
       dgi_commune,   
       intv,   
       temp_ident, #cour, dgi_dept 
WHERE ( pers.id_pers = retro.id_pers ) and  
       ( pers.id_pers = intv.id_intv ) and
		 ( commune.id_cmne = cand_attb.id_cmne ) and  
       ( dgi_commune.cd_dept = commune.cd_dept ) and  
       ( dgi_commune.cd_commune = commune.cd_commune ) and
		 ( retro.id_retro = temp_ident.id_identifiant  ) and
		 ( retro.id_cand_attb = cand_attb.id_cand_attb ) and
		 ( #cour.id_retro = retro.id_retro )	and
		 ( #cour.id_intl = @adc_id_intl) and
		 ( dgi_commune.cd_dept = dgi_dept.cd_dept )
AND temp_ident.cd_session = @cd_session

If @@error != 0
Begin
	--PRINT  'erreur sur l''insertion dans #retroCDG'
	raiserror 99999 'erreur sur l''insertion dans #retroCDG'
End

-- Instances
------------
-- Boucle sur les différents dossiers
Declare curs_retro cursor for
select id_cand_attb
from #retroCDG

Open curs_retro
Fetch curs_retro into @ln_id_dossier
While (@@SqlStatus = 0)
begin
	-- Description Instance
	Exec p_edition_reunion_inst	@ln_id_dossier ,'C', @lvc_description_reunion Output
	
	-- Sauvegarde info dans #retroCDG
	update #retroCDG
	set instance = @lvc_description_reunion
	where  #retroCDG.id_cand_attb = @ln_id_dossier

	If @@error != 0
	Begin
		--PRINT  'erreur sur la mise à jour de #retroCDG'
		raiserror 99999 'erreur sur mise à jour de #retroCDG'
	End

	-- Ligne suicvante
	Fetch curs_retro into @ln_id_dossier
End
close curs_retro

/*----- select ----*/
SELECT id_retro,
	reference_retrocession,
	departement,
	commune_pilote,
	nom_technicien,   
   instance,
	@adc_id_intl id_intl,
	nom_departement 
FROM 	#retroCDG

end
go 

grant execute on p_edition_cdg_retro to public
go 
