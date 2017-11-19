SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[VF$Club_Method_Fighter] ( @X XML )
RETURNS TABLE
AS 
RETURN
    (
WITH    QXML
          AS ( SELECT   @X.query('//Club_Method').value('(Club_Method/@code)[1]', 'BIGINT') AS CBMT_CODE 
                       ,@X.query('//Club_Method').value('(Club_Method/@cochfileno)[1]', 'BIGINT') AS COCH_FILE_NO
          )
    SELECT  f.FILE_NO ,
            f.NAME_DNRM ,
            f.FNGR_PRNT_DNRM ,
            dbo.GET_MTOS_U(f.MBSP_STRT_DATE) AS STRT_DATE,
            dbo.GET_MTOS_U(f.MBSP_END_DATE) AS END_DATE,
            f.INSR_NUMB_DNRM,
            CASE WHEN CAST(f.INSR_DATE_DNRM AS DATE) = '1900-01-01' THEN NULL ELSE dbo.GET_MTOS_U(f.INSR_DATE_DNRM) END AS INSR_DATE,
            f.CELL_PHON_DNRM ,
            f.DEBT_DNRM,
            c.FILE_NO AS COCH_FILE_NO,
            c.NAME_DNRM AS COCH_NAME_DNRM,
            cm.CODE AS CBMT_CODE,
            CAST(cm.STRT_TIME AS VARCHAR(5)) AS STRT_TIME ,
            CAST(cm.END_TIME AS VARCHAR(5)) AS END_TIME ,
            ms.NUMB_OF_MONT_DNRM,
            ms.NUMB_OF_DAYS_DNRM,
            ms.NUMB_OF_ATTN_MONT,
            ms.SUM_ATTN_MONT_DNRM,
            m.MTOD_DESC,
            cb.CTGY_DESC,
            sx.DOMN_DESC AS SEX_TYPE,
            dy.DOMN_DESC AS DAY_TYPE,
            cm.CBMT_DESC,
            cl.NAME AS CLUB_NAME,
            UPPER(SUSER_NAME()) AS CRNT_USER,
            dbo.GET_MTOS_U(GETDATE()) + CHAR(10) + CAST(CAST(GETDATE() AS TIME(0)) AS VARCHAR(5)) AS CRNT_DATE
    FROM    dbo.Fighter f ,
            dbo.Club_Method cm ,
            dbo.Club cl,
            dbo.Fighter c ,
            dbo.Method m ,
            dbo.Category_Belt cb,
            dbo.Member_Ship ms,
            dbo.[D$SXTP] sx,
            dbo.[D$DYTP] dy,            
            QXML Qx
    WHERE   f.CBMT_CODE_DNRM = cm.CODE
            AND cm.MTOD_CODE = m.CODE
            AND cb.MTOD_CODE = m.CODE
            AND f.CTGY_CODE_DNRM = cb.CODE
            AND cm.COCH_FILE_NO = c.FILE_NO
            AND ms.FIGH_FILE_NO = f.FILE_NO
            AND ms.RWNO = f.MBSP_RWNO_DNRM
            AND ms.RECT_CODE = '004'    
            AND cm.SEX_TYPE = sx.VALU
            AND cm.DAY_TYPE = dy.VALU        
            AND cm.CLUB_CODE = cl.CODE
            AND ( Qx.CBMT_CODE IS NULL
                  OR f.CBMT_CODE_DNRM = Qx.CBMT_CODE 
                )
            AND ( Qx.COCH_FILE_NO IS NULL
                  OR cm.COCH_FILE_NO = Qx.COCH_FILE_NO
                )
            AND (f.MBSP_END_DATE >= CAST(GETDATE() AS DATE))
);
  
GO
