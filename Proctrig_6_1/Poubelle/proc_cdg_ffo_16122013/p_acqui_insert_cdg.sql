/* Procédure testant si l'acquisition fait partie d'une substitution*/
If Exists (Select 1 From sysobjects  Where type = 'P' and Lower(name) = Lower('p_acqui_insert_cdg') ) 
	drop procedure p_acqui_insert_cdg

go 

CREATE PROCEDURE p_acqui_insert_cdg
			@id_acqui				numeric(15),
			@bl_insert_cdg			smallint,
			@fg_type_cdg			char(1), 
			@dt_rcpt_repn			datetime,
			@id_type_avis			numeric(15) AS
BEGIN
	DECLARE	@id_intl				numeric(15),
			@id_adr					numeric(15),
			@id_fnct				numeric(15),
			@id_cour				numeric(15),
			@id_cmne				numeric(15),
			@lb_reference			varchar(20),
			@nb_count				smallint,
			@nb_cour_atrt			smallint
	
	-- Initialisation
	SELECT	@lb_reference = cd_codf_lett + ' ' + cd_codf_dept + ' ' + right(cd_codf_an,2) + ' '  + cd_codf_doss + ' ' + cd_codf_cptr,
			@id_cmne = id_cmne
	FROM	acqui
	WHERE	id_acqui = @id_acqui
	AND     acqui.bl_proj_vent = 0 
	if @@error != 0 RETURN

	SELECT	@nb_cour_atrt = MAX(nb_cour_atrt)
	FROM	cour
	WHERE	id_doss_cour = @id_acqui AND 
			fg_type_doss = 'A'
			
	SELECT	@nb_cour_atrt = IsNull(@nb_cour_atrt, 0)
	
	-- Curseur des CDG
	DECLARE curs_intl_cdg CURSOR FOR
		SELECT DISTINCT
				intl.id_intl,
				intl.id_adr,
				intl.id_fnct
	    FROM 	intl,   
			 	rep_commune,
			 	intl_typedest
		WHERE	intl.id_fnct IN (-2,-3) AND
				intl.id_intl = intl_typedest.id_intl AND 
				intl_typedest.id_type_dest = -1 AND 
				rep_commune.id_intl = intl.id_intl AND 
				rep_commune.id_cmne = @id_cmne
	
	IF @fg_type_cdg IN ('T','A')	-- Tous ou Agriculture
	BEGIN
		SELECT	@nb_count = Count(*)
		FROM 	cour,
				intl,
				intl_typedest							
		WHERE	id_doss_cour = @id_acqui AND 
				fg_type_doss = 'ACQUI' AND 	
				cour.id_intl = intl.id_intl	AND
				cour.id_intl = intl_typedest.id_intl AND
				intl.id_fnct = -3 AND
				intl_typedest.id_type_dest = -1
				
		-- Si au moins une occurence on effectue une mise à jour
		IF @nb_count > 0
		BEGIN
			IF @dt_rcpt_repn IS NOT NULL
			BEGIN
				UPDATE	cour
				SET		dt_rcpt_repn = @dt_rcpt_repn,
						id_type_avis = @id_type_avis
				FROM 	intl,
						intl_typedest							
				WHERE	id_doss_cour = @id_acqui AND 
						fg_type_doss = 'ACQUI' AND
						cour.id_intl = intl.id_intl	AND 
						cour.id_intl = intl_typedest.id_intl AND
						intl.id_fnct = -3 AND
						intl_typedest.id_type_dest = -1
			END
		END
		
		-- Pas d'occurence, on insere
		IF @nb_count = 0 AND @bl_insert_cdg = 1
		BEGIN
			-- Curseur des CDG
			OPEN curs_intl_cdg
			FETCH curs_intl_cdg INTO @id_intl, @id_adr, @id_fnct
			
			WHILE @@sqlstatus = 0
			BEGIN
				IF @id_fnct = -3
				BEGIN
					-- Récupération d'un identifiant
					EXEC p_GetNewId	'cour',@id_cour OUTPUT
					
					SELECT	@nb_cour_atrt = @nb_cour_atrt + 1
					
					-- Insertion d'une occurence
					INSERT INTO cour(	id_cour,		id_adr,			id_type_avis,		id_doss_cour,
										nb_cour_atrt,	dt_cour_atrt,	dt_repn_souh,		dt_rcpt_repn,
										nm_doss,		fg_type_doss,	tt_mtiv_avis,		id_intl)
							SELECT		@id_cour,		@id_adr,		CASE WHEN @id_type_avis IS NULL THEN -2 ELSE @id_type_avis END,	@id_acqui,
										@nb_cour_atrt,	Convert(DateTime, Convert(VarChar,  getdate(), 103), 103),		NULL,				@dt_rcpt_repn,
										@lb_reference,	'ACQUI',			NULL,				@id_intl
					IF @@error != 0 RETURN
				END
				
				-- CDG Suivant
				FETCH curs_intl_cdg INTO @id_intl, @id_adr, @id_fnct
			END
			CLOSE curs_intl_cdg
		END
	END

	IF @fg_type_cdg IN ('T', 'F')	-- Tous ou Finances
	BEGIN
		SELECT	@nb_count = Count(*)
		FROM 	cour,
				intl,
				intl_typedest							
		WHERE	id_doss_cour = @id_acqui AND 
				fg_type_doss = 'ACQUI' AND 	
				cour.id_intl = intl.id_intl	AND
				cour.id_intl = intl_typedest.id_intl AND
				intl.id_fnct = -2 AND
				intl_typedest.id_type_dest = -1
				
		-- Si au moins une occurence on effectue une mise à jour
		IF @nb_count > 0
		BEGIN
			IF @dt_rcpt_repn IS NOT NULL
			BEGIN
				UPDATE	cour
				SET		dt_rcpt_repn = @dt_rcpt_repn,
						id_type_avis = @id_type_avis
				FROM 	intl,intl_typedest							
				WHERE	id_doss_cour = @id_acqui AND 
						fg_type_doss = 'ACQUI' AND
						cour.id_intl = intl.id_intl	AND 
						cour.id_intl = intl_typedest.id_intl AND
						intl.id_fnct = -2 AND
						intl_typedest.id_type_dest = -1
			END
		END
		
		-- Pas d'occurence, on insere
		IF @nb_count = 0 AND @bl_insert_cdg = 1
		BEGIN
			-- Curseur des CDG
			OPEN curs_intl_cdg
			FETCH curs_intl_cdg INTO @id_intl, @id_adr, @id_fnct
			
			WHILE @@sqlstatus = 0
			BEGIN
				IF @id_fnct = -2
				BEGIN
					-- Récupération d'un identifiant
					EXEC p_GetNewId	'cour',@id_cour OUTPUT
					
					SELECT	@nb_cour_atrt = @nb_cour_atrt + 1
					
					-- Insertion d'une occurence
					INSERT INTO cour(	id_cour,		id_adr,			id_type_avis,		id_doss_cour,
										nb_cour_atrt,	dt_cour_atrt,	dt_repn_souh,		dt_rcpt_repn,
										nm_doss,		fg_type_doss,	tt_mtiv_avis,		id_intl)
							SELECT		@id_cour,		@id_adr,		CASE WHEN @id_type_avis IS NULL THEN -2 ELSE @id_type_avis END,	@id_acqui,
										@nb_cour_atrt,	Getdate(),		NULL,				@dt_rcpt_repn,
										@lb_reference,	'ACQUI',		NULL,				@id_intl
					IF @@error != 0 RETURN
				END
				
				-- CDG Suivant
				FETCH curs_intl_cdg INTO @id_intl, @id_adr, @id_fnct
			END
			CLOSE curs_intl_cdg
		END
	END
	DEALLOCATE CURSOR curs_intl_cdg
END
go

grant execute on p_acqui_insert_cdg to public
go 

