

--DROP TABLE SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant;

CREATE table SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant (ProductName  VARCHAR(100),
      RéférenceProduit  VARCHAR(100));



insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Comptabilité Evolution','CEVCL0001');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Gestion Commerciale Evolution','CEVCL0004');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Paie Evolution','CEVCL0008');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Solutions Evolution','CEVCL0009');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Association Evolution','CEVCL0038');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Gestion Commerciale Quantum','CIGCL0001');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Paie Quantum','CIGCL0003');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Comptabilité Millesime Unit','CMLCL0001');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Gestion Commerciale Millesime Unit','CMLCL0010');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Facturation Millesime Unit','CMLCL0016');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Immobilisations Millesime Unit','CMLCL0020');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Paie Millesime Unit','CMLCL0022');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Association Millesime Unit','CMLCL0075');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('ECF / Etats Financiers Millesime Unit','CMLCL0113');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('ECF / Etats Financiers Evolution','CMLCL0113');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Solutions Millesime Unit','CMLCL0120');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Solutions Millesime Solution','CMLCL0121');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Solutions Sage 50cloud','S5KCL0001');
insert into SALES_OPS.dbo.Churn_Model_Transco_Produit_NPS_Repondant values('Solutions Sage 50c','S5KCL0001');

select * from Churn_Model_Transco_Produit_NPS_Repondant;