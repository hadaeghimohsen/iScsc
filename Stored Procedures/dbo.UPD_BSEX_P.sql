SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_BSEX_P]
	-- Add the parameters for the stored procedure here
   @Code      BIGINT
  ,@Epit_Code BIGINT
  ,@Rqtt_Code VARCHAR(3)
  ,@Coch_Deg  VARCHAR(3)
  ,@Prct_Valu FLOAT
  ,@Stat      VARCHAR(3)
  ,@Mtod_Code BIGINT
  ,@Ctgy_Code BIGINT
  ,@Calc_Expn_Type VARCHAR(3)
  ,@Calc_Type VARCHAR(3)
  ,@Rqtp_Code VARCHAR(3)
  ,@Pymt_Stat VARCHAR(3)
  ,@Min_Numb_Attn SMALLINT
  ,@Min_Attn_Stat VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>123</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 123 سطوح امینتی : شما مجوز ویرایش کردن درصد درجه مربیگری را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
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
        FROM dbo.Base_Calculate_Expense
       WHERE COCH_DEG = @Coch_Deg
         AND EPIT_CODE = @Epit_Code
         AND RQTP_CODE = @Rqtp_Code
         AND RQTT_CODE = @Rqtt_Code
         --AND CALC_EXPN_TYPE = @Calc_Expn_Type
         --AND CALC_TYPE = @Calc_Type
         AND MTOD_CODE = @Mtod_Code
         AND CTGY_CODE = @Ctgy_Code
         AND CODE != @Code
   )
   BEGIN
      RAISERROR (N'قبلا این آیتم در جدول های پایه وارد شده، لطفا اصلاح کنید', 16, 1);
      RETURN;
   END
   
   -- اگر نوع محاسبه تعداد جلسات باشد و نحوه محاسبه مبلغی باشد باید با خطا مواجه شود
   IF @Calc_Expn_Type = '002' AND @Calc_Type = '002'
   BEGIN
      RAISERROR (N'اگر نوع محاسبه تعداد جلسات باشد نمی توانید نحوه محاسبه مبلغی را انتخاب کنید، لطفا اصلاح کنید', 16, 1);
      RETURN;
   END;

   IF @Calc_Expn_Type IN ('003', '004', '005')
   BEGIN
     SELECT @Rqtp_Code = NULL
           ,@Rqtt_Code = NULL
           ,@Epit_Code = NULL
           ,@Coch_Deg = NULL
           ,@Min_Numb_Attn = CASE @Calc_Expn_Type WHEN '005' THEN @Min_Numb_Attn ELSE NULL END 
           ,@Min_Attn_Stat = CASE @Calc_Expn_Type WHEN '005' THEN @Min_Attn_Stat ELSE NULL END;
   END 
   
   UPDATE Calculate_Expense_Coach
      SET STAT = @Stat
    WHERE EPIT_CODE = @Epit_Code
      AND RQTT_CODE = @Rqtt_Code
      AND COCH_DEG  = @Coch_Deg
      AND MTOD_CODE = @Mtod_Code
      AND CTGY_CODE = @Ctgy_Code
      AND CALC_EXPN_TYPE = @Calc_Expn_Type
      AND CALC_TYPE = @Calc_Type
      AND RQTP_CODE = @Rqtp_Code
      AND PYMT_STAT = @Pymt_Stat
      AND MIN_NUMB_ATTN = @Min_Numb_Attn
      AND MIN_ATTN_STAT = @Min_Attn_Stat
      AND STAT      <> @Stat;
   
   UPDATE Base_Calculate_Expense
      SET EPIT_CODE = @Epit_Code
         ,RQTT_CODE = @Rqtt_Code
         ,COCH_DEG  = @Coch_Deg
         ,PRCT_VALU = @Prct_Valu
         ,STAT      = @Stat
         ,MTOD_CODE = @Mtod_Code
         ,CTGY_CODE = @Ctgy_Code
         ,CALC_EXPN_TYPE = @Calc_Expn_Type
         ,CALC_TYPE = @Calc_Type
         ,RQTP_CODE = @Rqtp_Code
         ,PYMT_STAT = @Pymt_Stat
         ,MIN_NUMB_ATTN = @Min_Numb_Attn
         ,MIN_ATTN_STAT = @Min_Attn_Stat
     WHERE CODE = @Code;
END
GO
