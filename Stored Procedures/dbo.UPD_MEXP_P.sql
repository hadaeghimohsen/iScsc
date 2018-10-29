SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_MEXP_P]
	-- Add the parameters for the stored procedure here
	@Code BIGINT,
	@Club_Code BIGINT,
	@Epit_Code BIGINT,
	@Coch_File_No BIGINT,
	@Vald_Type VARCHAR(3),
	@Calc_Expn_Type VARCHAR(3),
	@Decr_Prct FLOAT,
	@Delv_Stat VARCHAR(3),
	@Delv_Date DATE,
	@Delv_By NVARCHAR(250),
	@Expn_Amnt BIGINT,
	@Expn_Desc NVARCHAR(500),
	@Qnty FLOAT
AS
BEGIN
	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>212</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 212 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   UPDATE dbo.Misc_Expense
      SET CLUB_CODE = @Club_Code
         ,EPIT_CODE = @Epit_Code
         ,COCH_FILE_NO = @Coch_File_No
         ,EXPN_AMNT = @Expn_Amnt
         ,EXPN_DESC = @Expn_Desc
         ,CALC_EXPN_TYPE = @Calc_Expn_Type
         ,DECR_PRCT = @Decr_Prct
         ,DELV_STAT = @Delv_Stat
         ,DELV_DATE = @Delv_Date
         ,DELV_BY = @Delv_By
         ,VALD_TYPE = @Vald_Type
         ,QNTY = @Qnty
    WHERE CODE = @Code;
END
GO
