SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_AUDT_P]
	-- Add the parameters for the stored procedure here
	@CODE BIGINT	
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$DEL_AUDT_P]
	   DELETE dbo.Audit
	    WHERE CODE = @CODE;
	COMMIT TRAN [T$DEL_AUDT_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	   ROLLBACK TRAN [T$DEL_AUDT_P];
	END CATCH
END
GO
