SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Request_History]
(	
	@Rqid BIGINT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT SHIS.RQST_RQID AS SHIS_RQST_RQID
	      ,SHIS.RWNO AS SHIS_RWNO
	      ,dbo.GET_MTOS_U(SHIS.FROM_DATE) AS SHIS_FROM_DATE
	      ,dbo.GET_MTOS_U(SHIS.TO_DATE) AS SHIS_TO_DATE
	      ,SHID.RWNO AS SHID_RWNO
	      ,dbo.GET_MTOS_U(SHID.FROM_DATE) AS SHID_FROM_DATE
	      ,dbo.GET_MTOS_U(SHID.TO_DATE) AS SHID_TO_DATE
	      ,MSTT.CODE AS MSTT_CODE
	      ,MSTT.MSTT_DESC
	      ,SSTT.CODE AS SSTT_CODE
	      ,SSTT.SSTT_DESC
   FROM   dbo.Step_History_Summery AS SHIS,
          dbo.Step_History_Detail AS SHID,
          dbo.Main_State AS MSTT,
          dbo.Sub_State AS SSTT
   WHERE SHIS.RQST_RQID = SHID.SHIS_RQST_RQID 
     AND SHIS.RWNO = SHID.SHIS_RWNO
     AND SHIS.SSTT_MSTT_CODE = MSTT.CODE 
     AND SHIS.SSTT_MSTT_SUB_SYS = MSTT.SUB_SYS
     AND SHID.SSTT_MSTT_CODE = SSTT.MSTT_CODE 
     AND SHID.SSTT_MSTT_SUB_SYS = SSTT.MSTT_SUB_SYS 
     AND SHID.SSTT_CODE = SSTT.CODE 
     AND MSTT.CODE = SSTT.MSTT_CODE 
     AND MSTT.SUB_SYS = SSTT.MSTT_SUB_SYS
     AND ((@Rqid IS NULL) OR (SHIS.RQST_RQID = @Rqid))
)
GO
