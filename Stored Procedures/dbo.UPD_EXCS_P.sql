SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_EXCS_P]
	@REGNPRVNCNTYCODE VARCHAR(3)
  ,@REGNPRVNCODE VARCHAR(3)
  ,@REGNCODE VARCHAR(3)
  ,@REGLYEAR SMALLINT
  ,@REGLCODE INT
  ,@EXTPCODE BIGINT
  ,@CASHCODE BIGINT
  ,@EXCSSTAT VARCHAR(3)
AS
BEGIN
	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>6</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 6 سطوح امینتی : شما مجوز ویرایش کردن آیین نامه حساب را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      GOTO L$End;
   END
   -- پایان دسترسی
   
   UPDATE Expense_Cash
      SET EXCS_STAT = CASE CASH_CODE WHEN @CASHCODE THEN '002' ELSE '001' END
    WHERE REGN_PRVN_CNTY_CODE = @REGNPRVNCNTYCODE
      AND REGN_PRVN_CODE = @REGNPRVNCODE
      AND REGN_CODE = @REGNCODE
      AND REGL_CODE = @REGLCODE
      AND REGL_YEAR = @REGLYEAR
      AND EXTP_CODE = @EXTPCODE;
   L$End:
   RETURN;
END
GO
