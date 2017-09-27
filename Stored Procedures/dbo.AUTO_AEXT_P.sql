SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[AUTO_AEXT_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN T_C$AutoAExtP;
	
	   DECLARE C$AutoAExtP CURSOR FOR
	      SELECT CODE, FIGH_FILE_NO, CLUB_CODE
	        FROM dbo.Attendance A
	       WHERE A.EXIT_TIME IS NULL;
   	
	   DECLARE @Code BIGINT, 
	           @FileNo BIGINT,
	           @ClubCode BIGINT,
	           @AttnDate DATE;
   	SET @AttnDate = DATEADD(HH, 1, GETDATE());
   	
	   OPEN C$AutoAExtP;
	   FNR_C$AutoAExtP:
	   FETCH NEXT FROM C$AutoAExtP INTO @Code, @FileNo, @ClubCode;
   	
	   IF @@FETCH_STATUS <> 0
	      GOTO END_C$AutoAExtP;
   	
   	EXEC dbo.INS_ATTN_P @Club_Code = @ClubCode, -- bigint
   	    @Figh_File_No = @FileNo, -- bigint
   	    @Attn_Date = @AttnDate,
   	    @CochFileNo = NULL,
   	    @Attn_Type = '003'; -- date   	
   	
	   GOTO FNR_C$AutoAExtP;
	   END_C$AutoAExtP:
	   CLOSE C$AutoAExtP;
	   DEALLOCATE C$AutoAExtP;
   
   COMMIT TRAN T_C$AutoAExtP;
   END TRY
   BEGIN CATCH
      IF (SELECT CURSOR_STATUS('global','C$AutoAExtP')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('global','C$AutoAExtP')) > -1
         BEGIN
          CLOSE C$AutoAExtP
         END
       DEALLOCATE C$AutoAExtP
      END
      
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T_C$AutoAExtP;
   END CATCH;
   
END
GO
