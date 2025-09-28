SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_AUDT_P]
	-- Add the parameters for the stored procedure here
	@FIGH_FILE_NO BIGINT,
	@AUDT_DATE DATETIME,
	@EXPN_AMNT BIGINT,
	@FEE_AMNT BIGINT,
	@EXTR_PRCT_AMNT BIGINT,
	@SUM_AMNT_DNRM BIGINT,
   @FBAC_CODE BIGINT,
   @PAYC_CODE BIGINT,
   @PAYC_CMNT NVARCHAR(500),
   @LETT_NO VARCHAR(15),
   @CMNT NVARCHAR(2000)
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$INS_AUDT_P]
	   INSERT INTO dbo.Audit
	           ( FIGH_FILE_NO ,
	             CODE ,	             
	             AUDT_DATE ,
	             EXPN_AMNT ,
	             FEE_AMNT ,
	             EXTR_PRCT_AMNT ,
	             SUM_AMNT_DNRM,
	             FBAC_CODE ,
	             PAYC_CODE ,
	             PAYC_CMNT ,
	             LETT_NO ,
	             CMNT 
	           )
	   VALUES  ( @FIGH_FILE_NO , -- FIGH_FILE_NO - bigint
	             0 , -- CODE - bigint
	             @AUDT_DATE , -- AUDT_DATE - datetime
	             @EXPN_AMNT , -- EXPN_AMNT - bigint
	             @FEE_AMNT , -- FEE_AMNT - bigint
	             @EXTR_PRCT_AMNT , -- EXTR_PRCT_AMNT - bigint
	             @SUM_AMNT_DNRM ,
	             @FBAC_CODE , -- FBAC_CODE - bigint
	             @PAYC_CODE , -- PAYC_CODE - bigint
	             @PAYC_CMNT , -- PAYC_CMNT - nvarchar(500)
	             @LETT_NO , -- LETT_NO - varchar(15)
	             @CMNT
	           );
	COMMIT TRAN [T$INS_AUDT_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	   ROLLBACK TRAN [T$INS_AUDT_P];
	END CATCH
END
GO
