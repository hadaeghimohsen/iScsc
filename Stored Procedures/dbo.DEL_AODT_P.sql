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
    
    -- بروزرسانی مبلغ میز
    UPDATE dbo.Aggregation_Operation_Detail
       SET END_TIME = GETDATE()
     WHERE AGOP_CODE = @Agop_Code
       AND RWNO = @Rwno
       AND END_TIME IS NULL;
    
    EXEC dbo.CALC_APDT_P @Agop_Code = @Agop_Code, -- bigint
       @Rwno = @Rwno -- bigint
    
    DECLARE @XTemp XML = (
      SELECT a.FIGH_FILE_NO AS '@fileno',
             '002' AS '@type',
             N'میز ' + ei.EPIT_DESC + N' از ساعت ' + CAST(a.STRT_TIME AS VARCHAR(5)) + N' شروع شده و تا ساعت ' + CAST(a.END_TIME AS VARCHAR(5)) + N' به مدت ' + CAST(a.TOTL_MINT_DNRM AS VARCHAR(10)) + N' دقیقه باز بوده که ارزش میز به مبلغ ' + 
             REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, a.TOTL_AMNT_DNRM), 1), '.00', '') + N' بوده که توسط کاربر ' + UPPER(SUSER_NAME()) + N' حذف شده است.' AS '@text'
        FROM dbo.Aggregation_Operation_Detail a, dbo.Expense e, dbo.Expense_Type et, dbo.Expense_Item ei
       WHERE a.AGOP_CODE = @Agop_Code
         AND a.RWNO = @Rwno
         AND e.CODE = a.EXPN_CODE
         AND e.EXTP_CODE = et.CODE
         AND et.EPIT_CODE = ei.CODE
         FOR XML PATH('Log')
    );    
    EXEC dbo.INS_LGOP_P @X = @XTemp -- xml    
    
    -- 1400/01/01
    DELETE  dbo.Aggregation_Operation_Detail
    WHERE   AGOP_CODE = @Agop_Code
            AND RWNO = @Rwno;
END;
GO
