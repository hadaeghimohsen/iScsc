SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_FBAC_P]
	-- Add the parameters for the stored procedure here
	@CODE BIGINT,
	@FIGH_FILE_NO BIGINT,
	@ACNT_NUMB VARCHAR(100),
	@CARD_NUMB VARCHAR(16),
	@SHBA_NUMB VARCHAR(100),
	@CMNT NVARCHAR(500)
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$UPD_FBAC_P]
	   
	   IF NOT EXISTS(
	         SELECT * 
	           FROM dbo.Fighter_Bank_Account a
	          WHERE a.FIGH_FILE_NO = @FIGH_FILE_NO
	            AND a.CODE != @CODE
	            AND ((ISNULL(@ACNT_NUMB, '') = '' OR a.ACNT_NUMB = @ACNT_NUMB)
	             OR (ISNULL(@CARD_NUMB, '') = '' OR a.CARD_NUMB = @CARD_NUMB)
	             OR (ISNULL(@SHBA_NUMB, '') = '' OR a.SHBA_NUMB = @SHBA_NUMB))
	      )
	   BEGIN
	      UPDATE dbo.Fighter_Bank_Account
	         SET ACNT_NUMB = @ACNT_NUMB
	            ,CARD_NUMB = @CARD_NUMB
	            ,SHBA_NUMB = @SHBA_NUMB
	            ,CMNT = @CMNT
	       WHERE CODE = @CODE;
	   END;
	   
	COMMIT TRAN [T$UPD_FBAC_P];	 
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16 ,1);
	   ROLLBACK TRAN [T$UPD_FBAC_P];
	END CATCH	
END
GO
