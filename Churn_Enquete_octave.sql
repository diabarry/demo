SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure [dbo].[Proc_Insert_CHURN_MODEL_Ciblage_CIEL_V2] as
-- proc stock à executer environ le 5eme dernier jour du mois comme ca t'arrenge :) 5, 6 ou 7 jour avant la fin du mois
-- truncate table CHURN_MODEL_CIBLAGE_V2
-- RM200914 V2 mise en place

declare @dateref int
set @dateref =-5


drop table TEMP_CHURN_ALL_BU_ABNAB
select * 
into TEMP_CHURN_ALL_BU_ABNAB

from(
select 
a.AccountId
,a.AccountNumber
,t.[Raison Sociale] [Raison_Sociale]
,t.[Channel Customer] as Channel_Customer
,a.[principal product] [Principal_product]
,a.createdon_PP
,a.Modelisation
,a.DOS_calc
,a.GDOS_Calc
,a.BDD
,a.Usage
,a.bu
,a.[ref PP] [Reference_PP]
,a.[Mode de commercialisation] [ModeComm]
,a.LPS
,a.[Niveau fonctionnel] [Niveau_fonctionnel]
,a.Version
,a.Users
,a.[ID PP] as Identifiant_PP
,a.[ID externe PP] as ID_PP
,a.NS_PP
,a.[Libellé Contrat] as [Libelle_Contrat]
,a.[Durée Engagement] as [Duree_Engagement]
,a.[Id PE] as ID_CNT
,a.Identifiant_CNT
,a.PNP
,a.PNPR
,a.[Etat contrat] as [Etat_contrat]
,a.[Date début Contrat] as [Date_debut_contrat]
,a.[Date fin contrat] as [Date_fin_contrat]
,a.[ID TAS] as AccountNumber_TAS 
,a.[RS TAS] as RaisonSociale_TAS
,a.[Channel Product] [Channel_Product]
,a.[ID Revendeur] as AccountNumber_Rev			
,a.[RS revendeur] as RaisonSociale_Rev
,a.Statut_echeance -- si date de début contrat > getdate alors anticipée /// si date de fin < getdate alors échue sinon encours
,a.Tacite
,a.Editeur_Revente Marque_blanche
,a.[Eligible Phoning] as [Eligible_Phoning]-- champ calculé : si tel <> bleu + equipement client + ... champ spécifique pour le marketing afin de restreindre aux clients éligibles
,t.SIRET_calc
,t.INSEE_E_NAF
,t.[Etat Client] as [Etat_Client]
,t.NPS
,a.[Customer Plan] as [CustomerPlan]
,CONVERT(date, DATEADD(mm, @dateref, a.[Date fin contrat]), 103) AS ReferenceDate
,case when a.[Customer Plan]=1 then 1 else 0 end as ProductPlan
FROM SALES_OPS.dbo.PIVOT_PARC_ABNAB a
left join [SALES_OPS].[dbo].[PIVOT_PARC_THIRD_PARTY] t on a.AccountId=t.AccountId
WHERE 
cast(year(DATEADD(mm, @dateref, a.[Date fin contrat])) as nvarchar)+' - '+cast(month(DATEADD(mm, @dateref, a.[Date fin contrat])) as nvarchar)= cast (YEAR(getdate()) as nvarchar)+' - '+ cast(month(getdate()) as nvarchar)
and a.Usage = 'Equipement Client'
and t.Pays in ('France','Monaco')
--and [Expert Comptable] = 'Non'
--and Partenaire = 'Non'
--and EOL_PP = 'Non' 
--and runtime = 'Non' 
and DOS not in ('ODBC/Report et Décisions','Runtime','Serveurs','ASSOCIATION','AUTO ENTREPRENEUR') 
and t.[type de tiers] not in ('Compte Test','Filiale SAGE','Profession Libérale','Particulier')

union ALL

select 
a.AccountId
,a.AccountNumber
,t.[Raison Sociale]
,t.[Channel Customer] as Channel_Customer
,a.[principal product]
,a.createdon_PP
,a.Modelisation
,a.DOS_calc
,a.GDOS_Calc
,a.BDD
,a.Usage
,a.bu
,a.[ref PP]
,a.[Mode de commercialisation]
,a.LPS
,a.[Niveau fonctionnel]
,a.Version
,a.Users
,a.[ID PP] as Identifiant_PP
,a.[ID externe PP] as ID_PP
,a.NS_PP
,a.[Libellé Contrat]
,a.[Durée Engagement]
,a.[Id PE] as ID_CNT
,a.Identifiant_CNT
,a.PNP
,a.PNPR
,a.[Etat contrat]
,a.[Date début Contrat]
,a.[Date fin contrat]
,a.[ID TAS] as AccountNumber_TAS 
,a.[RS TAS] as RaisonSociale_TAS
,a.[Channel Product]
,a.[ID Revendeur] as AccountNumber_Rev			
,a.[RS revendeur] as RaisonSociale_Rev
,a.Statut_echeance -- si date de début contrat > getdate alors anticipée /// si date de fin < getdate alors échue sinon encours
,a.Tacite
,a.Marque_blanche
,a.[Eligible Phoning] -- champ calculé : si tel <> bleu + equipement client + ... champ spécifique pour le marketing afin de restreindre aux clients éligibles
,t.SIRET_calc
,t.INSEE_E_NAF
,t.[Etat Client]
,t.NPS
,a.[Customer Plan]
,CONVERT(date, DATEADD(mm, @dateref, a.[Date fin contrat]), 103) AS ReferenceDate
,0 as ProductPlan
		
FROM SALES_OPS.dbo.PIVOT_PARC_NAB_Tiers_AB a
left join [SALES_OPS].[dbo].[PIVOT_PARC_THIRD_PARTY] t on a.AccountId=t.AccountId
WHERE 
cast(year(DATEADD(mm, @dateref, a.[Date fin contrat])) as nvarchar)+' - '+cast(month(DATEADD(mm, @dateref, a.[Date fin contrat])) as nvarchar)= cast (YEAR(getdate()) as nvarchar)+' - '+ cast(month(getdate()) as nvarchar)
and a.Usage = 'Equipement Client'
and t.Pays in ('France','Monaco')
--and [Expert Comptable] = 'Non'
--and Partenaire = 'Non'
--and EOL_PP = 'Non' 
--and runtime = 'Non' 
and DOS not in ('ODBC/Report et Décisions','Runtime','Serveurs','ASSOCIATION','AUTO ENTREPRENEUR') 
and t.[type de tiers] not in ('Compte Test','Filiale SAGE','Profession Libérale','Particulier')
) a


