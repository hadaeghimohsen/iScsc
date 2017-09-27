SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$InsuranceFighter]
(	
	@CrntDate DATE,
	@FighWho  SMALLINT -- (0: All), (1: Contain)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT F.FILE_NO, 
	       F.NAME_DNRM,
	       F.INSR_DATE_DNRM,
	       F.INSR_NUMB_DNRM,
	       DATEDIFF(DAY, F.INSR_DATE_DNRM, COALESCE(@CrntDate, GETDATE())) * -1 AS REMN_CRNT_DATE,
	       DATEDIFF(DAY, F.INSR_DATE_DNRM, GETDATE()) * -1 AS REMN_SRVR_DATE
	  FROM Fighter F, Fighter_Public P, V#URFGA UR, V#UCFGA UC
	 WHERE F.FILE_NO = P.FIGH_FILE_NO
	   AND F.FGPB_RWNO_DNRM = P.RWNO
	   AND UPPER(SUSER_NAME()) = UR.SYS_USER 
	   AND UR.REGN_PRVN_CODE = F.REGN_PRVN_CODE 
	   AND UR.REGN_CODE = F.REGN_CODE
	   AND UR.SYS_USER = UC.SYS_USER 
	   AND UC.CLUB_CODE = F.CLUB_CODE_DNRM 
	   AND P.RECT_CODE = '004'
	   AND F.CONF_STAT = '002'
	   AND (@FighWho = 0 OR (P.INSR_DATE < COALESCE(@CrntDate, GETDATE())))
	                       
)
GO
