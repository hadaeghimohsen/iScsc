SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CALC_APDT_P]
	-- Add the parameters for the stored procedure here
	@Agop_Code BIGINT
  ,@Rwno BIGINT
AS
BEGIN
   UPDATE T
      SET T.END_TIME = GETDATE()         
    FROM dbo.Aggregation_Operation_Detail T, dbo.Expense E
    WHERE T.AGOP_CODE = @Agop_Code 
      AND T.RWNO = @Rwno
      AND T.EXPN_CODE = E.CODE
      AND T.EXPN_CODE IS NOT NULL;    
      
	UPDATE T
      SET T.EXPN_PRIC = ROUND(E.PRIC * T.TOTL_MINT_DNRM / 60, -3)
         ,T.EXPN_EXTR_PRCT = ROUND(E.EXTR_PRCT * T.TOTL_MINT_DNRM / 60, -3)
         ,T.TOTL_AMNT_DNRM = ISNULL(T.TOTL_BUFE_AMNT_DNRM, 0) + ISNULL(T.EXPN_PRIC, 0) + ISNULL(T.EXPN_EXTR_PRCT, 0)
    FROM dbo.Aggregation_Operation_Detail T, dbo.Expense E
    WHERE T.AGOP_CODE = @Agop_Code 
      AND T.RWNO = @Rwno
      AND T.EXPN_CODE = E.CODE
      AND T.EXPN_CODE IS NOT NULL;    
END
GO
