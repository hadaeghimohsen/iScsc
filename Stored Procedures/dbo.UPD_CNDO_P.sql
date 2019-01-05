SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[UPD_CNDO_P]
   @Regn_Prvn_Cnty_Code VARCHAR(3)
  ,@Regn_Prvn_Code VARCHAR(3)
  ,@Regn_Code VARCHAR(3)
  ,@Code VARCHAR(3)
  ,@Name NVARCHAR(250)
  ,@Post_Adrs NVARCHAR(500)
  ,@Cmnt NVARCHAR(1000)
  ,@Cord_X FLOAT
  ,@Cord_Y FLOAT
AS 
BEGIN
   BEGIN TRY
   BEGIN TRAN
      UPDATE dbo.Cando
         SET NAME = @Name
            ,POST_ADRS = @Post_Adrs
            ,CMNT = @Cmnt
            ,CORD_X = @Cord_X
            ,CORD_Y = @Cord_Y
       WHERE REGN_PRVN_CNTY_CODE = @Regn_Prvn_Cnty_Code
         AND REGN_PRVN_CODE = @Regn_Prvn_Code
         AND REGN_CODE = @Regn_Code
         AND CODE = @Code;         
   COMMIT TRAN;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(Max);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH;
END;
GO