----------------------------------------------------------------------
drop table TEMP_Churn_1
select 
t.AccountId
,count(distinct bu) as nb_bu
,count(distinct DOS_calc) as nb_dos
,count(distinct(case when contact.contactid is not null then contact.EMailAddress1 else null end )) as nb_contact

into TEMP_Churn_1

from TEMP_CHURN_ALL_BU_ABNAB t
left join [PCRM_MSCRM].dbo.contact as contact with (nolock) on contact.ParentCustomerId = t.AccountId 
and contact.StateCode = 0
group by t.AccountId
---having count (distinct bu)>1

-----------------------------------------------------------montant _agence
drop table TEMP_Churn_2
select 
t.AccountId
,t.Identifiant_CNT
,t.Identifiant_PP
,SUM(case 
		when devis.createdon between DATEADD(MM,@dateref - 12, t.[Date_fin_contrat]) and DATEADD(mm, @dateref, t.Date_fin_contrat) 
		then devis.new_TotalHT else 0 end ) 
		as agence_1
,SUM(case 
		when devis.createdon between DATEADD(MM,@dateref - 25, t.Date_fin_contrat) and DATEADD(mm, @dateref - 13, t.Date_fin_contrat) 
		then devis.new_TotalHT else 0 end ) 
		as agence_2
,SUM(case 
		when devis.createdon between DATEADD(MM,@dateref - 38, t.Date_fin_contrat) and DATEADD(mm, @dateref - 26, t.Date_fin_contrat) 
		then devis.new_TotalHT else 0 end ) 
		as agence_3

into TEMP_Churn_2

from TEMP_CHURN_ALL_BU_ABNAB t
left join PCRM_MSCRM.[dbo].Quote as devis with(nolock) on t.accountid = devis.new_Tiersbnficiaire
WHERE devis.OwnerId not in ('1CC5E9D9-5FE6-E211-8F89-005056965CBC','1C1CAF53-60E6-E211-8F89-005056965CBC') -- diff reab vi vd
	and devis.new_TotalHT > 0
			and devis.StateCode != '3' 
			and devis.new_statut = 100000002
Group by t.AccountId
,t.Identifiant_CNT
,t.Identifiant_PP

-----------------------------------------------montant_reab------------
drop table TEMP_Churn_3
select 
t.AccountId
,t.Identifiant_CNT
,t.Identifiant_PP
,SUM(case 
		when devis.createdon between DATEADD(MM,@dateref - 12, t.Date_fin_contrat) and DATEADD(mm, @dateref, t.Date_fin_contrat) 
		then devis.new_TotalHT else 0 end ) 
		as reab_1
,SUM(case 
		when devis.createdon between DATEADD(MM,@dateref - 25, t.Date_fin_contrat) and DATEADD(mm, @dateref - 13, t.Date_fin_contrat) 
		then devis.new_TotalHT else 0 end ) 
		as reab_2
,SUM(case 
		when devis.createdon between DATEADD(MM,@dateref - 38,t.Date_fin_contrat) and DATEADD(mm, @dateref - 26,t.Date_fin_contrat) 
		then devis.new_TotalHT else 0 end ) 
		as reab_3

into TEMP_Churn_3

from TEMP_CHURN_ALL_BU_ABNAB t
left join PCRM_MSCRM.[dbo].Quote as devis with(nolock) on t.accountid = devis.new_Tiersbnficiaire
WHERE devis.OwnerId in ('1CC5E9D9-5FE6-E211-8F89-005056965CBC','1C1CAF53-60E6-E211-8F89-005056965CBC') --  reab vi vd
	and devis.new_TotalHT > 0
			and devis.StateCode != '3' 
			and devis.new_statut = 100000002
