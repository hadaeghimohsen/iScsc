SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_CEXC_P]
	-- Add the parameters for the stored procedure here
   @Code      BIGINT
  ,@Coch_File_No BIGINT
  ,@Epit_Code BIGINT
  ,@Rqtt_Code VARCHAR(3)
  ,@Coch_Deg  VARCHAR(3)
  ,@Extp_Code BIGINT
  ,@Mtod_Code BIGINT
  ,@Ctgy_Code BIGINT
  ,@Calc_Type VARCHAR(3)
  ,@Prct_Valu FLOAT
  ,@Stat      VARCHAR(3)
  ,@Rqtp_Code VARCHAR(3)
  ,@Calc_Expn_Type VARCHAR(3)
  ,@Pymt_Stat VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>126</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 126 سطوح امینتی : شما مجوز ویرایش کردن درصد مربی را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   IF EXISTS(
      SELECT *
        FROM dbo.Calculate_Expense_Coach
       WHERE COCH_DEG = @Coch_Deg
         AND EPIT_CODE = @Epit_Code
         AND RQTP_CODE = @Rqtp_Code
         AND RQTT_CODE = @Rqtt_Code
         --AND CALC_EXPN_TYPE = @Calc_Expn_Type
         --AND CALC_TYPE = @Calc_Type
         AND MTOD_CODE = @Mtod_Code
         AND CTGY_CODE = @Ctgy_Code
         AND COCH_FILE_NO = @Coch_File_No
         AND CODE != @Code
   )
   BEGIN
      RAISERROR (N'قبلا این آیتم در جدول های پایه برای این مربی وارد شده، لطفا اصلاح کنید', 16, 1);
      RETURN;
   END   
   
   UPDATE Calculate_Expense_Coach
      SET COCH_FILE_NO = @Coch_File_No
         ,EPIT_CODE    = @Epit_Code
         ,RQTT_CODE    = @Rqtt_Code
         ,COCH_DEG     = @Coch_Deg
         ,PRCT_VALU    = @Prct_Valu
         ,STAT         = @Stat
         ,EXTP_CODE    = @Extp_Code
         ,MTOD_CODE    = @Mtod_Code
         ,CTGY_CODE    = @Ctgy_Code
         ,CALC_TYPE    = @Calc_Type
         ,RQTP_CODE    = @Rqtp_Code
         ,CALC_EXPN_TYPE = @Calc_Expn_Type
         ,PYMT_STAT = @Pymt_Stat
    WHERE CODE = @Code;
END
GO
