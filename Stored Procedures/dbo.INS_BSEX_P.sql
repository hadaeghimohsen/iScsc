SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_BSEX_P]
	-- Add the parameters for the stored procedure here
	@Epit_Code BIGINT
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
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>122</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 122 سطوح امینتی : شما مجوز اضافه کردن درصد درجه مربیگری را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   INSERT INTO Base_Calculate_Expense 
   (CODE, EPIT_CODE, RQTT_CODE, COCH_DEG, PRCT_VALU, STAT, MTOD_CODE, CTGY_CODE,
    CALC_EXPN_TYPE, CALC_TYPE, RQTP_CODE, PYMT_STAT)
   VALUES (dbo.GNRT_NVID_U(), @Epit_Code, @Rqtt_Code, @Coch_Deg, @Prct_Valu, @Stat,
    @Mtod_Code, @Ctgy_Code, @Calc_Expn_Type, @Calc_Type, @Rqtp_Code, @Pymt_Stat);
END
GO
