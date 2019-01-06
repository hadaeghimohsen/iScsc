SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[DEL_CUNT_P]
   @Blok_Cndo_Code VARCHAR(3)
  ,@Blok_Code VARCHAR(3)
  ,@Code VARCHAR(3)
AS 
BEGIN
   BEGIN TRY
   BEGIN TRAN [DEL_CUNT_T]
      DELETE dbo.Cando_Block_Unit
       WHERE BLOK_CNDO_CODE = @Blok_Cndo_Code
         AND BLOK_CODE = @Blok_Code
         AND CODE = @Code;         
   
   COMMIT TRAN [DEL_CUNT_T]
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN [DEL_CUNT_T]
   END CATCH
END;
GO
