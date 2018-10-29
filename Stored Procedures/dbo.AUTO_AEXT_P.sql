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
	
	   L$Loop:
	   DECLARE C$AutoAExtP CURSOR FOR
	      SELECT CODE, FIGH_FILE_NO, CLUB_CODE, A.MBSP_RWNO_DNRM
	        FROM dbo.Attendance A
	       WHERE A.EXIT_TIME IS NULL;
   	
	   DECLARE @Code BIGINT, 
	           @FileNo BIGINT,
	           @ClubCode BIGINT,
	           @AttnDate DATE,
	           @MbspRwno SMALLINT;
   	SET @AttnDate = DATEADD(HH, 1, GETDATE());
   	
	   OPEN C$AutoAExtP;
	   FNR_C$AutoAExtP:
	   FETCH NEXT FROM C$AutoAExtP INTO @Code, @FileNo, @ClubCode, @MbspRwno;
   	
	   IF @@FETCH_STATUS <> 0
	      GOTO END_C$AutoAExtP;
   	
   	UPDATE dbo.Attendance
   	   SET EXIT_TIME = GETDATE()
   	 WHERE CODE = @Code;
   	
   	--EXEC dbo.INS_ATTN_P @Club_Code = @ClubCode, -- bigint
   	--    @Figh_File_No = @FileNo, -- bigint
   	--    @Attn_Date = @AttnDate,
   	--    @CochFileNo = NULL,
   	--    @Attn_Type = '003',
   	--    @MbspRwno = @MbspRwno; -- date   	
   	
   	--UPDATE dbo.Session_Meeting
   	--   SET END_TIME = GETDATE()
   	-- WHERE MBSP_FIGH_FILE_NO = @FileNo
   	--   AND END_TIME IS NULL;
   	
	   GOTO FNR_C$AutoAExtP;
	   END_C$AutoAExtP:
	   CLOSE C$AutoAExtP;
	   DEALLOCATE C$AutoAExtP;
	   
	   -- 1396/07/16 * اگر گزینه هایی که جا مانده اند
	   IF EXISTS(SELECT CODE, FIGH_FILE_NO, CLUB_CODE
	        FROM dbo.Attendance A
	       WHERE A.EXIT_TIME IS NULL)
	   BEGIN
	      GOTO L$Loop;
	   END
   
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
