SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_USCP_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$DEL_USCP_P]
   
   -- Local Params
   DECLARE @UserId BIGINT;
   SELECT @UserId = @X.query('//User').value('(User/@id)[1]', 'BIGINT')
   
   -- Local Vars
   DECLARE @SchmCode BIGINT,
           @SchmBy VARCHAR(250);
   
   -- Run statements
   SELECT @SchmBy = USER_DB FROM dbo.V#Users WHERE ID = @UserId;
   
   SELECT @SchmCode = sp.CODE FROM dbo.Schema_Profile sp WHERE sp.SCHM_BY = @SchmBy;
   IF ISNULL(@SchmCode, 0) != 0 
   BEGIN
      DELETE dbo.Sound WHERE SCHM_CODE = @SchmCode;
      DELETE dbo.Schema_Profile WHERE CODE = @SchmCode;
   END
   	
	COMMIT TRAN [T$DEL_USCP_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErorMesg, 16, 1);
	   ROLLBACK TRAN [T$DEL_USCP_P]
	END CATCH
END
GO
