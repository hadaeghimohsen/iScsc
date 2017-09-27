SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Payments]
(	
	@Rqid     BIGINT,
	@RqroRwno SMALLINT,
	@FileNo   BIGINT,
	@Type     VARCHAR(3),
	@PayStat  VARCHAR(3),
	@Qnty     SMALLINT,
	@DocmNumb BIGINT
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
         , PYMT.SUM_RCPT_EXPN_PRIC
         , PYMT.SUM_RCPT_EXPN_EXTR_PRCT
         , PYMT.SUM_RCPT_REMN_PRIC
         , PYMT.SUM_PYMT_DSCN_DNRM
         , PYMT.CRET_BY
         , dbo.GET_MTOS_U(PYMT.CRET_DATE) AS PYMT_CRET_DATE
         , PYMT.MDFY_BY
         , dbo.GET_MTOS_U(PYMT.MDFY_DATE) AS PYMT_MDFY_DATE
         , PYMT.LETT_NO AS PYMT_LETT_NO
         , dbo.GET_MTOS_U(PYMT.LETT_DATE) AS PYMT_LETT_DATE
         , EXPN.EXPN_DESC
         , EXPN.ADD_QUTS
         , RQRO.FIGH_FILE_NO
         , PYDT.PYMT_RQST_RQID
         , PYDT.RQRO_RWNO
         , PYDT.PAY_STAT
         , PYDT.QNTY
         , PYDT.DOCM_NUMB
         , dbo.GET_MTOS_U(PYDT.ISSU_DATE) AS ISSU_DATE
         , PYDT.EXPN_PRIC
         , PYDT.EXPN_EXTR_PRCT
         , PYDT.REMN_PRIC
         , PYDT.CRET_BY AS PYDT_CRET_BY
         , dbo.GET_MTOS_U(PYDT.CRET_DATE) AS PYDT_CRET_DATE
         , PYDT.MDFY_BY AS PYDT_MDFY_BY
         , dbo.GET_MTOS_U(PYDT.MDFY_DATE) AS PYDT_MDFY_DATE
         , PYDT.RECV_LETT_NO
         , dbo.GET_MTOS_U(PYDT.RECV_LETT_DATE) AS RECV_LETT_DATE
         , RQTP.RQTP_DESC
     FROM dbo.Request_Type AS RQTP,
          dbo.Request AS RQST,
          dbo.Payment AS PYMT,
          dbo.Payment_Detail AS PYDT,
          dbo.Request_Row AS RQRO,
          dbo.Expense AS EXPN  
    WHERE RQTP.CODE = Rqst.RQTP_CODE
      AND RQST.RQID = RQRO.RQST_RQID      
      AND RQST.RQID = PYMT.RQST_RQID
      AND PYMT.RQST_RQID      = PYDT.PYMT_RQST_RQID
      AND PYDT.PYMT_RQST_RQID = RQRO.RQST_RQID
      AND PYDT.RQRO_RWNO      = RQRO.RWNO
      AND PYDT.EXPN_CODE      = EXPN.CODE
      AND ((@Rqid IS NULL) OR (PYMT.RQST_RQID = @Rqid))
      AND ((@RqroRwno IS NULL) OR (PYDT.RQRO_RWNO = @RqroRwno))
      AND ((@FileNo IS NULL) OR (RQRO.FIGH_FILE_NO = @FileNo))
      AND ((@Type IS NULL) OR (PYMT.TYPE = @Type))
      AND ((@PayStat IS NULL) OR (PYDT.PAY_STAT = @PayStat))
      AND ((@Qnty IS NULL) OR (PYDT.QNTY = @Qnty))
      AND ((@DocmNumb IS NULL) OR (PYDT.DOCM_NUMB = @DocmNumb))
      AND RQST.RQST_STAT IN ('002')
)
GO
