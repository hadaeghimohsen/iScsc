SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[DEL_CNDO_P]
   @Regn_Prvn_Cnty_Code VARCHAR(3)
  ,@Regn_Prvn_Code VARCHAR(3)
  ,@Regn_Code VARCHAR(3)
  ,@Code VARCHAR(3)
AS 
BEGIN
   BEGIN TRY
   BEGIN TRAN      
      DELETE dbo.Cando
       WHERE REGN_PRVN_CNTY_CODE = @Regn_Prvn_Cnty_Code
         AND REGN_PRVN_CODE = @Regn_Prvn_Code
         AND REGN_CODE = @Regn_Code
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
