SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- View

CREATE VIEW [dbo].[V#Attendance_Action]
AS
    SELECT  a.FIGH_FILE_NO ,
            a.NAME_DNRM ,
            a.ATTN_DATE ,
            dbo.GET_MTOS_U(a.ATTN_DATE) AS ATTN_DATE_DNRM ,
            CAST(MIN(a.ENTR_TIME) AS VARCHAR(10)) AS ENTR_TIME ,
            CAST(MAX(a.EXIT_TIME) AS VARCHAR(10)) AS EXIT_TIME,
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
            ( SELECT    CASE pm.RCPT_MTOD
                          WHEN '001' THEN N'نقدی'
                          WHEN '003' THEN pm.FLOW_NO
                        END + N', '
              FROM      dbo.Payment_Method pm
              WHERE     pm.FIGH_FILE_NO_DNRM = a.FIGH_FILE_NO
                        AND CAST(pm.ACTN_DATE AS DATE) = a.ATTN_DATE
              FOR XML PATH('')
            ) AS PYMT_DESC
    FROM    dbo.Attendance a
    GROUP BY a.FIGH_FILE_NO ,
            a.NAME_DNRM ,
            a.ATTN_DATE ,
            dbo.GET_MTOS_U(a.ATTN_DATE) ;




GO
