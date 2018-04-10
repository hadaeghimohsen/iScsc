SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[VF$Fighter_Attendance] ( @X XML )
RETURNS TABLE
    AS 
RETURN
    (
WITH    QXML
          AS ( SELECT   @X.query('//Club_Method').value('(Club_Method/@code)[1]',
                                                        'BIGINT') AS CBMT_CODE ,
                        @X.query('//Club_Method').value('(Club_Method/@cochfileno)[1]',
                                                        'BIGINT') AS COCH_FILE_NO ,
                        @X.query('//Club_Method').value('(Club_Method/@ctgycode)[1]',
                                                        'BIGINT') AS CTGY_CODE ,
                        @X.query('//Attendance').value('(Attendance/@fromdate)[1]',
                                                       'DATE') AS FROM_ATTN_DATE ,
                        @X.query('//Attendance').value('(Attendance/@todate)[1]',
                                                       'DATE') AS TO_ATTN_DATE
             )
    SELECT  TResult.NAME_DNRM ,
            TResult.COCH_NAME_DNRM ,
            TResult.STRT_DATE ,
            TResult.MTOD_DESC ,
            TResult.CTGY_DESC ,
            TResult.NUMB_OF_ATTN_MONT ,
            TResult.SUM_ATTN_MONT_DNRM ,
            TResult.NUMB_OF_REMN ,
            TResult.AMNT ,
            TResult.TOTL_AMNT
      -- Parameters Show
            ,
            dbo.GET_MTOS_U(Qx.FROM_ATTN_DATE) AS PARM_FROM_ATTN_DATE ,
            dbo.GET_MTOS_U(Qx.TO_ATTN_DATE) AS PARM_TO_ATTN_DATE ,
            UPPER(SUSER_NAME()) AS PARM_CRET_BY
    FROM    ( SELECT    f.NAME_DNRM ,
                        c.NAME_DNRM AS COCH_NAME_DNRM ,
                        dbo.GET_MTOS_U(m.STRT_DATE) AS STRT_DATE ,
                        mt.MTOD_DESC ,
                        cb.CTGY_DESC ,
                        m.NUMB_OF_ATTN_MONT ,
                        m.SUM_ATTN_MONT_DNRM ,
                        ( m.NUMB_OF_ATTN_MONT - m.SUM_ATTN_MONT_DNRM ) AS NUMB_OF_REMN ,
                        cm.AMNT ,
                        SUM(cm.AMNT) AS TOTL_AMNT
              FROM      dbo.Attendance a ,
                        dbo.Fighter f ,
                        dbo.Fighter c ,
                        dbo.Member_Ship m ,
                        dbo.Fighter_Public fp ,
                        dbo.Club_Method cm ,
                        dbo.Method mt ,
                        dbo.Category_Belt cb ,
                        QXML Qx
              WHERE     a.FIGH_FILE_NO = f.FILE_NO
                        AND a.COCH_FILE_NO = c.FILE_NO
                        AND a.FIGH_FILE_NO = m.FIGH_FILE_NO
                        AND a.MBSP_RWNO_DNRM = m.RWNO
                        AND m.RECT_CODE = '004'
                        AND m.FIGH_FILE_NO = fp.FIGH_FILE_NO
                        AND m.FGPB_RWNO_DNRM = fp.RWNO
                        AND m.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
                        AND fp.RECT_CODE = '004'
                        AND fp.CBMT_CODE = cm.CODE
                        AND fp.MTOD_CODE = mt.CODE
                        AND fp.CTGY_CODE = cb.CODE
                        AND ( Qx.CBMT_CODE IS NULL
                              OR Qx.CBMT_CODE = 0
                              OR ( fp.CBMT_CODE = Qx.CBMT_CODE )
                            )
                        AND ( Qx.COCH_FILE_NO IS NULL
                              OR Qx.COCH_FILE_NO = 0
                              OR ( fp.COCH_FILE_NO = Qx.COCH_FILE_NO )
                            )
                        AND ( Qx.CTGY_CODE IS NULL
                              OR Qx.CTGY_CODE = 0
                              OR ( fp.CTGY_CODE = Qx.CTGY_CODE )
                            )
                        AND ( Qx.FROM_ATTN_DATE IS NULL
                              OR ( CAST(a.ATTN_DATE AS DATE) >= Qx.FROM_ATTN_DATE )
                            )
                        AND ( Qx.TO_ATTN_DATE IS NULL
                              OR ( CAST(a.ATTN_DATE AS DATE) <= Qx.TO_ATTN_DATE )
                            )
              GROUP BY  f.NAME_DNRM ,
                        c.NAME_DNRM ,
                        m.STRT_DATE ,
                        mt.MTOD_DESC ,
                        cb.CTGY_DESC ,
                        m.NUMB_OF_ATTN_MONT ,
                        m.SUM_ATTN_MONT_DNRM ,
                        ( m.NUMB_OF_ATTN_MONT - m.SUM_ATTN_MONT_DNRM ) ,
                        cm.AMNT
            ) TResult ,
            QXML Qx
);
GO
