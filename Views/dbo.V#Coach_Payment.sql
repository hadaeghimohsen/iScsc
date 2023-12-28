SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[V#Coach_Payment] AS 
SELECT  c.NAME_DNRM ,
        m.MTOD_DESC ,
        cb.CTGY_DESC ,
        p.SUM_RCPT_EXPN_PRIC ,
        dbo.GET_MTOS_U(r.SAVE_DATE) AS SAVE_DATE ,
        UPPER(SUSER_NAME()) AS CRNT_USER ,
        dbo.GET_MTOS_U(GETDATE()) + CHAR(10)
        + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)) AS CRNT_DATE ,
        f.FNGR_PRNT_DNRM ,
        f.NAME_DNRM AS FIGH_NAME_DNRM ,
        r.RQID ,
        ms.RWNO AS MBSP_RWNO ,
            --f.MBSP_RWNO_DNRM,
        dbo.GET_MTOS_U(ms.STRT_DATE) AS MBSP_STRT_DATE ,
        dbo.GET_MTOS_U(ms.END_DATE) AS MBSP_END_DATE,
        pd.CBMT_CODE_DNRM,
        pd.FIGH_FILE_NO AS COCH_FILE_NO,
        pd.CTGY_CODE_DNRM,
        pd.PYDT_DESC,
        pd.EXPN_PRIC,
        pd.EXPN_EXTR_PRCT,
        pd.QNTY,
        pd.PROF_AMNT_DNRM,
        pd.DEDU_AMNT_DNRM,
        
        -- Parameters Show
        -- Coach
        ms.NUMB_OF_ATTN_MONT,
        ms.SUM_ATTN_MONT_DNRM,
        c.CHAT_ID_DNRM AS COCH_CHAT_ID, 
        c.CELL_PHON_DNRM AS COCH_CELL_PHON, 
        c.SEX_TYPE_DNRM AS COCH_SEX_TYPE_DNRM,
        
        -- Service
        f.FILE_NO, 
        f.CHAT_ID_DNRM, 
        f.CELL_PHON_DNRM,
        f.SEX_TYPE_DNRM,
        f.FGPB_TYPE_DNRM,
        
        -- Request
        rt.RQTP_DESC,
        r.RQTP_CODE,
        r.RQTT_CODE,
        
        -- Payment
        p.PYMT_NO,
        p.SUM_EXPN_PRIC,
        p.SUM_EXPN_EXTR_PRCT,
        p.SUM_REMN_PRIC,
        p.SUM_PYMT_DSCN_DNRM,        
        (p.SUM_EXPN_PRIC + p.SUM_EXPN_EXTR_PRCT) - (p.SUM_RCPT_EXPN_PRIC + p.SUM_PYMT_DSCN_DNRM) AS DEBT_AMNT_PYMT
        
FROM    dbo.Payment_Detail pd ,
        dbo.Fighter c ,
        dbo.Category_Belt cb ,
        dbo.Method m ,
        dbo.Payment p ,
        dbo.Request r ,
        dbo.Request_Row rr ,
        dbo.Fighter f ,
        dbo.Member_Ship ms,
        dbo.Request_Type rt
WHERE   pd.PYMT_CASH_CODE = p.CASH_CODE
        AND pd.PYMT_RQST_RQID = p.RQST_RQID
        AND p.RQST_RQID = r.RQID
        AND c.FILE_NO = pd.FIGH_FILE_NO
        AND pd.CTGY_CODE_DNRM = cb.CODE
        AND pd.MTOD_CODE_DNRM = m.CODE
        AND m.CODE = cb.MTOD_CODE
        AND pd.PYMT_RQST_RQID = r.RQID
        AND pd.RQRO_RWNO = rr.RWNO
        AND r.RQID = rr.RQST_RQID
        AND rr.FIGH_FILE_NO = f.FILE_NO
        AND r.RQTP_CODE = rt.CODE
        AND ( ( r.RQTP_CODE = '009'
                AND rr.RQST_RQID = ms.RQRO_RQST_RQID
                AND rr.RWNO = ms.RQRO_RWNO
                AND ms.RECT_CODE = '004' )
              OR ( r.RQTP_CODE = '001'
                   AND rr.RQST_RQID = ms.RQRO_RQST_RQID
                   AND rr.RWNO = ms.RQRO_RWNO
                   AND ms.RECT_CODE = '001' ) )
        AND r.RQST_STAT = '002'
        AND r.RQTP_CODE IN ( '001', '009' )
        AND f.CONF_STAT = '002'
        AND f.ACTV_TAG_DNRM >= '101'
        AND ms.VALD_TYPE = '002'

