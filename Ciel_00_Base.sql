/*
drop table eml.Churn_Ciel_Base
drop table eml.Churn_all_bu_Ciel
drop table eml.Churn_all_bu
drop table eml.chur_AB_all_bu
*/



declare @datedebut date, @datefin date, @dateref int

SET @datedebut = '2019-10-01'
set @datefin = '2020-09-30'
set @dateref ='-5'

SELECT DISTINCT 
                         a.AccountId AS [Id Tiers], 
						 a.AccountNumber AS Account_Number, 
						 a.new_Raisonsociale AS Raison_Sociale, 
						 a.new_IdentifiantProfessionnel AS SIRET, 
						 CASE WHEN a.Telephone1 IS NOT NULL 
                         THEN 'oui' ELSE 'non' END AS telephone,
						 a.new_NAFIdName, 
						 Statut_Client.Value AS Etat, 
						 Mode_commercialisation_licence.Value AS Mode_Comm, 
						 CASE WHEN a.new_ispartenaire = 1 THEN 'oui' ELSE 'non' END AS Flag_partenaire,
                          a.new_paystiersidName AS Country, 
						  parcpere.new_identifiantproduit AS PP, 
						  parcpere.new_codeproduit AS reference, 
						  users.new_Quantite AS Users, 
						  parcpere.new_numero_serie AS Numero_Serie, 
                         parcpere.new_Identifiant AS urn, 
						 r.AccountNumber AS idRevendeur, 
						 r.new_Raisonsociale AS rsRevendeur,
						 a.new_NoteNPS,
						 a.new_nps_autrecommentaire,
						 a.new_nps_notenps, 
						 pdt_lic.new_Domaine_produit_StatName AS DOS, 
						 pdt_lic.new_Ligne_produit_StatName AS LPS, 
                         parcfils.new_identifiantproduit AS Libelle_contrat, 
						 Etat_PE.Value AS etat_PE, 
						 CONVERT(date, parcfils.new_Datededbut, 103) AS date_debut, 
						 CONVERT(date, parcfils.new_Datedefin, 103) AS date_fin_contrat, 
                         parcfils.new_Datedevente AS date_vente, 
						 Duree_engagement.Value AS Duree_engagement, 
						 parcfils.new_Prixnonproratise AS PNP, 
						 parcfils.new_prixnonproratiseremise AS PNPR, 
                         CASE WHEN parcpere.new_numero_serie IS NULL OR
                         parcpere.new_numero_serie = 'EN ATTENTE DE REF' THEN 'KO' ELSE 'OK' END AS RegistrationStatus, 
						  --CASE WHEN parcfils.new_Etatequipement = '279640002' AND (parcfils.new_motifavoir = '100000004' OR
                         --parcfils.new_motifavoir IS NULL) THEN 1 ELSE 0 END AS TargetEvent,
						 --CASE WHEN parcfils.new_Etatequipement = '279640002' AND (parcfils.new_motifavoir = '100000004' OR
                         --parcfils.new_motifavoir IS NULL) THEN resil.Value ELSE null END AS MotifResil,
                         case when cc.Identifiant_CNT is null or cc.motif_inactivation_calc in ('UPSELL','Upsell avec changement de contrat','Erreur création parc') then 0 else 1 end as TargetEvent, ----------------------Emil & Diaraye
                         cc.Type_date_calc as MotifResil, ----------------------Emil & Diaraye 09/07/21

						 pdt_lic.new_SousTypologie, 
						 parcfils.new_parcId, 
						 a.new_ModereglementName AS ModeRegelementTier, 
						 parcpere.new_StatutoptionName, 
                         parcpere.new_statutpaiement, 
						 statut_paiement_contrat.Value AS Statut_Paiement_contrat, 
						 statut_paiement_licence.Value AS Statut_Paiement_licence, 
						 CONVERT(date, MAX(DATEADD(mm, @dateref, parcfils.new_Datedefin)), 103) AS ReferenceDate, 
						 parcpere.new_Versionlivre AS Version, 
						 parcfils.new_Identifiant AS urnfils

        --------------ajout donnees churn enquête chaud--------------------------

                        --,a.new_date_enquete
                        --,a.new_note_enquete
                        --,a.new_ces
                        --,a.new_fcr
                        --,case when a.new_ces='Extrèmement faible (1)' then 1 
                        --when a.new_ces='Très faible (2)' then 2 
                        --when a.new_ces='Faible (3)' then 3 
                        --when a.new_ces='Moyen (4)' then 4 
                        --when a.new_ces='Elevé (5)' then 5 
                        --when a.new_ces='Très élevé (6)' then 6 
                        --when a.new_ces='Extrêmement élevé (7)' then 7 else a.new_ces end as new_ces_score

