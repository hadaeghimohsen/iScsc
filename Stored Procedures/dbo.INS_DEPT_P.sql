SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_DEPT_P]
	-- Add the parameters for the stored procedure here
	@OrgnCode VARCHAR(2),
	@Code VARCHAR(2),
	@DeptDesc NVARCHAR(250)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>172</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 172 سطوح امینتی : شما مجوز اضافه کردن سازمان و موسسه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   INSERT INTO dbo.Department
           ( ORGN_CODE ,
             CODE ,
             DEPT_DESC 
           )
   VALUES  ( @OrgnCode , -- ORGN_CODE - varchar(2)
             @Code , -- CODE - varchar(2)
             @DeptDesc  -- DEPT_DESC - nvarchar(250)
           );
END
GO
