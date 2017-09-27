SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_BSEX_P]
	-- Add the parameters for the stored procedure here
   @Code      BIGINT
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>124</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 124 سطوح امینتی : شما مجوز حذف کردن درصد درجه مربیگری را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی

	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>127</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 127 سطوح امینتی : شما مجوز حذف کردن درصد مربی را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   DELETE Calculate_Expense_Coach
    WHERE EXISTS(
      SELECT *
        FROM Base_Calculate_Expense b
       WHERE b.EPIT_CODE = EPIT_CODE
         AND b.RQTT_CODE = RQTT_CODE
         AND b.COCH_DEG  = COCH_DEG
         AND b.CODE      = @Code
    );
    
   DELETE Base_Calculate_Expense
    WHERE CODE = @Code;
END
GO
