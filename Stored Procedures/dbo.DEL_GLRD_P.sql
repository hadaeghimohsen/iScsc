SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_GLRD_P]
	@X XML
AS
BEGIN
   BEGIN TRY
   BEGIN TRAN DEL_GLRD_T
	   -- SET NOCOUNT ON added to prevent extra result sets from
	   -- interfering with SELECT statements.
	   SET NOCOUNT ON;

      DECLARE @GlrdGlid BIGINT
             ,@Rwno SMALLINT;
      
      SELECT @GlrdGlid = @X.value('(Gain_Loss_Rail_Detail/@glrlglid)[1]', 'BIGINT')
            ,@Rwno = @X.value('(Gain_Loss_Rail_Detail/@rwno)[1]', 'SMALLINT');
      
      DELETE dbo.Gain_Loss_Rail_Detail
       WHERE GLRL_GLID = @GlrdGlid
         AND RWNO = @Rwno;
      COMMIT TRAN DEL_GLRD_T;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN DEL_GLRD_T;   
   END CATCH
END
GO