into EML.Churn_Ciel_Base
FROM            PCRM_MSCRM.dbo.new_parc AS parcpere INNER JOIN
                         PCRM_MSCRM.dbo.Product AS pdt_lic ON pdt_lic.ProductNumber = parcpere.new_codeproduit AND parcpere.new_template = 0 AND parcpere.new_TiersId IS NOT NULL AND 
                         parcpere.new_parcderattachementId IS NULL AND (parcpere.new_usage = 100000008 OR
                         parcpere.new_usage IS NULL) AND pdt_lic.new_SousTypologie IN (100000000, 100000002) AND pdt_lic.new_Typeduproduit IN (100000000, 279640002) AND 
                         (pdt_lic.new_Domaine_produit_Stat NOT IN ('C3F926E4-CED9-E211-AB10-005056965CBC', '3DFA26E4-CED9-E211-AB10-005056965CBC', 'EBF926E4-CED9-E211-AB10-005056965CBC','83E8D2FC-DD5D-E311-9E34-00505696792C'/*auto entrepreneur*/,'81E8D2FC-DD5D-E311-9E34-00505696792C'/*association*/) OR
                         pdt_lic.new_Domaine_produit_Stat IS NULL) AND pdt_lic.new_BUReconnaissancederevenu = 100000000 LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS Mode_commercialisation_licence ON parcpere.new_modedecommerce = Mode_commercialisation_licence.AttributeValue AND 
                         Mode_commercialisation_licence.ObjectTypeCode = 10036 AND Mode_commercialisation_licence.AttributeName = 'new_modedecommerce' LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.new_configurationcameleon AS users ON parcpere.new_parcId = users.new_elementdeparc AND users.statecode = 0 AND users.new_type IN (100000000, 100000001, 100000002) INNER JOIN
                         PCRM_MSCRM.dbo.new_parc AS parcfils INNER JOIN
                         PCRM_MSCRM.dbo.Product AS pdt_fils ON parcfils.new_codeproduit = pdt_fils.ProductNumber ON parcpere.new_parcId = parcfils.new_parcderattachementId AND 
                         parcfils.new_parcderattachementId IS NOT NULL AND parcfils.new_template = 0 AND parcfils.new_Datedefin BETWEEN @datedebut AND @datefin AND pdt_fils.new_SousTypologie = 100000004 AND 
                         pdt_fils.new_Typeduproduit = 100000001 AND parcfils.new_codeproduit NOT IN ('GCIAS0095', 'GCIAS0019','GCICL0058','GCISC0022'/*gratuit 30 jours,ciel bilan*/) LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS Etat_PE WITH (nolock) ON Etat_PE.AttributeValue = parcfils.new_Etatequipement AND Etat_PE.ObjectTypeCode = 10036 AND 
                         Etat_PE.AttributeName = 'new_etatequipement' LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS Duree_engagement ON parcfils.new_Dureeengagement = Duree_engagement.AttributeValue AND Duree_engagement.ObjectTypeCode = 10036 AND 
                         Duree_engagement.AttributeName = 'new_dureeengagement' 
						 LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS resil ON parcfils.new_MotifAbandonResiliation = resil.AttributeValue AND resil.ObjectTypeCode = 10036 AND 
                         resil.AttributeName = 'new_MotifAbandonResiliation' 
						 LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS statut_paiement_licence ON parcpere.new_statutpaiement = statut_paiement_licence.AttributeValue AND statut_paiement_licence.ObjectTypeCode = 10036 AND 
                         statut_paiement_licence.AttributeName = 'new_statutpaiement' LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS statut_paiement_contrat ON parcfils.new_statutpaiement = statut_paiement_contrat.AttributeValue AND statut_paiement_contrat.ObjectTypeCode = 10036 AND 
                         statut_paiement_contrat.AttributeName = 'new_statutpaiement' LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.Account AS a ON a.AccountId = parcpere.new_TiersId AND a.new_ispartenaire = 0 AND a.new_Typedetiers NOT IN ('100000004', '100000000', '100000002', '279640003') LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.Account AS r ON r.AccountId = parcpere.new_revendeur LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.Account AS Partenaire WITH (nolock) ON Partenaire.AccountId = parcfils.new_partenaireservice LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS Statut_Client ON a.new_StatutClient = Statut_Client.AttributeValue AND Statut_Client.ObjectTypeCode = 1 AND Statut_Client.AttributeName = 'new_statutclient'
                         --LEFT OUTER JOIN TEMP_CHURN_ALL_BU_ABNAB AS t on t.accountid=a.accountid ---jointure churn_all_bu_arnab pour enquête chaud

                        LEFT JOIN sales_ops.dbo.PIVOT_CHURN_SEGMENT_ALL cc on cc.Identifiant_CNT=parcfils.new_Identifiant ---Emil & Diaraye