UNION ALL
SELECT c.NAME_DNRM ,
        m.MTOD_DESC ,
        cb.CTGY_DESC ,
        p.SUM_RCPT_EXPN_PRIC ,
        dbo.GET_MTOS_U(r.SAVE_DATE) AS SAVE_DATE ,
        UPPER(SUSER_NAME()) AS CRNT_USER ,
        dbo.GET_MTOS_U(GETDATE()) + CHAR(10)
        + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)) AS CRNT_DATE ,
        f.FNGR_PRNT_DNRM ,
        f.NAME_DNRM AS FIGH_NAME_DNRM ,
        r.RQID ,
        NULL,--ms.RWNO AS MBSP_RWNO ,
            --f.MBSP_RWNO_DNRM,
        dbo.GET_MTOS_U(r.RQST_DATE) ,
        dbo.GET_MTOS_U(pd.EXPR_DATE),
        pd.CBMT_CODE_DNRM,
        pd.FIGH_FILE_NO AS COCH_FILE_NO,
        pd.CTGY_CODE_DNRM,
        pd.PYDT_DESC,
        pd.EXPN_PRIC,
        pd.EXPN_EXTR_PRCT,
        pd.QNTY,
        pd.PROF_AMNT_DNRM,
        pd.DEDU_AMNT_DNRM,
        
        -- Parameters Show
        -- Coach
        NULL,
        NULL,
        c.CHAT_ID_DNRM AS COCH_CHAT_ID, 
        c.CELL_PHON_DNRM AS COCH_CELL_PHON, 
        c.SEX_TYPE_DNRM AS COCH_SEX_TYPE_DNRM,
        
        -- Service
        f.FILE_NO, 
        f.CHAT_ID_DNRM, 
        f.CELL_PHON_DNRM,
        f.SEX_TYPE_DNRM,
        f.FGPB_TYPE_DNRM,
        
        -- Request
        rt.RQTP_DESC,
        r.RQTP_CODE,
        r.RQTT_CODE,
        
        -- Payment
        p.PYMT_NO,
        p.SUM_EXPN_PRIC,
        p.SUM_EXPN_EXTR_PRCT,
        p.SUM_REMN_PRIC,
        p.SUM_PYMT_DSCN_DNRM,        
        (p.SUM_EXPN_PRIC + p.SUM_EXPN_EXTR_PRCT) - (p.SUM_RCPT_EXPN_PRIC + p.SUM_PYMT_DSCN_DNRM) AS DEBT_AMNT_PYMT        
  FROM dbo.Payment_Detail pd ,
       dbo.Fighter c ,
       dbo.Category_Belt cb ,
       dbo.Method m ,
       dbo.Payment p ,
       dbo.Request r ,
       dbo.Request_Row rr ,
       dbo.Fighter f ,
       dbo.Request_Type rt
 WHERE pd.PYMT_CASH_CODE = p.CASH_CODE
   AND pd.PYMT_RQST_RQID = p.RQST_RQID
   AND p.RQST_RQID = r.RQID
   AND c.FILE_NO = pd.FIGH_FILE_NO
   AND pd.CTGY_CODE_DNRM = cb.CODE
   AND pd.MTOD_CODE_DNRM = m.CODE
   AND m.CODE = cb.MTOD_CODE
   AND pd.PYMT_RQST_RQID = r.RQID
   AND pd.RQRO_RWNO = rr.RWNO
   AND r.RQID = rr.RQST_RQID
   AND rr.FIGH_FILE_NO = f.FILE_NO
   AND r.RQTP_CODE = rt.CODE
   AND r.RQST_STAT = '002'
   AND r.RQTP_CODE IN ( '016' )
   AND f.CONF_STAT = '002'
   AND f.ACTV_TAG_DNRM >= '101';





GO