Group by t.AccountId
,t.Identifiant_CNT
,t.Identifiant_PP

---------------------------------------------nb_demande-------------------------------
drop table TEMP_Churn_4
select 
t.AccountId
,t.Identifiant_PP
,t.Identifiant_CNT
,COUNT(DISTINCT CASE WHEN d.CreatedOn BETWEEN dateadd(mm, @dateref-12, t.Date_fin_contrat) AND DATEADD(mm, @dateref, t.Date_fin_contrat) 
						THEN d.ticketnumber ELSE NULL END) AS Total_demandes_1
,COUNT(DISTINCT CASE WHEN d.CreatedOn BETWEEN dateadd(MM, @dateref-25, t.Date_fin_contrat) AND dateadd(MM, @dateref-13, DATEADD(mm, @dateref, t.Date_fin_contrat)) 
                         THEN d.ticketnumber ELSE NULL END) AS Total_demandes_2
,COUNT(DISTINCT CASE WHEN d.CreatedOn BETWEEN dateadd(MM, @dateref-38, t.Date_fin_contrat) AND dateadd(MM, @dateref-26, DATEADD(mm, @dateref, t.Date_fin_contrat)) 
                         THEN d.ticketnumber ELSE NULL END) AS Total_demandes_3

into TEMP_Churn_4

from TEMP_CHURN_ALL_BU_ABNAB t
left join PCRM_MSCRM.dbo.Incident d ON t.AccountId = d.new_clientfinalid 
JOIN PCRM_MSCRM.dbo.new_typededemande td 
                         ON td.new_typededemandeId = d.new_TypeId 
                         AND td.new_Typedeservice = '100000004'
group by 
t.AccountId
,t.Identifiant_PP
,t.Identifiant_CNT


-------------------------------------------------------------
drop table TEMP_Churn_5
select distinct
t.accountid,
parcfils.new_Identifiant,
t.identifiant_cnt,
t.identifiant_PP,
CASE WHEN parcfils.new_Etatequipement = '279640002' AND 
			(parcfils.new_motifavoir = '100000004' OR parcfils.new_motifavoir IS NULL) THEN 1 ELSE 0 END AS TargetEvent,
CASE WHEN parcfils.new_Etatequipement = '279640002' AND 
			(parcfils.new_motifavoir = '100000004' OR parcfils.new_motifavoir IS NULL) THEN MotifResil.Value ELSE null END AS MotifResil

into TEMP_Churn_5
from     

PCRM_MSCRM.dbo.new_parc AS parcpere 
INNER JOIN PCRM_MSCRM.dbo.Product AS pdt_lic 
				ON pdt_lic.ProductNumber = parcpere.new_codeproduit 
				AND parcpere.new_template = 0 
				AND parcpere.new_TiersId IS NOT NULL 
				AND  parcpere.new_parcderattachementId IS NULL 
				AND (parcpere.new_usage = 100000008 OR
                         parcpere.new_usage IS NULL) 
				AND pdt_lic.new_SousTypologie IN (100000000, 100000002) 
				AND pdt_lic.new_Typeduproduit IN (100000000, 279640002) 
		
 INNER JOIN
                PCRM_MSCRM.dbo.new_parc AS parcfils 
INNER JOIN
                PCRM_MSCRM.dbo.Product AS pdt_fils 
				ON parcfils.new_codeproduit = pdt_fils.ProductNumber 
				ON parcpere.new_parcId = parcfils.new_parcderattachementId 
				AND parcfils.new_parcderattachementId IS NOT NULL 
				AND parcfils.new_template = 0 
				AND pdt_fils.new_SousTypologie = 100000004 
				AND pdt_fils.new_Typeduproduit = 100000001 
LEFT JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS MotifResil 
						 ON parcfils.new_MotifAbandonResiliation = MotifResil.AttributeValue 
						 AND MotifResil.ObjectTypeCode = 10036 AND 
                         MotifResil.AttributeName = 'new_MotifAbandonResiliation' 
LEFT JOIN
                         PCRM_MSCRM.dbo.StringMapBase AS MotifInact 
						 ON parcfils.new_motifavoir = MotifInact.AttributeValue 
						 AND MotifInact.ObjectTypeCode = 10036 AND 
                         MotifInact.AttributeName = 'new_motifavoir' 

join TEMP_CHURN_ALL_BU_ABNAB t on t.Identifiant_CNT=parcfils.new_Identifiant


---------------------------------------------nb_produit_ciel-------------------------------
drop table TEMP_Churn_6_Ciel
select 
t.AccountId
,COUNT(distinct produit.ProductNumber) as nb_produit_last_year

into TEMP_Churn_6_Ciel

