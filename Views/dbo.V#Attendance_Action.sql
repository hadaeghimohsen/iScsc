SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[V#Attendance_Action] AS 
SELECT  a.FIGH_FILE_NO ,
        a.NAME_DNRM ,
        a.ATTN_DATE ,
        dbo.GET_MTOS_U(a.MBSP_STRT_DATE_DNRM) AS MBSP_STRT_DATE_DNRM,
        dbo.GET_MTOS_U(a.MBSP_END_DATE_DNRM) AS MBSP_END_DATE_DNRM,
        ( SELECT    CAST(DERS_NUMB AS VARCHAR(10)) + ' ,'
          FROM      dbo.Attendance at
          WHERE     at.FIGH_FILE_NO = a.FIGH_FILE_NO
                    AND at.ATTN_DATE = a.ATTN_DATE
        FOR
          XML PATH('')
        ) AS DREN_NUMBS ,
        ( SELECT    ISNULL(at.ATTN_DESC, '') + ' ,'
          FROM      dbo.Attendance at
          WHERE     at.FIGH_FILE_NO = a.FIGH_FILE_NO
                    AND at.ATTN_DATE = a.ATTN_DATE
        FOR
          XML PATH('')
        ) AS ATTN_DESCS ,
        ( SELECT    SUM(ISNULL(pm.AMNT, 0))
          FROM      dbo.Payment_Method pm
          WHERE     pm.FIGH_FILE_NO_DNRM = a.FIGH_FILE_NO
                    AND CAST(pm.ACTN_DATE AS DATE) = a.ATTN_DATE
        ) AS PYMT_AMNT ,
        ( SELECT    SUM(ISNULL(pd.AMNT, 0))
          FROM      dbo.Payment_Discount pd
          WHERE     pd.FIGH_FILE_NO_DNRM = a.FIGH_FILE_NO
                    AND CAST(pd.CRET_DATE AS DATE) = a.ATTN_DATE
        ) AS PYDS_AMNT
FROM    dbo.Attendance a

GROUP BY a.FIGH_FILE_NO ,
        a.NAME_DNRM ,
        a.ATTN_DATE,
        dbo.GET_MTOS_U(a.MBSP_STRT_DATE_DNRM),
        dbo.GET_MTOS_U(a.MBSP_END_DATE_DNRM);

GO
