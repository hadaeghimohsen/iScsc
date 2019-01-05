SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[DEL_CBLK_P]
   @Cndo_Code VARCHAR(3)
  ,@Code VARCHAR(3)
AS 
BEGIN
   BEGIN TRY
   BEGIN TRAN      
      DELETE dbo.Cando_Block
       WHERE CNDO_CODE = @Cndo_Code
         AND CODE = @Code;         
   
   COMMIT TRAN   
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN;
   END CATCH
END;
GO