from 
[PCRM_MSCRM].dbo.new_parc as parcpere											-- Table �l�ment de parc
inner join  PCRM_MSCRM.dbo.Product          as pdt_lic							-- Table produit (jointure stricte)
        on pdt_lic.productnumber    = parcpere.new_codeproduit


--and parcpere.statecode                      = 0                                 -- Licence actif
and parcpere.new_template                   = 0                                 -- Template = Non
and parcpere.new_numero_serie               is not null                         -- le num�ro de s�rie n'est pas vide
and parcpere.new_numero_serie               <> 'EN ATTENTE DE REF'              -- le num�ro de s�rie n'est pas "EN ATTENTE DE REF"
and parcpere.new_tiersid                    is not null                         -- le num�ro de Tiers n'est pas vide
--and parcpere.new_etatequipement             in (279640001, 279640000)           -- l'�tat de l'�quipement est 'Activ�' ou 'Vendu'
and parcpere.new_parcderattachementid       is null                             -- Non rattach� � un autre produit
and (   parcpere.new_usage                  = 100000008                         -- Equipement Client ou non remplis
    or  parcpere.new_usage                  is  null
    )

and pdt_lic.new_soustypologie               in (100000000, 100000002)           -- le sous-type est "composant logiciel" ou "SAAS"
and pdt_lic.new_typeduproduit               in (100000000, 279640002)           -- le type est "composant" ou "service"

								---------------- exclusion DOS  -------------------

and (   pdt_lic.new_Domaine_produit_Stat    not in  ('C3F926E4-CED9-E211-AB10-005056965CBC'  -- 'ODBC/Report et D�cisions'
                                                    ,'3DFA26E4-CED9-E211-AB10-005056965CBC'	 -- 'Runtime'
                                                    ,'EBF926E4-CED9-E211-AB10-005056965CBC') -- 'Serveurs'
                                                    
										or  pdt_lic.new_Domaine_produit_Stat    is  null									    -- Ou est non renseign�
    )

and pdt_lic.new_BUReconnaissancederevenu = 100000000

  -- Bloc Jointure Contrat --
join   PCRM_MSCRM.dbo.new_parc             as parcfils
inner join  PCRM_MSCRM.dbo.Product              as pdt_fils
        on parcfils.new_codeproduit = pdt_fils.productnumber
        on parcpere.new_parcid      = parcfils.new_parcderattachementid

                                -- Bloc Def Contrat --
--and parcfils.statecode                      = 0                                 -- Contrat actif (soit le dernier contrat en date)
and parcfils.new_parcderattachementid       is not null                         -- Contrat rattach� � une licence
and parcfils.new_template                   = 0                                 -- Template = Non
--and parcfils.new_datedefin				between @datedebut and @datefin                    -- les abonn�s en cours
--and parcfils.new_datededbut                 <= SYSDATETIME()
--and parcfils.new_etatequipement             in (279640001, 279640000)           -- l'�tat de l'�quipement est 'Activ�' ou 'Vendu'
and pdt_fils.new_soustypologie              = 100000004                         -- le sous-type est "assistance"    
and pdt_fils.new_typeduproduit              = 100000001                         -- le type est "prestation"

and parcfils.new_codeproduit not in (
'GCIAS0095'
,'GCIAS0019' 
)

join TEMP_CHURN_ALL_BU_ABNAB t on t.AccountId=parcpere.new_TiersId
join PCRM_MSCRM.[dbo].Quote as devis with(nolock) on t.accountid = devis.new_Tiersbnficiaire
join PCRM_MSCRM.dbo.QuoteDetail	as Quote_Detail	WITH (nolock) ON	Quote_Detail.quoteid	= devis.quoteid  
join [PCRM_MSCRM].dbo.product as produit on produit.productid = Quote_Detail.productid 
and produit.new_soustypologie in (100000000, 100000002)
and produit.new_Produitprincipal = 1

where 
devis.createdon between DATEADD(mm, @dateref - 12, parcfils.new_Datedefin) and DATEADD(mm, @dateref, parcfils.new_Datedefin)
and	devis.OwnerId not in ('1CC5E9D9-5FE6-E211-8F89-005056965CBC','1C1CAF53-60E6-E211-8F89-005056965CBC') -- diff reab vi vd
	and devis.new_TotalHT > 0
			and devis.StateCode != '3' 
			and devis.new_statut = 100000002
			and Quote_Detail.new_casdevente = 100000000


group by t.AccountId




-----------------------------------------------age-----------------------------
drop table TEMP_Churn_7_Ciel
select distinct
t.AccountId
,MIN(parcpere.new_Datedevente) as first_purchasing_date
,MIN(case when pdt_lic.new_BUReconnaissancederevenu = 100000000 then parcpere.new_Datedevente else null end) as first_purchasing_date_bu
,DATEDIFF(YYYY,MIN(parcpere.new_Datedevente),getdate()) as age_of_customer

into TEMP_Churn_7_Ciel

from 
[PCRM_MSCRM].dbo.new_parc as parcpere											-- Table �l�ment de parc
inner join  PCRM_MSCRM.dbo.Product          as pdt_lic							-- Table produit (jointure stricte)
        on pdt_lic.productnumber    = parcpere.new_codeproduit


