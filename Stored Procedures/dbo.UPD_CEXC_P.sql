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
  ,@Prct_Valu FLOAT
  ,@Stat      VARCHAR(3)
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
   
   UPDATE Calculate_Expense_Coach
      SET COCH_FILE_NO = @Coch_File_No
         ,EPIT_CODE    = @Epit_Code
         ,RQTT_CODE    = @Rqtt_Code
         ,COCH_DEG     = @Coch_Deg
         ,PRCT_VALU    = @Prct_Valu
         ,STAT         = @Stat
    WHERE CODE = @Code;
END
GO
