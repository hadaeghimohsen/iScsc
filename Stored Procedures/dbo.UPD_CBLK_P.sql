SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[UPD_CBLK_P]
   @Cndo_Code VARCHAR(3)
  ,@Code VARCHAR(3)
  ,@Name NVARCHAR(250)
  ,@Post_Adrs NVARCHAR(500)
  ,@Cmnt NVARCHAR(1000)
  ,@Cord_X FLOAT
  ,@Cord_Y FLOAT
AS 
BEGIN
   BEGIN TRY
   BEGIN TRAN [UPD_CBLK_T]
      UPDATE dbo.Cando_Block
         SET NAME = @Name
            ,POST_ADRS = @Post_Adrs
            ,CMNT = @Cmnt
            ,CORD_X = @Cord_X
            ,CORD_Y = @Cord_Y
       WHERE CNDO_CODE = @Cndo_Code
         AND CODE = @Code;         
   COMMIT TRAN [UPD_CBLK_T]
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(Max);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN [UPD_CBLK_T]
   END CATCH;
END;
GO
