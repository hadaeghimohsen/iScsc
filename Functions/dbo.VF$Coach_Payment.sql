SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[VF$Coach_Payment] ( @X XML )
RETURNS TABLE
AS 
RETURN
    (
WITH    QXML
          AS ( SELECT   @X.query('//Club_Method').value('(Club_Method/@code)[1]',
                                                        'BIGINT') AS CBMT_CODE ,
                        @X.query('//Club_Method').value('(Club_Method/@cochfileno)[1]',
                                                        'BIGINT') AS COCH_FILE_NO ,
                        @X.query('//Request').value('(Request/@fromrqstdate)[1]',
                                                    'DATE') AS FROM_RQST_DATE ,
                        @X.query('//Request').value('(Request/@torqstdate)[1]', 'DATE') AS TO_RQST_DATE ,
                        @X.query('//Request').value('(Request/@cretby)[1]', 'VARCHAR(250)') AS CRET_BY
             )
    SELECT  c.NAME_DNRM ,
            m.MTOD_DESC ,
            cb.CTGY_DESC ,
            p.SUM_RCPT_EXPN_PRIC,
            dbo.GET_MTOS_U(R.SAVE_DATE) AS SAVE_DATE,
            UPPER(SUSER_NAME()) AS CRNT_USER,
            dbo.GET_MTOS_U(GETDATE()) + CHAR(10) + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)) AS CRNT_DATE,
            
            -- Parameters Show
            dbo.GET_MTOS_U(Qx.FROM_RQST_DATE) AS PARM_FROM_RQST_DATE,
            dbo.GET_MTOS_U(Qx.TO_RQST_DATE) AS PARM_TO_RQST_DATE,
            Qx.CRET_BY AS PARM_CRET_BY
    FROM    dbo.Payment_Detail pd ,
            dbo.Fighter c ,
            dbo.Category_Belt cb ,
            dbo.Method m ,
            dbo.Payment p ,
            dbo.Request r ,
            QXML Qx
    WHERE   pd.PYMT_CASH_CODE = p.CASH_CODE
            AND pd.PYMT_RQST_RQID = p.RQST_RQID
            AND p.RQST_RQID = r.RQID
            AND c.FILE_NO = pd.FIGH_FILE_NO
            AND pd.CTGY_CODE_DNRM = cb.CODE
            AND pd.MTOD_CODE_DNRM = m.CODE
            AND m.CODE = cb.MTOD_CODE
            AND r.RQST_STAT = '002'
            AND r.RQTP_CODE IN ( '001', '009' )
            
            AND (Qx.CBMT_CODE IS NULL OR qx.CBMT_CODE = 0 OR (pd.CBMT_CODE_DNRM = Qx.CBMT_CODE))
            AND (Qx.COCH_FILE_NO IS NULL OR qx.COCH_FILE_NO = 0 OR (pd.FIGH_FILE_NO = Qx.COCH_FILE_NO))
            AND (Qx.FROM_RQST_DATE IS NULL OR (CAST(R.RQST_DATE AS DATE) >= Qx.FROM_RQST_DATE))
            AND (Qx.TO_RQST_DATE IS NULL OR (CAST(R.RQST_DATE AS DATE) <= Qx.TO_RQST_DATE))
            AND (Qx.CRET_BY IS NULL OR Qx.CRET_BY = '' OR (R.CRET_BY = Qx.CRET_BY))
);
  
GO
