SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[VF$SystemPaymentSummery01] (@X XML)
RETURNS TABLE
AS 
RETURN
(
   WITH QXML AS
   (
      SELECT @X.query('//Request').value('(Request/@rqid)[1]',         'BIGINT') AS RQID
            ,@X.query('//Request').value('(Request/@rqtpcode)[1]',     'VARCHAR(3)') AS RQTP_CODE
            ,@X.query('//Request').value('(Request/@rqttcode)[1]',     'VARCHAR(3)') AS RQTT_CODE
            ,@X.query('//Request').value('(Request/@rqstrqid)[1]',     'BIGINT') AS RQST_RQID
            ,@X.query('//Request').value('(Request/@regncode)[1]',     'VARCHAR(3)') AS REGN_CODE
            ,@X.query('//Request').value('(Request/@prvncode)[1]',     'VARCHAR(3)') AS PRVN_CODE
            ,@X.query('//Request').value('(Request/@subsys)[1]',       'SMALLINT') AS SUB_SYS
            ,@X.query('//Request').value('(Request/@ssttmsttcode)[1]', 'SMALLINT') AS SSTT_MSTT_CODE
            ,@X.query('//Request').value('(Request/@ssttcode)[1]',     'SMALLINT') AS SSTT_CODE
            ,@X.query('//Request').value('(Request/@year)[1]',         'SMALLINT') AS [YEAR]
            ,@X.query('//Request').value('(Request/@cycl)[1]',         'VARCHAR(3)') AS CYCL
            ,@X.query('//Request').value('(Request/@cretby)[1]',       'VARCHAR(250)') AS CRET_BY
            ,@X.query('//Request').value('(Request/@mdfyby)[1]',       'VARCHAR(250)') AS MDFY_BY
            ,@X.query('//Request_Row').value('(Request_Row/@fighfileno)[1]', 'BIGINT') AS FIGH_FILE_NO
            ,@X.query('//Request').value('(Request/@fromrqstdate)[1]',       'DATE') AS FROM_RQST_DATE
            ,@X.query('//Request').value('(Request/@torqstdate)[1]',       'DATE') AS TO_RQST_DATE
            ,@X.query('//Request').value('(Request/@fromsavedate)[1]',       'DATE') AS FROM_SAVE_DATE
            ,@X.query('//Request').value('(Request/@tosavedate)[1]',       'DATE') AS TO_SAVE_DATE
            
            ,@X.query('//Payment_Method').value('(Payment_Method/@frompymtdate)[1]',       'DATE') AS FROM_PYMT_DATE
            ,@X.query('//Payment_Method').value('(Payment_Method/@topymtdate)[1]',       'DATE') AS TO_PYMT_DATE
            
            ,@X.query('//Payment_Discount').value('(Payment_Discount/@frompydsdate)[1]',       'DATE') AS FROM_PYDS_DATE
            ,@X.query('//Payment_Discount').value('(Payment_Discount/@topydsdate)[1]',       'DATE') AS TO_PYDS_DATE            
            
            ,@X.query('//Club_Method').value('(Club_Method/@code)[1]',       'BIGINT') AS CBMT_CODE
            
            ,@X.query('//Fighter').value('(Fighter/@cochcode)[1]',     'BIGINT') AS COCH_CODE
            --,@X.query('//Fighter').value('(Fighter/@cmbtcode)[1]',     'BIGINT') AS CBMT_CODE            
            ,@X.query('//Fighter').value('(Fighter/@mtodcode)[1]',     'BIGINT') AS MTOD_CODE
            ,@X.query('//Fighter').value('(Fighter/@ctgycode)[1]',     'BIGINT') AS CTGY_CODE
            ,@X.query('//Fighter').value('(Fighter/@frstname)[1]',     'NVARCHAR(250)') AS FRST_NAME
            ,@X.query('//Fighter').value('(Fighter/@lastname)[1]',     'NVARCHAR(250)') AS LAST_NAME
            ,@X.query('//Fighter').value('(Fighter/@suntbuntdeptorgncode)[1]',     'VARCHAR(2)') AS SUNT_BUNT_DEPT_ORGN_CODE
            ,@X.query('//Fighter').value('(Fighter/@suntbuntdeptcode)[1]',     'VARCHAR(2)') AS SUNT_BUNT_DEPT_CODE
            ,@X.query('//Fighter').value('(Fighter/@suntbuntcode)[1]',     'VARCHAR(2)') AS SUNT_BUNT_CODE
            ,@X.query('//Fighter').value('(Fighter/@suntcode)[1]',     'VARCHAR(4)') AS SUNT_CODE
            ,@X.query('//Fighter').value('(Fighter/@mbspstrtdate)[1]',     'DATE') AS MBSP_STRT_DATE
            ,@X.query('//Fighter').value('(Fighter/@mbspenddate)[1]',     'DATE') AS MBSP_END_DATE
   )
SELECT  ROW_NUMBER() OVER( ORDER BY r.SAVE_DATE ) AS RWNO,
        r.SAVE_DATE ,
        dbo.GET_MTOS_U(r.SAVE_DATE) AS PERS_SAVE_DATE,
        f.FILE_NO,
        f.DEBT_DNRM,
        f.NAME_DNRM ,
        p.CRET_BY,
        m.CODE AS MTOD_CODE,
        m.MTOD_DESC,
        f.FNGR_PRNT_DNRM ,
        f.CELL_PHON_DNRM , 
        su.SUNT_DESC,       
        f.MBSP_STRT_DATE ,
        f.MBSP_END_DATE ,
        dbo.GET_MTOS_U(f.MBSP_STRT_DATE) AS PERS_MBSP_STRT_DATE,
        dbo.GET_MTOS_U(f.MBSP_END_DATE) AS PERS_MBSP_END_DATE,        
        --cb.MTOD_CODE,
        --(SELECT m.MTOD_DESC FROM dbo.Method m WHERE m.CODE = cb.MTOD_CODE ) AS MTOD_DESC,
        CAST(cb.STRT_TIME AS TIME(0)) STRT_TIME,
        CAST(cb.END_TIME AS TIME(0)) AS END_TIME,
        r.RQID ,
        p.CASH_CODE ,
        ( SELECT    c.NAME
          FROM      dbo.Cash c
          WHERE     c.CODE = p.CASH_CODE
        ) AS CASH_DESC ,
        pd.EXPN_CODE ,
        pd.EXPN_PRIC ,
        pd.QNTY ,
        ( SELECT    e.EXPN_DESC
          FROM      dbo.Expense e
          WHERE     e.CODE = pd.EXPN_CODE
        ) AS EXPN_DESC ,
        ( p.SUM_EXPN_PRIC + p.SUM_EXPN_EXTR_PRCT ) AS TOTL_AMNT ,
        p.SUM_PYMT_DSCN_DNRM ,
        ( ( p.SUM_EXPN_PRIC + p.SUM_EXPN_EXTR_PRCT ) - p.SUM_PYMT_DSCN_DNRM ) AS PYMT_AMNT ,
        ( p.SUM_RCPT_EXPN_PRIC + ISNULL(p.SUM_RCPT_EXPN_EXTR_PRCT, 0) ) AS GET_PYMT_AMNT,
        ( ( p.SUM_EXPN_PRIC + p.SUM_EXPN_EXTR_PRCT )
          - ( ( p.SUM_RCPT_EXPN_PRIC + ISNULL(p.SUM_RCPT_EXPN_EXTR_PRCT, 0) )
              + p.SUM_PYMT_DSCN_DNRM ) ) AS DEBT_AMNT ,
        rqtp.RQTP_DESC,
        r.RQTP_CODE ,
        rqtt.RQTT_DESC,
        r.RQTT_CODE ,
        ( SELECT    c.NAME_DNRM
          FROM      dbo.Fighter c
          WHERE     c.FILE_NO = pd.FIGH_FILE_NO
        ) AS COCH_NAME ,
        pd.FIGH_FILE_NO ,
        p.AMNT_UNIT_TYPE_DNRM ,
        (SELECT DOMN_DESC FROM dbo.[D$ATYP] WHERE VALU = p.AMNT_UNIT_TYPE_DNRM) AS AMNT_TYPE_DESC        
FROM    dbo.Request_Type rqtp ,
        dbo.Requester_Type rqtt ,
        dbo.Request r ,
        dbo.Request_Row rr ,
        dbo.Fighter f ,
        dbo.Sub_Unit su,
        dbo.Payment p ,
        dbo.Payment_Detail pd 
        LEFT OUTER JOIN dbo.Club_Method cb ON cb.CODE = pd.CBMT_CODE_DNRM
        LEFT OUTER JOIN dbo.Method m ON m.CODE = pd.MTOD_CODE_DNRM ,
        QXML Qx
WHERE   rqtp.CODE = r.RQTP_CODE
        AND rqtt.CODE = r.RQTT_CODE
        AND r.RQID = rr.RQST_RQID
        AND rr.FIGH_FILE_NO = f.FILE_NO
        AND p.RQST_RQID = r.RQID
        AND p.RQST_RQID = pd.PYMT_RQST_RQID
        AND p.CASH_CODE = pd.PYMT_CASH_CODE
        AND r.RQST_STAT = '002'
        AND r.RQTP_CODE IN ( '001', '009', '016' )
        AND f.SUNT_BUNT_DEPT_ORGN_CODE_DNRM = su.BUNT_DEPT_ORGN_CODE
        AND f.SUNT_BUNT_DEPT_CODE_DNRM = su.BUNT_DEPT_CODE
        AND f.SUNT_BUNT_CODE_DNRM = su.BUNT_CODE
        AND f.SUNT_CODE_DNRM = su.CODE
        AND p.PYMT_STAT != '002'
        AND f.CONF_STAT = '002'
        AND f.ACTV_TAG_DNRM >= '101'
        
        AND (Qx.FROM_RQST_DATE IS NULL OR CAST(R.RQST_DATE AS DATE) >= CAST(Qx.FROM_RQST_DATE AS DATE))
        AND (Qx.TO_RQST_DATE IS NULL OR CAST(R.RQST_DATE AS DATE) <= CAST(Qx.TO_RQST_DATE AS DATE))
        
        /*AND (Qx.FROM_SAVE_DATE IS NULL OR CAST(R.SAVE_DATE AS DATE) >= CAST(Qx.FROM_SAVE_DATE AS DATE))
        AND (Qx.TO_SAVE_DATE IS NULL OR CAST(R.SAVE_DATE AS DATE) <= CAST(Qx.TO_SAVE_DATE AS DATE))
        
        AND (Qx.FROM_PYMT_DATE IS NULL OR EXISTS(SELECT * FROM dbo.Payment_Method pm WHERE p.RQST_RQID = pm.PYMT_RQST_RQID AND p.CASH_CODE = pm.PYMT_CASH_CODE AND CAST(pm.ACTN_DATE AS DATE) >= CAST(Qx.FROM_PYMT_DATE AS DATE)))
        AND (Qx.TO_PYMT_DATE IS NULL OR EXISTS(SELECT * FROM dbo.Payment_Method pm WHERE p.RQST_RQID = pm.PYMT_RQST_RQID AND p.CASH_CODE = pm.PYMT_CASH_CODE AND CAST(pm.ACTN_DATE AS DATE) <= CAST(Qx.TO_PYMT_DATE AS DATE)))
        
        AND (Qx.FROM_PYDS_DATE IS NULL OR EXISTS(SELECT * FROM dbo.Payment_Discount ps WHERE p.RQST_RQID = ps.PYMT_RQST_RQID AND p.CASH_CODE = ps.PYMT_CASH_CODE AND CAST(ps.CRET_DATE AS DATE) >= CAST(Qx.FROM_PYDS_DATE AS DATE)))
        AND (Qx.TO_PYDS_DATE IS NULL OR EXISTS(SELECT * FROM dbo.Payment_Discount ps WHERE p.RQST_RQID = ps.PYMT_RQST_RQID AND p.CASH_CODE = ps.PYMT_CASH_CODE AND CAST(ps.CRET_DATE AS DATE) <= CAST(Qx.TO_PYDS_DATE AS DATE)))
        
        AND (Qx.CBMT_CODE IS NULL OR (CASE WHEN Qx.CBMT_CODE = 0 THEN cb.CODE ELSE Qx.CBMT_CODE END = cb.CODE AND f.MBSP_END_DATE >= CAST(GETDATE() AS DATE)))
        */
)

 

GO
