SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE VIEW V#Transaction_Fee AS 
--SELECT * FROM iRoboTech.dbo.V#Transaction_Fee WHERE TXFE_TYPE IN ('001', '009');

CREATE VIEW [dbo].[V#Admin_Wallet] AS
SELECT * 
  FROM iRoboTech.dbo.Wallet 
 WHERE CHAT_ID in (
	   SELECT TOP 1 sr.CHAT_ID
		 FROM iRoboTech.dbo.Service_Robot sr, iRoboTech.dbo.Service_Robot_Group srg, iRoboTech.dbo.[Group] g
		WHERE sr.SERV_FILE_NO = srg.SRBT_SERV_FILE_NO
		  AND sr.ROBO_RBID = srg.SRBT_ROBO_RBID
		  AND srg.GROP_GPID = g.GPID
		  AND sr.ROBO_RBID = 401
	     AND srg.STAT = '002'
		  AND g.STAT = '002'
		  AND g.ADMN_ORGN = '002'
        AND g.GPID = 131) and srbt_robo_rbid = 401;
GO