WHERE        (a.StateCode = 0) AND (a.new_ispartenaire = 0) AND (a.new_TypetiersEC IS NULL) AND (a.new_NAFId not in (
'BFB4073A-CED9-E211-AB10-005056965CBC',
'2FB5073A-CED9-E211-AB10-005056965CBC',
'31B5073A-CED9-E211-AB10-005056965CBC',
'33B5073A-CED9-E211-AB10-005056965CBC',
'35B5073A-CED9-E211-AB10-005056965CBC',
'37B5073A-CED9-E211-AB10-005056965CBC',
'39B5073A-CED9-E211-AB10-005056965CBC',
'3BB5073A-CED9-E211-AB10-005056965CBC',
'3DB5073A-CED9-E211-AB10-005056965CBC',
'3FB5073A-CED9-E211-AB10-005056965CBC',
'41B5073A-CED9-E211-AB10-005056965CBC',
'43B5073A-CED9-E211-AB10-005056965CBC',
'45B5073A-CED9-E211-AB10-005056965CBC',
'47B5073A-CED9-E211-AB10-005056965CBC',
'49B5073A-CED9-E211-AB10-005056965CBC',
'4BB5073A-CED9-E211-AB10-005056965CBC',
'4DB5073A-CED9-E211-AB10-005056965CBC',
'4FB5073A-CED9-E211-AB10-005056965CBC',
'51B5073A-CED9-E211-AB10-005056965CBC',
'53B5073A-CED9-E211-AB10-005056965CBC',
'55B5073A-CED9-E211-AB10-005056965CBC',
'57B5073A-CED9-E211-AB10-005056965CBC',
'59B5073A-CED9-E211-AB10-005056965CBC',
'5BB5073A-CED9-E211-AB10-005056965CBC',
'5DB5073A-CED9-E211-AB10-005056965CBC',
'5FB5073A-CED9-E211-AB10-005056965CBC',
'61B5073A-CED9-E211-AB10-005056965CBC',
'63B5073A-CED9-E211-AB10-005056965CBC',
'65B5073A-CED9-E211-AB10-005056965CBC',
'67B5073A-CED9-E211-AB10-005056965CBC',
'69B5073A-CED9-E211-AB10-005056965CBC',
'6BB5073A-CED9-E211-AB10-005056965CBC',
'6DB5073A-CED9-E211-AB10-005056965CBC',
'6FB5073A-CED9-E211-AB10-005056965CBC',
'71B5073A-CED9-E211-AB10-005056965CBC',
'73B5073A-CED9-E211-AB10-005056965CBC',
'75B5073A-CED9-E211-AB10-005056965CBC',
'77B5073A-CED9-E211-AB10-005056965CBC',
'79B5073A-CED9-E211-AB10-005056965CBC',
'7BB5073A-CED9-E211-AB10-005056965CBC',
'7DB5073A-CED9-E211-AB10-005056965CBC',
'7FB5073A-CED9-E211-AB10-005056965CBC',
'81B5073A-CED9-E211-AB10-005056965CBC',
'83B5073A-CED9-E211-AB10-005056965CBC',
'85B5073A-CED9-E211-AB10-005056965CBC')
) and pdt_lic.new_Ligne_produit_StatName !='Quantum'
GROUP BY a.AccountId, a.AccountNumber, a.new_Raisonsociale, a.new_IdentifiantProfessionnel, CASE WHEN a.Telephone1 IS NOT NULL THEN 'oui' ELSE 'non' END, Statut_Client.Value, 
                         Mode_commercialisation_licence.Value, CASE WHEN a.new_ispartenaire = 1 THEN 'oui' ELSE 'non' END, a.new_paystiersidName, parcpere.new_identifiantproduit, parcpere.new_codeproduit, 
                         users.new_Quantite, parcpere.new_codeproduit, parcpere.new_numero_serie, a.new_NAFIdName, parcpere.new_Identifiant, r.AccountNumber, r.new_Raisonsociale, pdt_lic.new_Domaine_produit_StatName, 
                         pdt_lic.new_Ligne_produit_StatName, parcfils.new_identifiantproduit, Etat_PE.Value,CASE WHEN parcfils.new_Etatequipement = '279640002' AND (parcfils.new_motifavoir = '100000004' OR
                         parcfils.new_motifavoir IS NULL) THEN resil.Value ELSE null END, CONVERT(date, parcfils.new_Datededbut, 103), CONVERT(date, parcfils.new_Datedefin, 103), parcfils.new_Datedevente, 
                         Duree_engagement.Value, parcfils.new_Prixnonproratise, parcfils.new_prixnonproratiseremise, CASE WHEN parcfils.new_Etatequipement = '279640002' AND (parcfils.new_motifavoir = '100000004' OR
                         parcfils.new_motifavoir IS NULL) THEN 1 ELSE 0 END, pdt_lic.new_SousTypologie, parcfils.new_parcId, a.new_ModereglementName, parcpere.new_StatutoptionName, parcpere.new_statutpaiement, 
                         statut_paiement_contrat.Value, statut_paiement_licence.Value, CASE WHEN parcpere.new_numero_serie IS NULL OR
                         parcpere.new_numero_serie = 'EN ATTENTE DE REF' THEN 'KO' ELSE 'OK' END, parcpere.new_Versionlivre, parcfils.new_Identifiant,a.new_NoteNPS,a.new_nps_autrecommentaire,a.new_nps_notenps
                         --,a.new_date_enquete,a.new_note_enquete,a.new_ces,a.new_fcr
                        ,motif_inactivation_calc, Identifiant_CNT,Type_date_calc


