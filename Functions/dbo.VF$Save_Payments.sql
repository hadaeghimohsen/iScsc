SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Save_Payments]
(	
	@Rqid     BIGINT,
	@FileNo   BIGINT
)
RETURNS TABLE 
AS
RETURN 
(
   SELECT  PYMT.[YEAR]
         , PYMT.[CYCL]
         , PYMT.PYMT_NO
         , PYMT.PYMT_PYMT_NO
         , PYMT.TYPE 
         , PYMT.PYMT_TYPE
         , PYMT.PYMT_STAT
         , PYMT.RECV_TYPE
         , CASE PYMT.PYMT_STAT WHEN '001' THEN PYMT.SUM_EXPN_PRIC ELSE 0 END AS SUM_EXPN_PRIC
         , CASE PYMT.PYMT_STAT WHEN '001' THEN PYMT.SUM_EXPN_EXTR_PRCT ELSE 0 END AS SUM_EXPN_EXTR_PRCT
         , CASE PYMT.PYMT_STAT WHEN '001' THEN PYMT.SUM_REMN_PRIC ELSE 0 END AS SUM_REMN_PRIC
         , CASE PYMT.PYMT_STAT WHEN '001' THEN ISNULL(PYMT.SUM_RCPT_EXPN_PRIC, 0) ELSE 0 END AS SUM_RCPT_EXPN_PRIC
         , CASE PYMT.PYMT_STAT WHEN '001' THEN PYMT.SUM_RCPT_EXPN_EXTR_PRCT ELSE 0 END AS SUM_RCPT_EXPN_EXTR_PRCT
         , CASE PYMT.PYMT_STAT WHEN '001' THEN PYMT.SUM_RCPT_REMN_PRIC ELSE 0 END AS SUM_RCPT_REMN_PRIC
         , CASE PYMT.PYMT_STAT WHEN '001' THEN PYMT.SUM_PYMT_DSCN_DNRM ELSE 0 END AS SUM_PYMT_DSCN_DNRM
         , PYMT.CRET_BY
         , PYMT.CRET_DATE AS PYMT_CRET_DATE
         , PYMT.MDFY_BY
         , PYMT.MDFY_DATE AS PYMT_MDFY_DATE
         , PYMT.LETT_NO AS PYMT_LETT_NO
         , PYMT.LETT_DATE AS PYMT_LETT_DATE
         , RQRO.FIGH_FILE_NO
         , RQTP.RQTP_DESC
         , RQST.RQID
         , RQST.RQTP_CODE
         , PYMT.CASH_CODE
         , PYMT.AMNT_UNIT_TYPE_DNRM
         , PYMT.REGL_YEAR_DNRM
         , PYMT.REGL_CODE_DNRM         
     FROM dbo.Request_Type AS RQTP,
          dbo.Request AS RQST,
          dbo.Payment AS PYMT,
          dbo.Request_Row AS RQRO
    WHERE RQTP.CODE = Rqst.RQTP_CODE
      AND RQST.RQID = RQRO.RQST_RQID      
      AND RQST.RQID = PYMT.RQST_RQID
      AND ((@Rqid IS NULL) OR (PYMT.RQST_RQID = @Rqid))
      AND ((@FileNo IS NULL) OR (RQRO.FIGH_FILE_NO = @FileNo))
      AND RQST.RQST_STAT IN ('002')
)
GO
