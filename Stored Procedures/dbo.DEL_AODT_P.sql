SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_AODT_P]
	-- Add the parameters for the stored procedure here
    @Agop_Code BIGINT ,
    @Rwno INT
AS
BEGIN
	-- بررسی دسترسی کاربر
    DECLARE @AP BIT ,
        @AccessString VARCHAR(250);
    SET @AccessString = N'<AP><UserName>' + SUSER_NAME()
        + '</UserName><Privilege>241</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
    EXEC iProject.dbo.sp_executesql N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',
        N'@P1 ntext, @ap BIT OUTPUT', @AccessString, @ap = @AP OUTPUT;
    IF @AP = 0
    BEGIN
        RAISERROR ( N'خطا - عدم دسترسی به ردیف 241 سطوح امینتی : شما مجوز حذف کردن آیتم میز رزرو شده را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
        RETURN;
    END;
   -- پایان دسترسی
   
    DELETE  dbo.Aggregation_Operation_Detail
    WHERE   AGOP_CODE = @Agop_Code
            AND RWNO = @Rwno;
END;
GO
