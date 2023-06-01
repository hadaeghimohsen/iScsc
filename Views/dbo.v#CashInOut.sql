SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[v#CashInOut] AS
SELECT r.RQTP_CODE,
   f.FILE_NO, 
   f.CHAT_ID_DNRM,
   pm.ACTN_DATE AS SAVE_DATE,      
	r.CRET_BY,
	'001' AS RECD_TYPE,
	N'درآمد روزانه' AS PYMT_TYPE_DESC, 
   dr.VALU AS RCPT_MTOD,
	dr.DOMN_DESC AS RCPT_DESC, 
	da.DOMN_DESC AS AMNT_TYPE_DESC,
	pm.AMNT
  FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f,
       dbo.Payment p,
       dbo.Payment_Method pm, dbo.[D$RCMT] dr, dbo.[D$ATYP] da
 WHERE r.RQID = p.RQST_RQID
   AND r.RQID = rr.RQST_RQID
   AND rr.FIGH_FILE_NO = f.FILE_NO
   AND p.RQST_RQID = pm.PYMT_RQST_RQID
   AND pm.RCPT_MTOD = dr.VALU
   AND r.RQST_STAT = '002'
   AND r.AMNT_TYPE_DNRM = da.VALU
   AND dr.VALU NOT IN ('005', '018')
   --AND CAST(R.SAVE_DATE AS DATE) BETWEEN CAST(GETDATE() AS DATE) AND CAST(GETDATE() AS DATE)
UNION ALL
SELECT r.RQTP_CODE,
   f.FILE_NO, 
   f.CHAT_ID_DNRM,
   g.PAID_DATE,
	r.CRET_BY,
	'002' AS RECD_TYPE,
	dc.DOMN_DESC AS PYMT_TYPE_DESC, 
   dr.VALU AS RCPT_MTOD,
	dr.DOMN_DESC AS RCPT_DESC, 
	da.DOMN_DESC AS AMNT_TYPE_DESC,
	gd.AMNT
  FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f,
       dbo.Gain_Loss_Rial g,
       dbo.Gain_Loss_Rail_Detail gd, dbo.[D$RCMT] dr, dbo.[D$ATYP] da, dbo.[D$CNGT] dc
 WHERE r.RQID = g.RQRO_RQST_RQID
   AND r.RQID = rr.RQST_RQID
   AND rr.FIGH_FILE_NO = f.FILE_NO
   AND g.GLID = gd.GLRL_GLID
   AND r.RQST_STAT = '002'
   AND r.AMNT_TYPE_DNRM = da.VALU
   AND gd.RCPT_MTOD = dr.VALU
   AND g.DPST_STAT = dc.VALU
   --AND CAST(R.SAVE_DATE AS DATE) BETWEEN CAST(GETDATE() AS DATE) AND CAST(GETDATE() AS DATE)
UNION ALL
SELECT r.RQTP_CODE,
   f.FILE_NO, 
   f.CHAT_ID_DNRM,
   pm.ACTN_DATE,   
	r.CRET_BY,
	'003' AS Recd_Type,
	N'برداشت از سپرده' AS PYMT_TYPE_DESC, 
   dr.VALU AS RCPT_MTOD,
	dr.DOMN_DESC AS RCPT_DESC, 
	da.DOMN_DESC AS AMNT_TYPE_DESC,
	pm.AMNT
  FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f,
       dbo.Payment p,
       dbo.Payment_Method pm, dbo.[D$RCMT] dr, dbo.[D$ATYP] da
 WHERE r.RQID = p.RQST_RQID
   AND r.RQID = rr.RQST_RQID
   AND rr.FIGH_FILE_NO = f.FILE_NO
   AND p.RQST_RQID = pm.PYMT_RQST_RQID
   AND pm.RCPT_MTOD = dr.VALU
   AND r.RQST_STAT = '002'
   AND r.AMNT_TYPE_DNRM = da.VALU
   AND dr.VALU = '005'
   --AND CAST(R.SAVE_DATE AS DATE) BETWEEN CAST(GETDATE() AS DATE) AND CAST(GETDATE() AS DATE)
UNION ALL
SELECT r.RQTP_CODE,
   f.FILE_NO, 
   f.CHAT_ID_DNRM,
   pm.ACTN_DATE,
	r.CRET_BY,
	'004' AS RECD_TYPE,
	N'هزینه روزانه' AS PYMT_TYPE_DESC, 
   dr.VALU AS RCPT_MTOD,
	dr.DOMN_DESC AS RCPT_DESC, 
	da.DOMN_DESC AS AMNT_TYPE_DESC,
	pm.AMNT
  FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f,
       dbo.Payment p,
       dbo.Payment_Method pm, dbo.[D$RCMT] dr, dbo.[D$ATYP] da
 WHERE r.RQID = p.RQST_RQID
   AND r.RQID = rr.RQST_RQID
   AND rr.FIGH_FILE_NO = f.FILE_NO
   AND p.RQST_RQID = pm.PYMT_RQST_RQID
   AND pm.RCPT_MTOD = dr.VALU
   AND r.RQST_STAT = '002'
   AND r.AMNT_TYPE_DNRM = da.VALU
   AND dr.VALU IN ('018')
   --AND CAST(R.SAVE_DATE AS DATE) BETWEEN CAST(GETDATE() AS DATE) AND CAST(GETDATE() AS DATE)
UNION ALL
SELECT r.RQTP_CODE,
   f.FILE_NO, 
   f.CHAT_ID_DNRM,
   pm.ACTN_DATE,
	r.CRET_BY,
	'005' AS RECD_TYPE,
	N'مبلغ بیمه' AS PYMT_TYPE_DESC, 
   dr.VALU AS RCPT_MTOD,
	dr.DOMN_DESC AS RCPT_DESC, 
	da.DOMN_DESC AS AMNT_TYPE_DESC,
	pm.AMNT
  FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f,
       dbo.Payment p,
       dbo.Payment_Method pm, dbo.[D$RCMT] dr, dbo.[D$ATYP] da
 WHERE r.RQID = p.RQST_RQID
   AND r.RQID = rr.RQST_RQID
   AND rr.FIGH_FILE_NO = f.FILE_NO
   AND p.RQST_RQID = pm.PYMT_RQST_RQID
   AND pm.RCPT_MTOD = dr.VALU
   AND r.RQST_STAT = '002'
   AND r.RQTP_CODE = '012'
   AND r.AMNT_TYPE_DNRM = da.VALU

GO
