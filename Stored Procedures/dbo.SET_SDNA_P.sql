SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SET_SDNA_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
BEGIN TRY	
   BEGIN TRAN T$SET_SDNA_P
   
   -- Local Params
   DECLARE @AttnCode BIGINT,
           @SharAttnCode BIGINT,
           @FileNo BIGINT;
   SELECT @AttnCode = @X.query('//Attendance').value('(Attendance/@code)[1]', 'BIGINT')
         ,@FileNo = @X.query('//Attendance').value('(Attendance/@fileno)[1]', 'BIGINT')
         ,@SharAttnCode = @X.query('//Attendance').value('(Attendance/@sharcode)[1]', 'BIGINT');
   
   -- Local Vars
      
   -- 1403/12/09 * اگر قبلا کمدی برای ایت حضور و غیاب ثبت شده آن را غیر فعال کنید
   DELETE dbo.Dresser_Attendance 
      --SET TKBK_TIME = GETDATE()
    WHERE ATTN_CODE = @AttnCode;
      --AND TKBK_TIME IS NULL;
   UPDATE dbo.Attendance SET DERS_NUMB = NULL, NUMB_OPEN_DNRM = 0 WHERE CODE = @AttnCode;
   
   INSERT INTO Dresser_Attendance (Dres_Code, Attn_Code, FIGH_FILE_NO, Code, Lend_Time, DERS_NUMB)
   SELECT TOP 1 
          da.DRES_CODE, @AttnCode, @FileNo, dbo.Gnrt_Nvid_U(), CAST(GETDATE() AS TIME(0)), da.DERS_NUMB
     FROM dbo.Dresser_Attendance da
    WHERE da.ATTN_CODE = @SharAttnCode
      AND da.TKBK_TIME IS NULL;
   
   -- اگر درخواست قفل کمدی با موفقیت انجام شود
   -- ثبت شماره قفل کمدی
   UPDATE dbo.Attendance 
      SET DERS_NUMB = (SELECT d.DRES_NUMB FROM dbo.Dresser_Attendance da, dbo.Dresser d WHERE da.ATTN_CODE = @AttnCode AND da.DRES_CODE = d.CODE AND da.DRAT_CODE IS NULL AND da.TKBK_TIME IS NULL)
    WHERE Code = @AttnCode;

   
   COMMIT TRAN [T$SET_SDNA_P]
END TRY
BEGIN CATCH
   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
   RAISERROR ( @ErorMesg, -- Message text.
            16, -- Severity.
            1 -- State.
            );
   ROLLBACK TRAN [T$SET_SDNA_P]
END CATCH
END
GO