--and parcpere.statecode                      = 0                                 -- Licence actif
and parcpere.new_template                   = 0                                 -- Template = Non
and parcpere.new_numero_serie               is not null                         -- le num�ro de s�rie n'est pas vide
and parcpere.new_numero_serie               <> 'EN ATTENTE DE REF'              -- le num�ro de s�rie n'est pas "EN ATTENTE DE REF"
and parcpere.new_tiersid                    is not null                         -- le num�ro de Tiers n'est pas vide
--and parcpere.new_etatequipement             in (279640001, 279640000)           -- l'�tat de l'�quipement est 'Activ�' ou 'Vendu'
and parcpere.new_parcderattachementid       is null                             -- Non rattach� � un autre produit
and (   parcpere.new_usage                  = 100000008                         -- Equipement Client ou non remplis
    or  parcpere.new_usage                  is  null
    )

and pdt_lic.new_soustypologie               in (100000000, 100000002)           -- le sous-type est "composant logiciel" ou "SAAS"
and pdt_lic.new_typeduproduit               in (100000000, 279640002)           -- le type est "composant" ou "service"

								---------------- exclusion DOS  -------------------

and (   pdt_lic.new_Domaine_produit_Stat    not in  ('C3F926E4-CED9-E211-AB10-005056965CBC'  -- 'ODBC/Report et D�cisions'
                                                    ,'3DFA26E4-CED9-E211-AB10-005056965CBC'	 -- 'Runtime'
                                                    ,'EBF926E4-CED9-E211-AB10-005056965CBC') -- 'Serveurs'
                                                    
										or  pdt_lic.new_Domaine_produit_Stat    is  null									    -- Ou est non renseign�
    )

join TEMP_CHURN_ALL_BU_ABNAB t on t.AccountId=parcpere.new_TiersId


group by t.AccountId






-------------------------------------------------------------------------
-------------------------------------------------------------------------





















--------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-----------------------------------On plan PME-----------------------------------------
--------------------------------TEMP_Churn_4_PME------------------
--(4007 rows affected) 
--	(42388 rows affected) 
	--(6092 rows affected) 
--	Total execution time: 00:04:54.518
drop table TEMP_Churn_6_PME

select 
t.AccountId
,COUNT(distinct produit.ProductNumber) as nb_produit_last_year

into TEMP_Churn_6_PME

from [PCRM_MSCRM].dbo.new_parc as parcpere
inner join  PCRM_MSCRM.dbo.Product as pdt_lic
        on pdt_lic.productnumber    = parcpere.new_codeproduit
--and parcpere.statecode                      = 0                                 -- Licence 
and parcpere.new_template                   = 0                                 -- Template = Non
and parcpere.new_numero_serie               is not null                         -- le num�ro de s�rie n'est pas vide
and parcpere.new_numero_serie               <> 'EN ATTENTE DE REF'              -- le num�ro de s�rie n'est pas "EN ATTENTE DE REF"
and parcpere.new_tiersid                    is not null                         -- le num�ro de Tiers n'est pas vide
--and parcpere.new_etatequipement             in (279640001, 279640000)           -- l'�tat de l'�quipement est 'Activ�' ou 'Vendu'
and parcpere.new_parcderattachementid       is null                             -- Non rattach� � un autre produit
and (   parcpere.new_usage                  = 100000008                         -- Equipement Client ou non remplis
    or  parcpere.new_usage                  is  null
    )
and pdt_lic.new_soustypologie               in (100000000, 100000002)           -- le sous-type est "composant logiciel" ou "SAAS"
and pdt_lic.new_typeduproduit               in (100000000, 279640002)           -- le type est "composant" ou "service"

								---------------- exclusion DOS  -------------------

and (   pdt_lic.new_Domaine_produit_Stat    not in  ('C3F926E4-CED9-E211-AB10-005056965CBC'  -- 'ODBC/Report et D�cisions'
                                                    ,'3DFA26E4-CED9-E211-AB10-005056965CBC'	 -- 'Runtime'
                                                    ,'EBF926E4-CED9-E211-AB10-005056965CBC') -- 'Serveurs'
                                                    
										or  pdt_lic.new_Domaine_produit_Stat    is  null									    -- Ou est non renseign�
    )
and pdt_lic.new_BUReconnaissancederevenu = 100000002

join   PCRM_MSCRM.dbo.new_parc as parcfils
join  PCRM_MSCRM.dbo.Product as pdt_fils
        on parcfils.new_codeproduit = pdt_fils.productnumber
        on parcpere.new_parcid      = parcfils.new_parcderattachementid
--and parcfils.statecode                      = 0                                 -- Contrat actif (soit le dernier contrat en date)
and parcfils.new_parcderattachementid       is not null                         -- Contrat rattach� � une licence
and parcfils.new_template                   = 0                                 -- Template = Non
--and parcfils.new_etatequipement             in (279640001, 279640000)           -- l'�tat de l'�quipement est 'Activ�' ou 'Vendu'
and pdt_fils.new_soustypologie              = 100000004                         -- le sous-type est "assistance"    
and pdt_fils.new_typeduproduit              = 100000001                         -- le type est "prestation"

