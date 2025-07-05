SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SMPL_PROC_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$SMPL_PROC_P]
   
   -- Local Params
   
   -- Local Vars	
   
   -- Run statements
   	
	COMMIT TRAN [T$SMPL_PROC_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1);
	   ROLLBACK TRAN [T$SMPL_PROC_P]
	END CATCH
END
GO
