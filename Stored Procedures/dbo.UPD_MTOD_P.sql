SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_MTOD_P]
	-- Add the parameters for the stored procedure here
	@Code     BIGINT,
	@Mtod_Desc NVARCHAR(250),
	@Mtod_Code BIGINT,
	@Epit_Type VARCHAR(3),
	@Dflt_Stat VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>19</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 19 سطوح امینتی : شما مجوز ویرایش کردن سبک را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   UPDATE Method
      SET MTOD_DESC = @Mtod_Desc
         ,MTOD_CODE = @Mtod_Code
         ,Epit_Type = @Epit_Type
         ,DFLT_STAT = ISNULL(@Dflt_Stat, '001')
    WHERE CODE = @Code;
END
GO
