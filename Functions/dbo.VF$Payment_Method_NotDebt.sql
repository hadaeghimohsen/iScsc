SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[VF$Payment_Method_NotDebt] (@X XML)
RETURNS TABLE
AS 
RETURN
(
   WITH QXML AS
   (
      SELECT /*@X.query('//Request').value('(Request/@rqid)[1]',         'BIGINT') AS RQID
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
            
            ,@X.query('//Request').value('(Request/@mdfyby)[1]',       'VARCHAR(250)') AS MDFY_BY
            ,@X.query('//Request_Row').value('(Request_Row/@fighfileno)[1]', 'BIGINT') AS FIGH_FILE_NO*/
             @X.query('//Request').value('(Request/@fromrqstdate)[1]',       'DATE') AS FROM_RQST_DATE
            ,@X.query('//Request').value('(Request/@torqstdate)[1]',       'DATE') AS TO_RQST_DATE
            ,@X.query('//Request').value('(Request/@cretby)[1]',       'VARCHAR(250)') AS CRET_BY
            /*,@X.query('//Request').value('(Request/@fromsavedate)[1]',       'DATE') AS FROM_SAVE_DATE
            ,@X.query('//Request').value('(Request/@tosavedate)[1]',       'DATE') AS TO_SAVE_DATE
            
            ,@X.query('//Payment_Method').value('(Payment_Method/@frompymtdate)[1]',       'DATE') AS FROM_PYMT_DATE
            ,@X.query('//Payment_Method').value('(Payment_Method/@topymtdate)[1]',       'DATE') AS TO_PYMT_DATE
            
            ,@X.query('//Payment_Discount').value('(Payment_Discount/@frompydsdate)[1]',       'DATE') AS FROM_PYDS_DATE
            ,@X.query('//Payment_Discount').value('(Payment_Discount/@topydsdate)[1]',       'DATE') AS TO_PYDS_DATE            
            */
            ,@X.query('//Club_Method').value('(Club_Method/@code)[1]',       'BIGINT') AS CBMT_CODE
            ,@X.query('//Club_Method').value('(Club_Method/@cochfileno)[1]',       'BIGINT') AS COCH_FILE_NO
            /*            
            ,@X.query('//Fighter').value('(Fighter/@cochcode)[1]',     'BIGINT') AS COCH_CODE

            ,@X.query('//Fighter').value('(Fighter/@mtodcode)[1]',     'BIGINT') AS MTOD_CODE
            ,@X.query('//Fighter').value('(Fighter/@ctgycode)[1]',     'BIGINT') AS CTGY_CODE
            ,@X.query('//Fighter').value('(Fighter/@frstname)[1]',     'NVARCHAR(250)') AS FRST_NAME
            ,@X.query('//Fighter').value('(Fighter/@lastname)[1]',     'NVARCHAR(250)') AS LAST_NAME
            ,@X.query('//Fighter').value('(Fighter/@suntbuntdeptorgncode)[1]',     'VARCHAR(2)') AS SUNT_BUNT_DEPT_ORGN_CODE
            ,@X.query('//Fighter').value('(Fighter/@suntbuntdeptcode)[1]',     'VARCHAR(2)') AS SUNT_BUNT_DEPT_CODE
            ,@X.query('//Fighter').value('(Fighter/@suntbuntcode)[1]',     'VARCHAR(2)') AS SUNT_BUNT_CODE
            ,@X.query('//Fighter').value('(Fighter/@suntcode)[1]',     'VARCHAR(4)') AS SUNT_CODE
            ,@X.query('//Fighter').value('(Fighter/@mbspstrtdate)[1]',     'DATE') AS MBSP_STRT_DATE
            ,@X.query('//Fighter').value('(Fighter/@mbspenddate)[1]',     'DATE') AS MBSP_END_DATE*/
   )
-- این گزینه برای مشتریانی که تک کلاسی ثبت نام کرده اند و دارای یکم مربی می باشند
SELECT  pm.ACTN_DATE ,    
        dbo.GET_MTOS_U(pm.ACTN_DATE) AS PERS_ACTN_DATE,
        CAST(pm.ACTN_DATE AS TIME(0)) AS ACTN_TIME,
        pm.AMNT ,
        at.DOMN_DESC AS UNIT_AMNT_TYPE,   
        pm.RCPT_MTOD ,
        rc.DOMN_DESC AS RCPT_DESC,
        pm.CRET_BY ,
        rt.RQTP_DESC ,
        r.RQTP_CODE ,
        r.RQTT_CODE ,
        f.FGPB_TYPE_DNRM ,
        f.CLUB_CODE_DNRM ,
        c.NAME ,
        f.SUNT_BUNT_DEPT_ORGN_CODE_DNRM ,
        f.SUNT_BUNT_DEPT_CODE_DNRM ,
        f.SUNT_BUNT_CODE_DNRM ,
        f.SUNT_CODE_DNRM ,
        f.FILE_NO,
        f.NAME_DNRM AS FIGH_NAME_DNRM,
        F.FNGR_PRNT_DNRM,
        (
           CASE r.RQTP_CODE
            WHEN '001' THEN
               (SELECT dbo.GET_MTOS_U(STRT_DATE)
                 FROM dbo.Member_Ship
                WHERE FIGH_FILE_NO = F.FILE_NO
                  AND RECT_CODE = '004'
                  AND RWNO = 1)
            WHEN '009' THEN
               (SELECT dbo.GET_MTOS_U(STRT_DATE)
                 FROM dbo.Member_Ship
                WHERE RQRO_RQST_RQID = r.RQID
                  AND RECT_CODE = '004')
           END            
        ) AS STRT_DATE,
        su.SUNT_DESC,
        f.MTOD_CODE_DNRM ,
        m.MTOD_DESC, 
        f.CTGY_CODE_DNRM ,
        ct.CTGY_DESC ,
        f.COCH_FILE_NO_DNRM ,
        co.NAME_DNRM,
        f.CBMT_CODE_DNRM,
        CAST(cm.STRT_TIME AS VARCHAR(5)) AS STRT_TIME,
        CAST(cm.END_TIME AS VARCHAR(5)) AS END_TIME,
        cm.CBMT_DESC,
        /*dbo.GET_ADMN_U(pm.ACTN_DATE, pm.CRET_BY, '001', f.CBMT_CODE_DNRM)*/ 0 AS MTOD_CONT,
        /*dbo.GET_ADMN_U(pm.ACTN_DATE, pm.CRET_BY, '002', f.CBMT_CODE_DNRM)*/ 0 AS CBMT_CONT,
        pm.VALD_TYPE
FROM    dbo.Payment_Method pm ,        
        dbo.Payment p ,
        dbo.Request r ,
        dbo.Request_Type rt,
        dbo.Request_Row rr ,
        dbo.Fighter f ,
        dbo.Club c ,
        dbo.Method m,
        dbo.Category_Belt ct ,
        dbo.Fighter co,
        dbo.Club_Method cm,
        dbo.Sub_Unit su,
        dbo.[D$RCMT] rc,
        dbo.[D$ATYP] at,
        QXML Qx
WHERE   pm.PYMT_RQST_RQID = p.RQST_RQID
        AND pm.PYMT_CASH_CODE = p.CASH_CODE
        AND p.RQST_RQID = r.RQID
        AND r.RQTP_CODE = rt.CODE        
        AND r.RQID = rr.RQST_RQID
        AND rr.FIGH_FILE_NO = f.FILE_NO
        AND c.CODE = f.CLUB_CODE_DNRM
        AND m.CODE = f.MTOD_CODE_DNRM
        AND ct.CODE = f.CTGY_CODE_DNRM
        AND co.FILE_NO = f.COCH_FILE_NO_DNRM
        AND f.CBMT_CODE_DNRM = cm.CODE
        AND su.CODE = f.SUNT_CODE_DNRM
        AND su.BUNT_CODE = f.SUNT_BUNT_CODE_DNRM
        AND su.BUNT_DEPT_CODE = f.SUNT_BUNT_DEPT_CODE_DNRM
        AND su.BUNT_DEPT_ORGN_CODE = f.SUNT_BUNT_DEPT_ORGN_CODE_DNRM
        AND pm.RCPT_MTOD = rc.VALU
        AND p.AMNT_UNIT_TYPE_DNRM = at.VALU
        AND r.RQTP_CODE NOT IN ('016')
        AND f.CONF_STAT = '002'
        AND f.ACTV_TAG_DNRM >= '101'
        AND p.PYMT_STAT != '002'
        
        --AND (Qx.FROM_RQST_DATE IS NULL OR CAST(R.RQST_DATE AS DATE) >= CAST(Qx.FROM_RQST_DATE AS DATE))
        --AND (Qx.TO_RQST_DATE IS NULL OR CAST(R.RQST_DATE AS DATE) <= CAST(Qx.TO_RQST_DATE AS DATE))
        
        --AND (Qx.FROM_SAVE_DATE IS NULL OR CAST(R.SAVE_DATE AS DATE) >= CAST(Qx.FROM_SAVE_DATE AS DATE))
        --AND (Qx.TO_SAVE_DATE IS NULL OR CAST(R.SAVE_DATE AS DATE) <= CAST(Qx.TO_SAVE_DATE AS DATE))
        AND (p.SUM_EXPN_PRIC - (p.SUM_RCPT_EXPN_PRIC + p.SUM_PYMT_DSCN_DNRM)) = 0        
        AND EXISTS (
            SELECT *
              FROM dbo.Payment_Method pmt
             WHERE pmt.RQRO_RQST_RQID = pm.PYMT_RQST_RQID
               AND (Qx.FROM_RQST_DATE IS NULL OR CAST(pmt.ACTN_DATE AS DATE) >= CAST(Qx.FROM_RQST_DATE AS DATE))
               AND (Qx.TO_RQST_DATE IS NULL OR CAST(pmt.ACTN_DATE AS DATE) <= CAST(Qx.TO_RQST_DATE AS DATE))
        )
        AND (Qx.CRET_BY IS NULL OR Qx.CRET_BY = '' OR pm.CRET_BY = Qx.CRET_BY)

UNION ALL
SELECT  pm.ACTN_DATE ,    
        dbo.GET_MTOS_U(pm.ACTN_DATE) AS PERS_ACTN_DATE,
        CAST(pm.ACTN_DATE AS TIME(0)) AS ACTN_TIME,
        pm.AMNT ,
        at.DOMN_DESC AS UNIT_AMNT_TYPE,   
        pm.RCPT_MTOD ,
        rc.DOMN_DESC AS RCPT_DESC,
        pm.CRET_BY ,
        rt.RQTP_DESC ,
        r.RQTP_CODE ,
        r.RQTT_CODE ,
        '' AS FGPB_TYPE_DNRM,
        0 AS CLUB_CODE_DNRM,
        '' AS NAME,
        '' AS SUNT_BUNT_DEPT_ORGN_CODE_DNRM ,
        '' AS SUNT_BUNT_DEPT_CODE_DNRM ,
        '' AS SUNT_BUNT_CODE_DNRM ,
        '' AS SUNT_CODE_DNRM ,
        f.FILE_NO AS FILE_NO,
        CASE f.FGPB_TYPE_DNRM WHEN '005' THEN fp.FRST_NAME + N' ' + fp.LAST_NAME + N'(کاربر مهمان)' ELSE f.NAME_DNRM END AS FIGH_NAME_DNRM,
        --N'مهمان' AS FIGH_NAME_DNRM,
        CASE f.FGPB_TYPE_DNRM WHEN '005' THEN '--' ELSE f.FNGR_PRNT_DNRM END AS FNGR_PRNT_DNRM,
        --'--' AS FNGR_PRNT_DNRM,
        '--' AS STRT_DATE,
        '' AS SUNT_DESC,
        0 AS MTOD_CODE_DNRM ,
        N'درآمد متفرقه' AS MTOD_DESC, 
        0 AS CTGY_CODE_DNRM ,
        (
           SELECT e.EXPN_DESC + N' ,'
             FROM dbo.Payment_Detail pd, 
                  dbo.Expense e/*, 
                  dbo.Expense_Type et, 
                  dbo.Expense_Item ei,
                  dbo.Method m,
                  dbo.Category_Belt cb*/
            WHERE pd.PYMT_RQST_RQID = r.RQID
              AND pd.EXPN_CODE = e.CODE
              /*AND e.EXTP_CODE = et.CODE
              AND et.EPIT_CODE = ei.CODE
              AND e.MTOD_CODE = m.CODE
              AND e.CTGY_CODE = cb.CODE*/
              FOR XML PATH('')
        ) AS CTGY_DESC ,
        0 AS COCH_FILE_NO_DNRM ,
        '' AS NAME_DNRM,
        0 AS CBMT_CODE_DNRM,
        '' AS STRT_TIME,
        '' AS END_TIME,
        '' AS CBMT_DESC,
        0 AS MTOD_CONT,
        0 AS CBMT_CONT,
        pm.VALD_TYPE
FROM    dbo.Payment_Method pm ,        
        dbo.Payment p ,
        dbo.Request r 
        LEFT OUTER JOIN dbo.Fighter_Public fp ON r.RQID = fp.RQRO_RQST_RQID,
        dbo.fighter f,
        dbo.Request_Type rt,
        dbo.[D$RCMT] rc,
        dbo.[D$ATYP] at,
        QXML Qx
WHERE   pm.PYMT_RQST_RQID = p.RQST_RQID
        AND pm.PYMT_CASH_CODE = p.CASH_CODE
        AND p.RQST_RQID = r.RQID
        AND r.RQTP_CODE = rt.CODE        
        AND pm.RCPT_MTOD = rc.VALU
        AND p.AMNT_UNIT_TYPE_DNRM = at.VALU
        AND r.RQTP_CODE IN ('016')
        AND f.FILE_NO = pm.FIGH_FILE_NO_DNRM
        --AND (Qx.FROM_RQST_DATE IS NULL OR CAST(R.RQST_DATE AS DATE) >= CAST(Qx.FROM_RQST_DATE AS DATE))
        --AND (Qx.TO_RQST_DATE IS NULL OR CAST(R.RQST_DATE AS DATE) <= CAST(Qx.TO_RQST_DATE AS DATE))
        
        --AND (Qx.FROM_SAVE_DATE IS NULL OR CAST(R.SAVE_DATE AS DATE) >= CAST(Qx.FROM_SAVE_DATE AS DATE))
        --AND (Qx.TO_SAVE_DATE IS NULL OR CAST(R.SAVE_DATE AS DATE) <= CAST(Qx.TO_SAVE_DATE AS DATE))
        AND (p.SUM_EXPN_PRIC - (p.SUM_RCPT_EXPN_PRIC + p.SUM_PYMT_DSCN_DNRM)) = 0        
        AND EXISTS (
            SELECT *
              FROM dbo.Payment_Method pmt
             WHERE pmt.RQRO_RQST_RQID = pm.PYMT_RQST_RQID
               AND (Qx.FROM_RQST_DATE IS NULL OR CAST(pmt.ACTN_DATE AS DATE) >= CAST(Qx.FROM_RQST_DATE AS DATE))
               AND (Qx.TO_RQST_DATE IS NULL OR CAST(pmt.ACTN_DATE AS DATE) <= CAST(Qx.TO_RQST_DATE AS DATE))
        )
        --AND (Qx.FROM_RQST_DATE IS NULL OR CAST(pm.ACTN_DATE AS DATE) >= CAST(Qx.FROM_RQST_DATE AS DATE))
        --AND (Qx.TO_RQST_DATE IS NULL OR CAST(pm.ACTN_DATE AS DATE) <= CAST(Qx.TO_RQST_DATE AS DATE))
        
        AND (Qx.CRET_BY IS NULL OR Qx.CRET_BY = '' OR pm.CRET_BY = Qx.CRET_BY)
)

 
GO
