SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SYNC_RGL2_P]
	@NewReglYear SMALLINT
  ,@NewReglCode INT
  ,@OldReglYear SMALLINT
  ,@OldReglCode INT
AS
BEGIN
   --RAISERROR('MIRE', 16, 1);
   IF (@OldReglCode >= @NewReglCode AND @OldReglYear >= @NewReglYear) RETURN ;   
   
	MERGE dbo.Expense_Cash T
	USING (
	   SELECT *
	     FROM dbo.Expense_Cash S
	    WHERE S.Regl_Year = @OldReglYear
	      AND S.Regl_Code = @OldReglCode
	      AND S.Excs_Stat = '002'
	) S
	ON (T.Regl_Year = @NewReglYear AND T.Regl_Code = @NewReglCode
   AND T.Extp_Code = S.Extp_Code
	AND T.Cash_Code = S.Cash_Code 
	AND T.Regn_Code = S.Regn_Code 
	AND T.Regn_Prvn_Code = S.Regn_Prvn_Code)
	WHEN MATCHED THEN
	   UPDATE
	      SET Excs_Stat = S.Excs_Stat;
END
GO
