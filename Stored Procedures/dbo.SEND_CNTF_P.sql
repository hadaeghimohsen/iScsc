SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SEND_CNTF_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN T$SEND_CNTF_P;
	
	COMMIT TRAN [T$SEND_CNTF_P];
	END TRY
	BEGIN CATCH
   DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
   RAISERROR ( @ErrorMessage, -- Message text.
            16, -- Severity.
            1 -- State.
            );
   ROLLBACK TRAN [T$SEND_CNTF_P];
	END CATCH
END
GO
