SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[INS_CUNT_P]
   @Blok_Cndo_Code VARCHAR(3)
  ,@Blok_Code VARCHAR(3)
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
   INSERT INTO dbo.Cando_Block_Unit           
           ( Blok_CNDO_CODE ,
             BLOK_CODE ,
             CODE ,
             NAME ,
             POST_ADRS ,
             CMNT ,
             CORD_X ,
             CORD_Y 
           )
   VALUES  ( @Blok_Cndo_Code , -- REGN_CODE - varchar(3)
             @Blok_Code ,
             @Code , -- CODE - varchar(3)
             @Name , -- NAME - nvarchar(250)
             @Post_Adrs , -- POST_ADRS - nvarchar(500)
             @Cmnt , -- CMNT - nvarchar(1000)
             @Cord_X , -- CORD_X - float
             @Cord_Y  -- CORD_Y - float             
           );
   
   COMMIT TRAN;
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
