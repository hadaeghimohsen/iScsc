SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_REGN_P]
	-- Add the parameters for the stored procedure here
	@CntyCode VARCHAR(3),
	@PrvnCode VARCHAR(3),
	@Code VARCHAR(3),
	@Name NVARCHAR(250),
	@RegnCode VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>34</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 34 سطوح امینتی : شما مجوز اضافه کردن ناحیه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   INSERT INTO Region (PRVN_CNTY_CODE, PRVN_CODE, CODE, NAME, REGN_CODE)
   VALUES (@CntyCode, @PrvnCode, @Code, @Name, @RegnCode);
END
GO