and parcfils.new_codeproduit not in ('GCIAS0095','GCIAS0019' )

join TEMP_CHURN_ALL_BU_ABNAB t on t.AccountId=parcpere.new_TiersId

join PCRM_MSCRM.[dbo].Quote as devis with(nolock) on t.accountid = devis.new_Tiersbnficiaire
join PCRM_MSCRM.dbo.QuoteDetail	as Quote_Detail	WITH (nolock) ON Quote_Detail.quoteid = devis.quoteid  
join [PCRM_MSCRM].dbo.product as produit on produit.productid = Quote_Detail.productid 
and produit.new_soustypologie in (100000000, 100000002)
and produit.new_Produitprincipal = 1


where 
devis.createdon between DATEADD(mm, @dateref - 12, parcfils.new_Datedefin) and DATEADD(mm, @dateref, parcfils.new_Datedefin)
and	devis.OwnerId not in ('1CC5E9D9-5FE6-E211-8F89-005056965CBC','1C1CAF53-60E6-E211-8F89-005056965CBC') -- diff reab vi vd
	and devis.new_TotalHT > 0
			and devis.StateCode != '3' 
			and devis.new_statut = 100000002
			and Quote_Detail.new_casdevente = 100000000


group by t.AccountId




-----------------------------------------------age-----------------------------
drop table TEMP_Churn_7_PME
select distinct

t.AccountId
,MIN(parcpere.new_Datedevente) as first_purchasing_date
,MIN(case when pdt_lic.new_BUReconnaissancederevenu = 100000002 then parcpere.new_Datedevente else null end) as first_purchasing_date_bu
,DATEDIFF(YYYY,MIN(parcpere.new_Datedevente),getdate()) as age_of_customer

into TEMP_Churn_7_PME

from [PCRM_MSCRM].dbo.new_parc as parcpere											-- Table �l�ment de parc
inner join  PCRM_MSCRM.dbo.Product as pdt_lic							-- Table produit (jointure stricte)
        on pdt_lic.productnumber = parcpere.new_codeproduit

--and parcpere.statecode                      = 0                                 -- Licence actif
and parcpere.new_template                   = 0                                 -- Template = Non
and parcpere.new_numero_serie               is not null                         -- le num�ro de s�rie n'est pas vide
and parcpere.new_numero_serie               <> 'EN ATTENTE DE REF'              -- le num�ro de s�rie n'est pas "EN ATTENTE DE REF"
and parcpere.new_tiersid                    is not null                         -- le num�ro de Tiers n'est pas vide
--and parcpere.new_etatequipement             in (279640001, 279640000)           -- l'�tat de l'�quipement est 'Activ�' ou 'Vendu'
and parcpere.new_parcderattachementid       is null                             -- Non rattach� � un autre produit
and (   parcpere.new_usage                  = 100000008                         -- Equipement Client ou non remplis
    or  parcpere.new_usage                  is  null
    )

and pdt_lic.new_soustypologie               in (100000000, 100000002)           -- le sous-type est "composant logiciel" ou "SAAS"
and pdt_lic.new_typeduproduit               in (100000000, 279640002)           -- le type est "composant" ou "service"

								---------------- exclusion DOS  -------------------

and (   pdt_lic.new_Domaine_produit_Stat    not in  ('C3F926E4-CED9-E211-AB10-005056965CBC'  -- 'ODBC/Report et D�cisions'
                                                    ,'3DFA26E4-CED9-E211-AB10-005056965CBC'	 -- 'Runtime'
                                                    ,'EBF926E4-CED9-E211-AB10-005056965CBC') -- 'Serveurs'
                                                    
										or  pdt_lic.new_Domaine_produit_Stat    is  null									    -- Ou est non renseign�
    )

join TEMP_CHURN_ALL_BU_ABNAB t on t.AccountId=parcpere.new_TiersId

group by t.AccountId


drop table TEMP_CHURN_Equete_Chaud
select distinct

a.accountid
,new_date_enquete
,new_note_enquete
,new_ces
,new_fcr
,case when new_ces='Extrèmement faible (1)' then 1 
when new_ces='Très faible (2)' then 2 
when new_ces='Faible (3)' then 3 
when new_ces='Moyen (4)' then 4 
when new_ces='Elevé (5)' then 5 
when new_ces='Très élevé (6)' then 6 
when new_ces='Extrêmement élevé (7)' then 7 else new_ces end as new_ces_score
into TEMP_CHURN_Equete_Chaud
from pcrm_mscrm.dbo.account a
inner join TEMP_CHURN_ALL_BU_ABNAB t on t.accountid=a.accountid

