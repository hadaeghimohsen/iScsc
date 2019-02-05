SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[V#StatisticReceipt]
AS
SELECT  YEAR ,
        CYCL ,
        RQTP_CODE ,
        SUM(AMNT) AS AMNT
FROM    dbo.V#ReceiptPayments
GROUP BY YEAR ,
        CYCL ,
        RQTP_CODE
GO
