SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_AUDT_P]
	-- Add the parameters for the stored procedure here
	@CODE BIGINT,
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
	BEGIN TRAN [T$UPD_AUDT_P]
	   UPDATE dbo.Audit
	      SET AUDT_DATE = @AUDT_DATE,
	          EXPN_AMNT = @EXPN_AMNT,
	          FEE_AMNT = @FEE_AMNT,
	          EXTR_PRCT_AMNT = @EXTR_PRCT_AMNT,
	          SUM_AMNT_DNRM = @SUM_AMNT_DNRM,
	          FBAC_CODE = @FBAC_CODE,
	          PAYC_CODE = @PAYC_CODE,
	          PAYC_CMNT = @PAYC_CMNT,
	          LETT_NO = @LETT_NO,
	          CMNT = @CMNT
	    WHERE CODE = @CODE;
	COMMIT TRAN [T$UPD_AUDT_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	   ROLLBACK TRAN [T$UPD_AUDT_P];
	END CATCH
END
GO
