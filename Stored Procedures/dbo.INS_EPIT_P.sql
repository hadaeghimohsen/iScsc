SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_EPIT_P]
	-- Add the parameters for the stored procedure here
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
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>38</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 38 سطوح امینتی : شما مجوز اضافه کردن آیتم هزینه جدید را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   IF @Epit_Desc IS NULL OR LEN(@Epit_Desc) = 0 BEGIN RAISERROR(N'نام آیتم هزینه وارد نشده', 16, 1); END
   IF LEN(@Type) = 0 BEGIN RAISERROR(N'نوع آیتم هزینه وارد نشده', 16, 1); END
   IF LEN(@Rqtp_Code) = 0 BEGIN SET @Rqtp_Code = NULL; END
   IF LEN(@Rqtt_Code) = 0 BEGIN SET @Rqtt_Code = NULL; END
   
   INSERT INTO Expense_Item (EPIT_DESC, TYPE, RQTT_CODE, RQTP_CODE, IMAG)
   VALUES (@Epit_Desc, @Type, @Rqtt_Code, @Rqtp_Code, @Imag);
END
GO