-------------Churn_all_bu_ciel-----------------
SELECT DISTINCT 
                         a.AccountId AS [Id Tiers], 
						 a.AccountNumber AS [Code Tiers], 
						 a.new_Raisonsociale AS [Raison Sociale], 
						 parcpere.new_identifiantproduit AS PP, 
						 pdt_lic.new_Domaine_produit_StatName AS DOS, 
                         pdt_lic.new_Ligne_produit_StatName AS LPS, 
						 Etat_PE.Value AS etat_PE, 
						 parcfils.new_Datedevente AS date_vente, 
						 Duree_engagement.Value AS Duree_engagement, 
						 pdt_lic.new_SousTypologie, 
						 parcfils.new_parcId, 
                         CONVERT(date, MAX(DATEADD(mm, @dateref, parcfils.new_Datedefin)), 103) AS ReferenceDate, 
						 pdt_lic.new_BUReconnaissancederevenu AS BU, 
						 CONVERT(date, parcfils.new_Datedefin, 103) AS date_fin_contrat, 
						 parcpere.CreatedOn, 
                         parcpere.new_Identifiant AS urn
into EML.Churn_all_bu_ciel
FROM            PCRM_MSCRM.dbo.new_parc AS parcpere INNER JOIN
                         
						 PCRM_MSCRM.dbo.Product AS pdt_lic ON pdt_lic.ProductNumber = parcpere.new_codeproduit AND parcpere.new_template = 0 AND parcpere.new_numero_serie IS NOT NULL AND 
                         parcpere.new_numero_serie <> 'EN ATTENTE DE REF' AND parcpere.new_TiersId IS NOT NULL AND parcpere.new_parcderattachementId IS NULL AND (parcpere.new_usage = 100000008 OR
                         parcpere.new_usage IS NULL) AND pdt_lic.new_SousTypologie IN (100000000, 100000002) AND pdt_lic.new_Typeduproduit IN (100000000, 279640002) AND 
                         (pdt_lic.new_Domaine_produit_Stat NOT IN ('C3F926E4-CED9-E211-AB10-005056965CBC', '3DFA26E4-CED9-E211-AB10-005056965CBC', 'EBF926E4-CED9-E211-AB10-005056965CBC') OR
                         pdt_lic.new_Domaine_produit_Stat IS NULL) LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS Mode_commercialisation_licence ON parcpere.new_modedecommerce = Mode_commercialisation_licence.AttributeValue AND 
                         Mode_commercialisation_licence.ObjectTypeCode = 10036 AND Mode_commercialisation_licence.AttributeName = 'new_modedecommerce' LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.new_configurationcameleon AS users ON parcpere.new_parcId = users.new_elementdeparc AND users.statecode = 0 AND users.new_type IN (100000000, 100000001, 100000002) INNER JOIN
                         PCRM_MSCRM.dbo.new_parc AS parcfils INNER JOIN
                         PCRM_MSCRM.dbo.Product AS pdt_fils ON parcfils.new_codeproduit = pdt_fils.ProductNumber ON parcpere.new_parcId = parcfils.new_parcderattachementId AND parcfils.new_parcderattachementId IS NOT NULL AND 
                         parcfils.new_template = 0 AND parcfils.new_Datedefin BETWEEN @datedebut AND @datefin AND pdt_fils.new_SousTypologie = 100000004 AND pdt_fils.new_Typeduproduit = 100000001 AND 
                         parcfils.new_codeproduit NOT IN ('GCIAS0095', 'GCIAS0019') LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS Etat_PE WITH (nolock) ON Etat_PE.AttributeValue = parcfils.new_Etatequipement AND Etat_PE.ObjectTypeCode = 10036 AND 
                         Etat_PE.AttributeName = 'new_etatequipement' LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS Duree_engagement ON parcfils.new_Dureeengagement = Duree_engagement.AttributeValue AND Duree_engagement.ObjectTypeCode = 10036 AND 
                         Duree_engagement.AttributeName = 'new_dureeengagement' LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS statut_paiement_licence ON parcpere.new_statutpaiement = statut_paiement_licence.AttributeValue AND statut_paiement_licence.ObjectTypeCode = 10036 AND 
                         statut_paiement_licence.AttributeName = 'new_statutpaiement' LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS statut_paiement_contrat ON parcfils.new_statutpaiement = statut_paiement_contrat.AttributeValue AND statut_paiement_contrat.ObjectTypeCode = 10036 AND 
                         statut_paiement_contrat.AttributeName = 'new_statutpaiement' INNER JOIN
                         PCRM_MSCRM.dbo.Account AS a ON a.AccountId = parcpere.new_TiersId AND a.new_ispartenaire = 0 AND a.new_Typedetiers NOT IN ('100000004', '100000000', '100000002', '279640003') LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.Account AS r ON r.AccountId = parcpere.new_revendeur LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS Statut_Client ON a.new_StatutClient = Statut_Client.AttributeValue AND Statut_Client.ObjectTypeCode = 1 AND Statut_Client.AttributeName = 'new_statutclient'
