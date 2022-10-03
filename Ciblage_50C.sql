


-------Client Sage 50C avec un targetEvent sans filtre sur date ref (ramène toutes les autres informations du client)
------Filtre: client Direct 50C -------------------------
------- Client ayant entre 60 à 120 jours (2 à 4 mois) aprés début du contrat ----------------------------------------------
------- le 28/06/22 on avait  6681 lignes ----------------------------------------------------------------------------------------------
-------Date à modifier lors de chaque traitement------------------------------

/*
drop table 
*/

declare @datedebut date, @datefin date, @dateref int

SET @datedebut = '2022-02-01'
set @datefin = '2023-02-28'


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
                         parcfils.new_tacite,
						 CASE WHEN parcfils.new_Etatequipement = '279640002' AND (parcfils.new_motifavoir = '100000004' OR
                         parcfils.new_motifavoir IS NULL) THEN resil.Value ELSE null END AS MotifResil,
                         case when parcfils.new_etatequipement in(279640002) --abandonné resil
                            or parcfils.new_motifavoir in (100000004) --Refus réabonnement/
                            or parcfils.new_MotifAbandonResiliation is not null  then 1 else 0 end as TargetEventNew,
                         case when cc.Identifiant_CNT is null or cc.motif_inactivation_calc in ('UPSELL','Upsell avec changement de contrat','Erreur création parc') then 0 else 1 end as TargetEvent, ----------------------Emil & Diaraye
                         cc.Type_date_calc as MotifResil2, ----------------------Emil & Diaraye 09/07/21
                         cc.Type_date_calc2 as MotifResil_cal2, --DIA 220428
                         cc.date_fin_calc, --DIA 220428
                         cc.date_fin_calc2, --DIA 220428
                         cc.motif_abandonresiliation_calc, --DIA 220428
                         cc.motif_inactivation_calc, --DIA 220428
						 pdt_lic.new_SousTypologie, 
						 parcfils.new_parcId, 
						 a.new_ModereglementName AS ModeRegelementTier, 
						 parcpere.new_StatutoptionName, 
                         parcpere.new_statutpaiement, 
						 statut_paiement_contrat.Value AS Statut_Paiement_contrat, 
						 statut_paiement_licence.Value AS Statut_Paiement_licence, 
						--  CONVERT(date, MAX(DATEADD(mm, @dateref, parcfils.new_Datedefin)), 103) AS ReferenceDate, 
						 parcpere.new_Versionlivre AS Version, 
						 parcfils.new_Identifiant AS urnfils,
                        parcfils.new_date_inacativation,--DIA220406
                        parcfils.new_Abandonneresilie,--DIA220406
                        parcfils.new_datedAbandonResiliation,
                        case when Partenaire.AccountNumber='10456528' or Partenaire.AccountNumber is null then 'Direct' else 'Indirect'end as Channel_Product
                         ,contact.Telephone1 --diaraye--
		  ,CASE WHEN contact.Telephone1 IS NOT NULL THEN contact.Telephone1  
				WHEN contact.Telephone1 IS NULL AND contact.Telephone2 IS NOT NULL THEN contact.Telephone2
    			WHEN contact.Telephone1 IS NULL AND contact.Telephone2 IS NULL AND contact.Telephone3 IS NOT NULL THEN contact.Telephone3
				ELSE contact.MobilePhone END AS Telephone --diaraye--

-- into
FROM    PCRM_MSCRM.dbo.new_parc AS parcpere
INNER JOIN PCRM_MSCRM.dbo.Product AS pdt_lic   --identifier le produit principal 
            ON pdt_lic.ProductNumber = parcpere.new_codeproduit AND parcpere.new_template = 0
             AND parcpere.new_TiersId IS NOT NULL 
             AND  parcpere.new_parcderattachementId IS NULL  -- si null pas de parc seceondaire
             AND (parcpere.new_usage = 100000008 OR parcpere.new_usage IS NULL)  --voir stringmap
             AND pdt_lic.new_SousTypologie IN (100000000, 100000002) --Composant logiciel/SAAS
             AND pdt_lic.new_Typeduproduit IN (100000000, 279640002) --Composant/Service
             AND (pdt_lic.new_Domaine_produit_Stat NOT IN ('C3F926E4-CED9-E211-AB10-005056965CBC', '3DFA26E4-CED9-E211-AB10-005056965CBC', 'EBF926E4-CED9-E211-AB10-005056965CBC','83E8D2FC-DD5D-E311-9E34-00505696792C'/*auto entrepreneur*/,'81E8D2FC-DD5D-E311-9E34-00505696792C'/*association*/)
                 OR pdt_lic.new_Domaine_produit_Stat IS NULL)
             AND pdt_lic.new_BUReconnaissancederevenu = 100000000 -- Octave Ciel
LEFT OUTER JOIN PCRM_MSCRM.dbo.StringMapBase AS Mode_commercialisation_licence 
            ON parcpere.new_modedecommerce = Mode_commercialisation_licence.AttributeValue 
            AND Mode_commercialisation_licence.ObjectTypeCode = 10036 
            AND Mode_commercialisation_licence.AttributeName = 'new_modedecommerce' 
