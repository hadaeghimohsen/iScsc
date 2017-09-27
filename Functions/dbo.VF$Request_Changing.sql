SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[VF$Request_Changing](
   @FileNo BIGINT
)
RETURNS TABLE
AS RETURN
(
   SELECT
           T.RQTP_CODE, 
           T.RQTP_DESC, 
           T.RQTT_CODE,
           T.RQTT_DESC,
           T.RQID, 
           T.RQST_DATE,
           T.SAVE_DATE,
           T.CRET_BY,
           T.RQST_DESC,
--           T.RQST_RQID,
--           T.CASH_CODE,
           /*T.NAME_DNRM,
           T.FILE_NO,
           T.CELL_PHON_DNRM,*/
           --T.FIGH_FILE_NO,
           T.TOTL_AMNT,
           ISNULL((SELECT SUM(pm.AMNT) FROM Payment_Method Pm WHERE pm.PYMT_CASH_CODE = T.CASH_CODE AND pm.PYMT_RQST_RQID = T.RQST_RQID) , 0) AS TOTL_RCPT_AMNT,
           ISNULL((SELECT SUM(pc.AMNT) FROM Payment_Discount pc WHERE pc.PYMT_CASH_CODE = T.CASH_CODE AND pc.PYMT_RQST_RQID = T.RQST_RQID), 0) AS TOTL_DSCT_AMNT
     FROM (
   SELECT  r.RQTP_CODE, 
           rqtp.RQTP_DESC, 
           r.RQTT_CODE,
           rqtt.RQTT_DESC,
           r.RQID, 
           r.RQST_DATE,
           r.SAVE_DATE,
           r.RQST_DESC,
           r.CRET_BY, 
           P.RQST_RQID,           
           P.CASH_CODE,
           /*F.NAME_DNRM,
           F.File_No,
           F.Cell_Phon_Dnrm,*/
           --pd.FIGH_FILE_NO,
           ISNULL(SUM((pd.EXPN_PRIC + ISNULL(pd.EXPN_EXTR_PRCT, 0)) * pd.QNTY), 0) AS TOTL_AMNT
     FROM  dbo.Request r
     INNER JOIN dbo.Request_Row rr ON r.RQID = rr.RQST_RQID 
     INNER JOIN dbo.Request_Type rqtp ON r.RQTP_CODE = rqtp.CODE 
     INNER JOIN dbo.Requester_Type rqtt ON r.RQTT_CODE = rqtt.CODE
     INNER JOIN dbo.Fighter f ON rr.FIGH_FILE_NO = f.FILE_NO
     LEFT OUTER JOIN dbo.Payment p ON p.RQST_RQID = r.RQID
     LEFT OUTER JOIN dbo.Payment_Detail pd ON pd.PYMT_CASH_CODE = p.CASH_CODE AND pd.PYMT_RQST_RQID = p.RQST_RQID
     --LEFT OUTER JOIN dbo.Payment_Method pm ON pm.PYMT_CASH_CODE = p.CASH_CODE AND pm.PYMT_RQST_RQID = p.RQST_RQID
     --LEFT OUTER JOIN dbo.Payment_Discount pc ON pc.PYMT_CASH_CODE = p.CASH_CODE AND pc.PYMT_RQST_RQID = p.RQST_RQID
   WHERE  (rr.RECD_STAT = '002') 
     AND  (r.RQST_STAT = '002')
     AND  (f.CONF_STAT = '002')
     AND  (@FileNo IS NULL OR f.FILE_NO = @FileNo)
     GROUP BY r.RQTP_CODE, 
           rqtp.RQTP_DESC, 
           r.RQTT_CODE,
           rqtt.RQTT_DESC,
           r.RQID, 
           r.RQST_DATE,
           r.SAVE_DATE,
           r.CRET_BY,
           r.RQST_DESC,
           P.RQST_RQID,
           P.CASH_CODE
           /*F.NAME_DNRM,
           F.FILE_NO,
           F.CELL_PHON_DNRM*/
           --Pd.FIGH_FILE_NO
   ) T
)
GO
