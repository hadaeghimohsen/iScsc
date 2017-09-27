SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VD#SaleReceiptDiscount] AS 
SELECT s.YEAR, s.CYCL, SUM(s.EXPN_PRIC + s.EXPN_EXTR_PRCT) AS SALE_AMNT, 
      (SELECT SUM(amnt) FROM dbo.V#ReceiptPayments rp WHERE rp.YEAR = s.YEAR AND rp.CYCL = s.CYCL ) AS RCPT_AMNT,
      (SELECT SUM(amnt) FROM dbo.V#DiscountPayments dp WHERE dp.YEAR = s.YEAR AND dp.CYCL = s.CYCL) AS PYDS_AMNT
  FROM dbo.V#Sales s
GROUP BY s.year, s.CYCL
GO
