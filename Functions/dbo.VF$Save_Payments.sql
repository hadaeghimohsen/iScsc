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
   SELECT  PYMT.TYPE AS PYMT_TYPE
         , PYMT.RECV_TYPE
         , PYMT.SUM_EXPN_PRIC
         , PYMT.SUM_EXPN_EXTR_PRCT
         , PYMT.SUM_REMN_PRIC
         , ISNULL(PYMT.SUM_RCPT_EXPN_PRIC, 0) AS SUM_RCPT_EXPN_PRIC
         , PYMT.SUM_RCPT_EXPN_EXTR_PRCT
         , PYMT.SUM_RCPT_REMN_PRIC
         , PYMT.SUM_PYMT_DSCN_DNRM
         , PYMT.CRET_BY
         , PYMT.CRET_DATE AS PYMT_CRET_DATE
         , PYMT.MDFY_BY
         , PYMT.MDFY_DATE AS PYMT_MDFY_DATE
         , PYMT.LETT_NO AS PYMT_LETT_NO
         , PYMT.LETT_DATE AS PYMT_LETT_DATE
         , RQRO.FIGH_FILE_NO
         , RQTP.RQTP_DESC
         , RQST.RQID
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
