SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[V#Inventory] as
SELECT  ei.EPIT_DESC ,
        ei.CODE ,
        SUM(me.QNTY) AS IN_CONT ,
        SUM(me.EXPN_AMNT) IN_AMNT ,
        ( SELECT    SUM(pd.QNTY)
          FROM      dbo.Expense_Type et ,
                    dbo.Expense e ,
                    dbo.Payment_Detail pd ,
                    dbo.Request r
          WHERE     et.EPIT_CODE = ei.CODE
                    AND et.CODE = e.EXTP_CODE
                    AND e.CODE = pd.EXPN_CODE
                    AND pd.PYMT_RQST_RQID = r.RQID
                    AND r.RQST_STAT = '002'
        ) AS OUT_CONT,
        ( SELECT    SUM(pd.EXPN_PRIC + pd.EXPN_EXTR_PRCT * pd.QNTY)
          FROM      dbo.Expense_Type et ,
                    dbo.Expense e ,
                    dbo.Payment_Detail pd ,
                    dbo.Request r
          WHERE     et.EPIT_CODE = ei.CODE
                    AND et.CODE = e.EXTP_CODE
                    AND e.CODE = pd.EXPN_CODE
                    AND pd.PYMT_RQST_RQID = r.RQID
                    AND r.RQST_STAT = '002'
        ) AS OUT_AMNT
FROM    dbo.Expense_Item ei ,
        dbo.Misc_Expense me
WHERE   ei.CODE = me.EPIT_CODE
        AND ei.TYPE = '001'
GROUP BY ei.EPIT_DESC, ei.CODE;
GO