LEFT OUTER JOIN PCRM_MSCRM.dbo.new_configurationcameleon AS users
            ON parcpere.new_parcId = users.new_elementdeparc 
            AND users.statecode = 0 
            AND users.new_type IN (100000000, 100000001, 100000002) --Salle SAGE/Salle Externe/Intervenant SAGE
INNER JOIN PCRM_MSCRM.dbo.new_parc AS parcfils        
INNER JOIN PCRM_MSCRM.dbo.Product AS pdt_fils 
        ON parcfils.new_codeproduit = pdt_fils.ProductNumber 
        ON parcpere.new_parcId = parcfils.new_parcderattachementId 
        AND parcfils.new_parcderattachementId IS NOT NULL 
        AND parcfils.new_template = 0 
        AND parcfils.new_Datedefin BETWEEN @datedebut AND @datefin 
        AND pdt_fils.new_SousTypologie = 100000004  --Assistance
        AND  pdt_fils.new_Typeduproduit = 100000001 --Prestation
        AND parcfils.new_codeproduit NOT IN ('GCIAS0095', 'GCIAS0019','GCICL0058','GCISC0022'/*gratuit 30 jours,ciel bilan*/)
LEFT OUTER JOIN PCRM_MSCRM.dbo.StringMapBase AS Etat_PE WITH (nolock) 
        ON Etat_PE.AttributeValue = parcfils.new_Etatequipement 
        AND Etat_PE.ObjectTypeCode = 10036 
        AND  Etat_PE.AttributeName = 'new_etatequipement'
LEFT OUTER JOIN PCRM_MSCRM.dbo.StringMapBase AS Duree_engagement 
        ON parcfils.new_Dureeengagement = Duree_engagement.AttributeValue 
        AND Duree_engagement.ObjectTypeCode = 10036
        AND Duree_engagement.AttributeName = 'new_dureeengagement' 
LEFT OUTER JOIN PCRM_MSCRM.dbo.StringMapBase AS resil 
    ON parcfils.new_MotifAbandonResiliation = resil.AttributeValue 
    AND resil.ObjectTypeCode = 10036 
    AND resil.AttributeName = 'new_MotifAbandonResiliation' 
LEFT OUTER JOIN  PCRM_MSCRM.dbo.StringMapBase AS statut_paiement_licence 
    ON parcpere.new_statutpaiement = statut_paiement_licence.AttributeValue 
    AND statut_paiement_licence.ObjectTypeCode = 10036 
    AND  statut_paiement_licence.AttributeName = 'new_statutpaiement' 
LEFT OUTER JOIN PCRM_MSCRM.dbo.StringMapBase AS statut_paiement_contrat
    ON parcfils.new_statutpaiement = statut_paiement_contrat.AttributeValue 
    AND statut_paiement_contrat.ObjectTypeCode = 10036 
    AND  statut_paiement_contrat.AttributeName = 'new_statutpaiement' 
LEFT OUTER JOIN PCRM_MSCRM.dbo.Account AS a ON a.AccountId = parcpere.new_TiersId 
    AND a.new_ispartenaire = 0 
    AND a.new_Typedetiers NOT IN ('100000004', '100000000', '100000002', '279640003') --Compte Test/Filiale SAGE/Etudiant/Profession Libérale
LEFT OUTER JOIN PCRM_MSCRM.dbo.Account AS r ON r.AccountId = parcpere.new_revendeur 
LEFT OUTER JOIN PCRM_MSCRM.dbo.Account AS Partenaire WITH (nolock)
     ON Partenaire.AccountId = parcfils.new_partenaireservice 
LEFT OUTER JOIN PCRM_MSCRM.dbo.StringMapBase AS Statut_Client 
     ON a.new_StatutClient = Statut_Client.AttributeValue 
     AND Statut_Client.ObjectTypeCode = 1 
     AND Statut_Client.AttributeName = 'new_statutclient'
LEFT JOIN sales_ops.dbo.Stock_CHURN_SEGMENT_ALL cc --PIVOT_CHURN_SEGMENT_ALL cc 
    on cc.Identifiant_CNT=parcfils.new_Identifiant ---Emil & Diaraye
left  join PCRM_MSCRM.dbo.Contact AS contact ON contact.AccountId = a.AccountId AND contact.StateCode = 0  --diaraye--
		and contact.ContactId = a.PrimaryContactId   --diaraye--    
WHERE  (a.StateCode = 0) 
AND (a.new_ispartenaire = 0) 
AND (a.new_TypetiersEC IS NULL)
AND (a.new_NAFId not in (
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
) 
and pdt_lic.new_Ligne_produit_StatName ='Sage 50cloud' --end of life
and (Partenaire.AccountNumber='10456528' or Partenaire.AccountNumber is null) --and pays='FRANCE
and CONVERT(date, parcfils.new_Datededbut, 103) >= '2022-01-01'

