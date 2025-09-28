SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_FBAC_P]
	-- Add the parameters for the stored procedure here
	@CODE BIGINT	
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$DEL_FBAC_P]
	   
	   IF NOT EXISTS(SELECT * FROM dbo.Audit WHERE FBAC_CODE = @CODE)
	   BEGIN	   
	      DELETE dbo.Fighter_Bank_Account
	       WHERE CODE = @CODE;
	   END;
	   
	COMMIT TRAN [T$DEL_FBAC_P];	 
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16 ,1);
	   ROLLBACK TRAN [T$DEL_FBAC_P];
	END CATCH	
END
GO