WHERE        (a.StateCode = 0) AND (a.new_ispartenaire = 0) AND (a.new_TypetiersEC IS NULL) AND (a.new_NAFId <> 'BFB4073A-CED9-E211-AB10-005056965CBC')

GROUP BY a.AccountId, a.AccountNumber, a.new_Raisonsociale, parcpere.new_identifiantproduit, parcpere.new_codeproduit, parcpere.new_codeproduit, pdt_lic.new_Domaine_produit_StatName, pdt_lic.new_Ligne_produit_StatName, 
                         Etat_PE.Value, parcfils.new_Datedevente, Duree_engagement.Value, pdt_lic.new_SousTypologie, parcfils.new_parcId, pdt_lic.new_BUReconnaissancederevenu, CONVERT(date, parcfils.new_Datedefin, 103), 
                         parcpere.CreatedOn, parcpere.new_Identifiant, parcfils.new_Identifiant


----------------------------------churn_ab_all_bu-----------------

		SELECT DISTINCT 
                         a.AccountId AS [Id Tiers], 
						 a.AccountNumber AS [Code Tiers], 
						 a.new_Raisonsociale AS [Raison Sociale], 
						 parcpere.new_identifiantproduit AS PP,
						 pdt_lic.new_Domaine_produit_StatName AS DOS, 
                         pdt_lic.new_Ligne_produit_StatName AS LPS, 
						 Etat_PE.Value AS etat_PE, 
						 parcfils.new_Datedevente AS date_vente, 
						 Duree_engagement.Value AS Duree_engagement, 
						 pdt_lic.new_SousTypologie, 
						 parcfils.new_parcId, 
                         CONVERT(date, MAX(DATEADD(mm, @dateref, parcfils.new_Datedefin)), 103) AS ReferenceDate, 
						 pdt_lic.new_BUReconnaissancederevenu AS BU, 
						 CONVERT(date, parcfils.new_Datedefin, 103) AS date_fin_contrat, 
						 parcpere.CreatedOn, 
                         parcpere.new_Identifiant AS urn
