SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[V#Coach_Events] AS
SELECT c.FILE_NO COCH_FILE_NO, c.CHAT_ID_DNRM AS COCH_CHAT_ID, c.NAME_DNRM AS COCH_NAME, c.CELL_PHON_DNRM AS COCH_CELL_PHON, r.RQID, r.RQTP_CODE, r.SAVE_DATE, r.INVC_DATE, pd.CODE, pd.PYDT_DESC, pd.EXPN_CODE, CAST(pd.EXPR_DATE AS DATE) EXPR_DATE, (pd.EXPN_PRIC * pd.QNTY) AS EXPN_PRIC, ISNULL(pds.AMNT, 0) AS PYDS_AMNT, 
       f.FILE_NO, f.CHAT_ID_DNRM, f.NAME_DNRM, f.CELL_PHON_DNRM, f.BRTH_DATE_DNRM, f.INSR_DATE_DNRM, f.SEX_TYPE_DNRM
  FROM dbo.Payment_Detail pd
       LEFT OUTER JOIN dbo.Payment_Discount pds ON(pds.PYDT_CODE_DNRM = pd.CODE AND pds.EXPN_CODE = pd.EXPN_CODE AND pds.AMNT_TYPE = '005'),
       dbo.Fighter c, 
       dbo.Request_Row rr, 
       dbo.Request r,
       dbo.Fighter f       
 WHERE pd.FIGH_FILE_NO = c.FILE_NO
   AND pd.PYMT_RQST_RQID = rr.RQST_RQID
   AND pd.RQRO_RWNO = rr.RWNO
   AND rr.FIGH_FILE_NO = f.FILE_NO
   AND rr.RQST_RQID = r.RQID
   AND r.RQST_STAT = '002'
   AND CAST(pd.EXPR_DATE AS DATE) >= CAST(GETDATE() AS DATE);

GO
