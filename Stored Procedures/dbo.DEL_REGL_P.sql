SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_REGL_P]
	@Year SMALLINT
  ,@Code INT
AS
BEGIN
   -- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>5</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 5 سطوح امینتی : شما مجوز حذف آیین نامه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      GOTO L$End;
   END
   -- پایان دسترسی
   DELETE Regulation   
	 WHERE YEAR = @Year
	   AND CODE = @Code;
	
	L$End:
	RETURN;
END
GO