into EML.chur_AB_all_bu
FROM            PCRM_MSCRM.dbo.new_parc AS parcpere INNER JOIN
                         PCRM_MSCRM.dbo.Product AS pdt_lic ON pdt_lic.ProductNumber = parcpere.new_codeproduit AND parcpere.new_template = 0 AND parcpere.new_numero_serie IS NOT NULL AND 
                         parcpere.new_numero_serie <> 'EN ATTENTE DE REF' AND parcpere.new_TiersId IS NOT NULL AND parcpere.new_parcderattachementId IS NULL AND (parcpere.new_usage = 100000008 OR
                         parcpere.new_usage IS NULL) AND pdt_lic.new_SousTypologie IN (100000000, 100000002) AND pdt_lic.new_Typeduproduit IN (100000000, 279640002) AND 
                         (pdt_lic.new_Domaine_produit_Stat NOT IN ('C3F926E4-CED9-E211-AB10-005056965CBC', '3DFA26E4-CED9-E211-AB10-005056965CBC', 'EBF926E4-CED9-E211-AB10-005056965CBC') OR
                         pdt_lic.new_Domaine_produit_Stat IS NULL) LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS Mode_commercialisation_licence ON parcpere.new_modedecommerce = Mode_commercialisation_licence.AttributeValue AND 
                         Mode_commercialisation_licence.ObjectTypeCode = 10036 AND Mode_commercialisation_licence.AttributeName = 'new_modedecommerce' LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.new_configurationcameleon AS users ON parcpere.new_parcId = users.new_elementdeparc AND users.statecode = 0 AND users.new_type IN (100000000, 100000001, 100000002) INNER JOIN
                         PCRM_MSCRM.dbo.new_parc AS parcfils INNER JOIN
                         PCRM_MSCRM.dbo.Product AS pdt_fils ON parcfils.new_codeproduit = pdt_fils.ProductNumber ON parcpere.new_parcId = parcfils.new_parcderattachementId AND parcfils.new_parcderattachementId IS NOT NULL AND 
                         parcfils.new_template = 0 AND parcfils.new_Datedefin BETWEEN @datedebut AND @datefin AND pdt_fils.new_SousTypologie = 100000004 AND pdt_fils.new_Typeduproduit = 100000001 AND 
                         parcfils.new_codeproduit NOT IN ('GCIAS0095', 'GCIAS0019') LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS Etat_PE WITH (nolock) ON Etat_PE.AttributeValue = parcfils.new_Etatequipement AND Etat_PE.ObjectTypeCode = 10036 AND 
                         Etat_PE.AttributeName = 'new_etatequipement' LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS Duree_engagement ON parcfils.new_Dureeengagement = Duree_engagement.AttributeValue AND Duree_engagement.ObjectTypeCode = 10036 AND 
                         Duree_engagement.AttributeName = 'new_dureeengagement' LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS statut_paiement_licence ON parcpere.new_statutpaiement = statut_paiement_licence.AttributeValue AND statut_paiement_licence.ObjectTypeCode = 10036 AND 
                         statut_paiement_licence.AttributeName = 'new_statutpaiement' LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS statut_paiement_contrat ON parcfils.new_statutpaiement = statut_paiement_contrat.AttributeValue AND statut_paiement_contrat.ObjectTypeCode = 10036 AND 
                         statut_paiement_contrat.AttributeName = 'new_statutpaiement' INNER JOIN
                         PCRM_MSCRM.dbo.Account AS a ON a.AccountId = parcpere.new_TiersId AND a.new_ispartenaire = 0 AND a.new_Typedetiers NOT IN ('100000004', '100000000', '100000002', '279640003') LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.Account AS r ON r.AccountId = parcpere.new_revendeur LEFT OUTER JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS Statut_Client ON a.new_StatutClient = Statut_Client.AttributeValue AND Statut_Client.ObjectTypeCode = 1 AND Statut_Client.AttributeName = 'new_statutclient'