---------------------------------------------------------------
---------------------------------------------------------------
-----------------
Insert into CHURN_MODEL_CIBLAGE_V2
(
[AccountId]
      ,[AccountNumber]
      ,[Raison_Sociale]
      ,[Channel_Customer]
      ,[Principal_product]
      ,[createdon_PP]
      ,[Modelisation]
      ,[DOS_calc]
      ,[GDOS_Calc]
      ,[BDD]
      ,[Usage]
      ,[bu]
      ,[Reference_PP]
      ,[ModeComm]
      ,[LPS]
      ,[Niveau_fonctionnel]
      ,[Version]
      ,[Users]
      ,[Identifiant_PP]
      ,[ID_PP]
      ,[NS_PP]
      ,[Libelle_Contrat]
      ,[Duree_Engagement]
      ,[ID_CNT]
      ,[Identifiant_CNT]
      ,[PNP]
      ,[PNPR]
      ,[Etat_contrat]
      ,[Date_debut_contrat]
      ,[Date_fin_contrat]
      ,[AccountNumber_TAS]
      ,[RaisonSociale_TAS]
      ,[Channel_Product]
      ,[AccountNumber_Rev]
      ,[RaisonSociale_Rev]
      ,[Statut_echeance]
      ,[Tacite]
      ,[Marque_blanche]
      ,[Eligible_Phoning]
      ,[SIRET_calc]
      ,[INSEE_E_NAF]
      ,[Etat_Client]
      ,[NPS]
      ,[CustomerPlan]
      ,[ReferenceDate]
      ,[ProductPlan]
      ,[nb_bu]
      ,[nb_dos]
      ,[nb_contact]
      ,[agence_1]
      ,[agence_2]
      ,[agence_3]
      ,[reab_1]
      ,[reab_2]
      ,[reab_3]
      ,[Total_demandes_1]
      ,[Total_demandes_2]
      ,[Total_demandes_3]
      ,[TargetEvent]
      ,[MotifResil]
      ,[nb_produit_last_year]
      ,[first_purchasing_date]
      ,[first_purchasing_date_bu]
      ,[age_of_customer]
      ,[new_ces]
      ,[new_ces_score]
      ,[new_date_enquete]
      ,[new_fcr]
      ,[new_note_enquete]
      ,[CIBLE]
      ,[periode]
      ,[date_insert]
)
select 
a.*
,b.nb_bu
,b.nb_dos
,b.nb_contact
,c.agence_1
,c.agence_2
,c.agence_3
,d.reab_1
,d.reab_2
,d.reab_3
,e.Total_demandes_1
,e.Total_demandes_2
,e.Total_demandes_3
,f.TargetEvent
,f.MotifResil
,i.nb_produit_last_year
,j.first_purchasing_date
,j.first_purchasing_date_bu
,j.age_of_customer
,k.new_ces
,K.new_ces_score
,K.new_date_enquete
,K.new_fcr
,K.new_note_enquete
,'PME' CIBLE
,cast(year(DATEADD(mm, -@dateref, getdate())) as nvarchar)+' - '+cast(month(DATEADD(mm, -@dateref, getdate())) as nvarchar) periode 
, getdate() date_insert 
--into CHURN_MODEL_CIBLAGE_V2
from TEMP_CHURN_ALL_BU_ABNAB a
left join TEMP_Churn_1 b on b.accountid=a.AccountId
left join TEMP_Churn_2 c on c.Identifiant_CNT=a.Identifiant_CNT
left join TEMP_Churn_3 d on d.Identifiant_CNT=a.Identifiant_CNT
left join TEMP_Churn_4 e on e.Identifiant_CNT=a.Identifiant_CNT
left join TEMP_Churn_5 f on f.Identifiant_CNT=a.Identifiant_CNT
left join TEMP_Churn_6_pme i on i.accountid=a.AccountId
left join TEMP_Churn_7_pme j on j.accountid=a.AccountId
left join TEMP_CHURN_Equete_Chaud k on K.AccountId = A.AccountId
where  a.[ProductPlan]=1 
and a.bu='PME' 


----------------------------------CHURN_MODEL_CIBLAGE_V2-----------------------
-----------------
--select * from CHURN_MODEL_CIBLAGE_V2
--update CHURN_MODEL_CIBLAGE_V2 set Tacite = case when tacite = 1 then 'Oui' else 'Non' end where tacite in (1,0)

