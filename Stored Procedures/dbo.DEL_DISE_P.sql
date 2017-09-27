SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_DISE_P]
	-- Add the parameters for the stored procedure here
	@Code BIGINT
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>121</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 121 سطوح امینتی : شما مجوز حذف کردن وضعیت جسمی را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   IF NOT EXISTS(SELECT * FROM Fighter_Public WHERE RECT_CODE = '004' AND DISE_CODE = @Code)
      DELETE Diseases_Type
       WHERE CODE = @Code;
   ELSE
   BEGIN
      RAISERROR ( N'خطا - عدم حذف رکورد : با این کد وضعیت جسمی قبلا برای افراد در سابقه جسمانی آنها اطلاعات ثبت شده', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
      
END
GO
