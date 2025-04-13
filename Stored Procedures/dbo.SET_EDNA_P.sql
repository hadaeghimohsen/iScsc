SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SET_EDNA_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
BEGIN TRY	
   BEGIN TRAN T$SET_EDNA_P
   
   -- Local Params
   DECLARE @AttnCode BIGINT;
   SELECT @AttnCode = @X.query('//Attendance').value('(Attendance/@code)[1]', 'BIGINT');
   
   -- Local Vars
      
   -- 1403/12/09 * اگر قبلا کمدی برای ایت حضور و غیاب ثبت شده آن را غیر فعال کنید
   DELETE dbo.Dresser_Attendance 
      --SET TKBK_TIME = GETDATE()
    WHERE ATTN_CODE = @AttnCode;
      --AND TKBK_TIME IS NULL;
   UPDATE dbo.Attendance SET DERS_NUMB = NULL, NUMB_OPEN_DNRM = 0 WHERE CODE = @AttnCode;

   COMMIT TRAN [T$SET_EDNA_P]
END TRY
BEGIN CATCH
   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
   RAISERROR ( @ErorMesg, -- Message text.
            16, -- Severity.
            1 -- State.
            );
   ROLLBACK TRAN [T$SET_EDNA_P]
END CATCH
END
GO