--select * into CHURN_MODEL_CIBLAGE_V2_bck_RM201109 from CHURN_MODEL_CIBLAGE_V2
-- alter table CHURN_MODEL_CIBLAGE_V2 alter column cible nvarchar(10)
--alter table CHURN_MODEL_CIBLAGE_V2 alter column tacite nvarchar(10)
Insert into CHURN_MODEL_CIBLAGE_V2
(
[AccountId]
      ,[AccountNumber]
      ,[Raison_Sociale]
      ,[Channel_Customer]
      ,[Principal_product]
      ,[createdon_PP]
      ,[Modelisation]
      ,[DOS_calc]
      ,[GDOS_Calc]
      ,[BDD]
      ,[Usage]
      ,[bu]
      ,[Reference_PP]
      ,[ModeComm]
      ,[LPS]
      ,[Niveau_fonctionnel]
      ,[Version]
      ,[Users]
      ,[Identifiant_PP]
      ,[ID_PP]
      ,[NS_PP]
      ,[Libelle_Contrat]
      ,[Duree_Engagement]
      ,[ID_CNT]
      ,[Identifiant_CNT]
      ,[PNP]
      ,[PNPR]
      ,[Etat_contrat]
      ,[Date_debut_contrat]
      ,[Date_fin_contrat]
      ,[AccountNumber_TAS]
      ,[RaisonSociale_TAS]
      ,[Channel_Product]
      ,[AccountNumber_Rev]
      ,[RaisonSociale_Rev]
      ,[Statut_echeance]
      ,[Tacite]
      ,[Marque_blanche]
      ,[Eligible_Phoning]
      ,[SIRET_calc]
      ,[INSEE_E_NAF]
      ,[Etat_Client]
      ,[NPS]
      ,[CustomerPlan]
      ,[ReferenceDate]
      ,[ProductPlan]
      ,[nb_bu]
      ,[nb_dos]
      ,[nb_contact]
      ,[agence_1]
      ,[agence_2]
      ,[agence_3]
      ,[reab_1]
      ,[reab_2]
      ,[reab_3]
      ,[Total_demandes_1]
      ,[Total_demandes_2]
      ,[Total_demandes_3]
      ,[TargetEvent]
      ,[MotifResil]
      ,[nb_produit_last_year]
      ,[first_purchasing_date]
      ,[first_purchasing_date_bu]
      ,[age_of_customer]
      ,[new_ces]
      ,[new_ces_score]
      ,[new_date_enquete]
      ,[new_fcr]
      ,[new_note_enquete]
      ,[CIBLE]
      ,[periode]
      ,[date_insert]
)
select 
a.*
,b.nb_bu
,b.nb_dos
,b.nb_contact
,c.agence_1
,c.agence_2
,c.agence_3
,d.reab_1
,d.reab_2
,d.reab_3
,e.Total_demandes_1
,e.Total_demandes_2
,e.Total_demandes_3
,f.TargetEvent
,f.MotifResil
,i.nb_produit_last_year
,j.first_purchasing_date
,j.first_purchasing_date_bu
,j.age_of_customer
,k.new_ces
,K.new_ces_score
,K.new_date_enquete
,K.new_fcr
,K.new_note_enquete
,'CIEL' CIBLE
,cast(year(DATEADD(mm, -@dateref, getdate())) as nvarchar)+' - '+cast(month(DATEADD(mm, -@dateref, getdate())) as nvarchar) periode 
, getdate() date_insert 
--into CHURN_MODEL_CIBLAGE_V2_CIEL
from TEMP_CHURN_ALL_BU_ABNAB a
left join TEMP_Churn_1 b on b.accountid=a.AccountId
left join TEMP_Churn_2 c on c.Identifiant_CNT=a.Identifiant_CNT
left join TEMP_Churn_3 d on d.Identifiant_CNT=a.Identifiant_CNT
left join TEMP_Churn_4 e on e.Identifiant_CNT=a.Identifiant_CNT
left join TEMP_Churn_5 f on f.Identifiant_CNT=a.Identifiant_CNT
left join TEMP_Churn_6_Ciel i on i.accountid=a.AccountId
left join TEMP_Churn_7_Ciel j on j.accountid=a.AccountId
left join TEMP_CHURN_Equete_Chaud k on K.AccountId = A.AccountId
where  a.[ProductPlan]=1 
and a.bu='Ciel' 
and a.INSEE_E_NAF not in ('69.20Z','84.11Z','84.12Z','84.13Z','84.21Z',
                          '84.22Z','84.23Z','84.24Z','84.25Z','84.30A',
                          '84.30B','84.30C','85.10Z','85.20Z','85.31Z',
                          '85.32Z','85.41Z','85.42Z','85.51Z','85.52Z',
                          '85.53Z','85.59A','85.59B','85.60Z','86.10Z',
                          '86.21Z','86.22A','86.22B','86.22C','86.23Z',
                          '86.90A','86.90B','86.90C','86.90D','86.90E',
                          '86.90F','87.10A','87.10B','87.10C','87.20A',
                          '87.20B','87.30A','87.30B','87.90A','87.90B')
GO

--drop table SALES_OPS.dbo.CHURN_Equete_Chaud
----Enquete octave-----
select distinct

a.accountid
,a.AccountNumber
,new_date_enquete
,new_note_enquete
,new_ces
,new_fcr
,case when new_ces='Extrèmement faible (1)' then 1 
when new_ces='Très faible (2)' then 2 
when new_ces='Faible (3)' then 3 
when new_ces='Moyen (4)' then 4 
when new_ces='Elevé (5)' then 5 
when new_ces='Très élevé (6)' then 6 
when new_ces='Extrêmement élevé (7)' then 7 else new_ces end as new_ces_score
into SALES_OPS.dbo.CHURN_Equete_Chaud
from pcrm_mscrm.dbo.account a
inner join SALES_OPS.dbo.Churn_Ciel_entrainement_FY20 t on t.accountid=a.accountid