WHERE        (a.StateCode = 0) AND (a.new_ispartenaire = 0) AND (a.new_TypetiersEC IS NULL) AND (a.new_NAFId <> 'BFB4073A-CED9-E211-AB10-005056965CBC')
GROUP BY a.AccountId, a.AccountNumber, a.new_Raisonsociale, parcpere.new_identifiantproduit, parcpere.new_codeproduit, parcpere.new_codeproduit, pdt_lic.new_Domaine_produit_StatName, pdt_lic.new_Ligne_produit_StatName, 
                         Etat_PE.Value, parcfils.new_Datedevente, Duree_engagement.Value, pdt_lic.new_SousTypologie, parcfils.new_parcId, pdt_lic.new_BUReconnaissancederevenu, CONVERT(date, parcfils.new_Datedefin, 103), 
                         parcpere.CreatedOn, parcpere.new_Identifiant, parcfils.new_Identifiant






-----verif-----------------
select new_Identifiant,
new_identifiantproduit AS Libelle_contrat, 
CONVERT(date, new_Datededbut, 103) AS date_debut, 
CONVERT(date, new_Datedefin, 103) AS date_fin_contrat, 
new_Etatequipement,
new_motifavoir,
new_codeproduit AS reference,
CASE WHEN new_Etatequipement = '279640002' AND (new_motifavoir = '100000004' OR
new_motifavoir IS NULL) THEN 1 ELSE 0 END AS TargetEvent
from PCRM_MSCRM.dbo.new_parc
 where new_Identifiant = 45991741

                         select *
                        FROM eml.Churn_Ciel_Base