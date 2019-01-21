SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_EPIT_P]
	-- Add the parameters for the stored procedure here
	@Code     BIGINT,
	@Epit_Desc NVARCHAR(250),
	--@Qnty     SMALLINT,
	@Type     VARCHAR(3),
	@Rqtp_Code VARCHAR(3),
	@Rqtt_Code VARCHAR(3),
	@Imag IMAGE	
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>39</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 39 سطوح امینتی : شما مجوز ویرایش کردن آیتم هزینه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   IF LEN(@Rqtp_Code) = 0 BEGIN SET @Rqtp_Code = NULL; END
   IF LEN(@Rqtt_Code) = 0 BEGIN SET @Rqtt_Code = NULL; END
   
   UPDATE Expense_Item 
      SET EPIT_DESC = @Epit_Desc
         ,RQTP_CODE = @Rqtp_Code
         ,RQTT_CODE = @Rqtt_Code
         --,QNTY = @Qnty
         ,TYPE = @Type
         ,IMAG = @Imag
    WHERE CODE = @Code;
END
GO
