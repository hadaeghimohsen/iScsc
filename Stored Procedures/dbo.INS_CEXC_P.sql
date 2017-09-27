SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_CEXC_P]
	-- Add the parameters for the stored procedure here
   @Coch_File_No BIGINT
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
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>125</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 125 سطوح امینتی : شما مجوز اضافه کردن درصد مربی را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   INSERT INTO Calculate_Expense_Coach (CODE, EPIT_CODE, RQTT_CODE, COCH_DEG, PRCT_VALU, STAT, COCH_FILE_NO)
   VALUES (dbo.GNRT_NVID_U(), @Epit_Code, @Rqtt_Code, @Coch_Deg, @Prct_Valu, @Stat, @Coch_File_No);
END
GO
