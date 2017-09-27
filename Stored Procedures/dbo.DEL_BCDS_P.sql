SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_BCDS_P]
	-- Add the parameters for the stored procedure here
	@SUNT_BUNT_DEPT_ORGN_CODE VARCHAR(2),
	@SUNT_BUNT_DEPT_CODE VARCHAR(2),
	@SUNT_BUNT_CODE VARCHAR(2),
	@SUNT_CODE VARCHAR(4),
   @REGL_YEAR SMALLINT,
   @REGL_CODE INT,
   @Rwno INT
	
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>178</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 178 سطوح امینتی : شما مجوز حذف کردن تخفیفات سازمان و موسسه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی

   DELETE dbo.Basic_Calculate_Discount
    WHERE SUNT_BUNT_DEPT_ORGN_CODE = @SUNT_BUNT_DEPT_ORGN_CODE
      AND SUNT_BUNT_DEPT_CODE = @SUNT_BUNT_DEPT_CODE
      AND SUNT_BUNT_CODE = @SUNT_BUNT_CODE
      AND SUNT_CODE = @SUNT_CODE
      AND REGL_YEAR = @REGL_YEAR
      AND REGL_CODE = @REGL_CODE
      AND RWNO = @Rwno;         
END
GO
