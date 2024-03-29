SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_CEXC_P]
	-- Add the parameters for the stored procedure here
    @Expn_Code BIGINT,
    @Coch_File_No BIGINT ,
    @Epit_Code BIGINT ,
    @Rqtt_Code VARCHAR(3) ,
    @Coch_Deg VARCHAR(3) ,
    @Extp_Code BIGINT ,
    @Mtod_Code BIGINT ,
    @Ctgy_Code BIGINT ,
    @Calc_Type VARCHAR(3) ,
    @Prct_Valu FLOAT ,
    @Stat VARCHAR(3) ,
    @Rqtp_Code VARCHAR(3) ,
    @Calc_Expn_Type VARCHAR(3) ,
    @Pymt_Stat VARCHAR(3),
    @Min_Numb_Attn SMALLINT,
    @Min_Attn_Stat VARCHAR(3),
    @Rduc_Amnt BIGINT,
    @Cbmt_Code BIGINT,
    @Efct_Date_Type VARCHAR(3),
    @Expr_Pay_Day INT,
    @Tax_Prct_Valu INT,
    @Fore_Givn_Attn_Numb INT
AS
BEGIN
 	-- بررسی دسترسی کاربر
    DECLARE @AP BIT ,
        @AccessString VARCHAR(250);
    SET @AccessString = N'<AP><UserName>' + SUSER_NAME()
        + '</UserName><Privilege>125</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
    EXEC iProject.dbo.sp_executesql N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',
        N'@P1 ntext, @ap BIT OUTPUT', @AccessString, @ap = @AP OUTPUT;
    IF @AP = 0
        BEGIN
            RAISERROR ( N'خطا - عدم دسترسی به ردیف 125 سطوح امینتی : شما مجوز اضافه کردن درصد مربی را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
            RETURN;
        END;
   -- پایان دسترسی

    IF EXISTS ( SELECT  *
                FROM    dbo.Calculate_Expense_Coach
                WHERE   COCH_DEG = @Coch_Deg
                        AND EPIT_CODE = @Epit_Code
                        AND RQTP_CODE = @Rqtp_Code
                        AND RQTT_CODE = @Rqtt_Code                        
                        AND MTOD_CODE = @Mtod_Code
                        AND CTGY_CODE = @Ctgy_Code
                        AND COCH_FILE_NO = @Coch_File_No)
        BEGIN
            RAISERROR (N'قبلا این آیتم در جدول های پایه برای این مربی وارد شده، لطفا اصلاح کنید', 16, 1);
            RETURN;
        END;
   
   -- اگر نوع محاسبه تعداد جلسات باشد و نحوه محاسبه مبلغی باشد باید با خطا مواجه شود
    IF @Calc_Expn_Type = '002'
        AND @Calc_Type = '002'
        BEGIN
            RAISERROR (N'اگر نوع محاسبه تعداد جلسات باشد نمی توانید نحوه محاسبه مبلغی را انتخاب کنید، لطفا اصلاح کنید', 16, 1);
            RETURN;
        END;

    IF @Calc_Expn_Type IN ('003', '004', '005', '006')
    BEGIN
      SELECT @Rqtp_Code = NULL
            ,@Rqtt_Code = NULL
            ,@Epit_Code = NULL
            ,@Coch_Deg = NULL
            ,@Min_Numb_Attn = CASE @Calc_Expn_Type WHEN '005' THEN @Min_Numb_Attn ELSE NULL END 
            ,@Min_Attn_Stat = CASE @Calc_Expn_Type WHEN '005' THEN @Min_Attn_Stat ELSE NULL END;
    END 
   
    INSERT  INTO Calculate_Expense_Coach
            ( CODE ,
              EXPN_CODE ,
              EPIT_CODE ,
              RQTT_CODE ,
              COCH_DEG ,
              PRCT_VALU ,
              STAT ,
              COCH_FILE_NO ,
              EXTP_CODE ,
              MTOD_CODE ,
              CTGY_CODE ,
              CALC_TYPE ,
              RQTP_CODE ,
              CALC_EXPN_TYPE ,
              PYMT_STAT,
              MIN_NUMB_ATTN,
              MIN_ATTN_STAT,
              RDUC_AMNT,
              CBMT_CODE,
              EFCT_DATE_TYPE,
              EXPR_PAY_DAY,
              TAX_PRCT_VALU,
              FORE_GIVN_ATTN_NUMB
            )
    VALUES  ( dbo.GNRT_NVID_U() ,
              @Expn_Code ,
              @Epit_Code ,
              @Rqtt_Code ,
              @Coch_Deg ,
              @Prct_Valu ,
              @Stat ,
              @Coch_File_No ,
              @Extp_Code ,
              @Mtod_Code ,
              @Ctgy_Code ,
              @Calc_Type ,
              @Rqtp_Code ,
              @Calc_Expn_Type ,
              @Pymt_Stat,
              @Min_Numb_Attn,
              @Min_Attn_Stat,
              @Rduc_Amnt,
              @Cbmt_Code,
              @Efct_Date_Type,
              @Expr_Pay_Day,
              @Tax_Prct_Valu,
              @Fore_Givn_Attn_Numb
            );
   
    IF @Calc_Expn_Type NOT IN ('003', '004', '005', '006')
    AND @Rqtp_Code IN ('001', '009')
    AND NOT EXISTS ( SELECT *
                       FROM dbo.Calculate_Expense_Coach
                      WHERE COCH_DEG = @Coch_Deg
                            AND COCH_FILE_NO = @Coch_File_No
                            AND MTOD_CODE = @Mtod_Code
                            AND CTGY_CODE = @Ctgy_Code
                            AND CALC_EXPN_TYPE = @Calc_Expn_Type
                            AND CALC_TYPE = @Calc_Type
                            AND PRCT_VALU = @Prct_Valu
                            AND STAT = @Stat
                            AND EPIT_CODE = @Epit_Code
                            AND RQTT_CODE = @Rqtt_Code
                            AND RQTP_CODE = CASE @Rqtp_Code
                                              WHEN '001' THEN '009'
                                              WHEN '009' THEN '001'
                                            END )
        BEGIN
            -- 1401/08/13 * مرگ بر خامنه ای کصکش
            -- ابتدا اگر نوع هزینه ثبت نام باشد باید متوجه شویم که معادل آن در تمدید چیست یا برعکس
            SET @Expn_Code = NULL;
            SELECT @Expn_Code = e.CODE,
                   @Extp_Code = e.EXTP_CODE
              FROM dbo.Expense e, dbo.Expense_Type et,
                   dbo.Request_Requester rr
             WHERE e.EXTP_CODE = et.CODE
               AND et.RQRQ_CODE = rr.CODE
               AND rr.RQTT_CODE = '001'
               AND rr.RQTP_CODE = CASE @Rqtp_Code WHEN '001' THEN '009' ELSE '001' END
               AND e.MTOD_CODE = @Mtod_Code
               AND e.CTGY_CODE = @Ctgy_Code;
            
            IF @Expn_Code IS NOT NULL 
            BEGIN 
               INSERT  INTO Calculate_Expense_Coach
               ( CODE ,EXPN_CODE ,EPIT_CODE ,RQTT_CODE ,COCH_DEG , EXTP_CODE,
               COCH_FILE_NO ,PRCT_VALU ,STAT ,MTOD_CODE ,CTGY_CODE ,
               CALC_EXPN_TYPE ,CALC_TYPE ,RQTP_CODE ,PYMT_STAT ,
               MIN_NUMB_ATTN,MIN_ATTN_STAT,RDUC_AMNT,CBMT_CODE,
               EFCT_DATE_TYPE,EXPR_PAY_DAY,TAX_PRCT_VALU,FORE_GIVN_ATTN_NUMB)
               VALUES  
               (dbo.GNRT_NVID_U() ,
                @Expn_Code , @Epit_Code , @Rqtt_Code , @Coch_Deg , @Extp_Code ,
                @Coch_File_No , @Prct_Valu , @Stat , @Mtod_Code , @Ctgy_Code ,
                @Calc_Expn_Type , @Calc_Type ,
                CASE @Rqtp_Code
                  WHEN '001' THEN '009'
                  WHEN '009' THEN '001'
                END , @Pymt_Stat,
                @Min_Numb_Attn, @Min_Attn_Stat, @Rduc_Amnt, @Cbmt_Code,
                @Efct_Date_Type, @Expr_Pay_Day, @Tax_Prct_Valu, @Fore_Givn_Attn_Numb
               );
            END 
        END; 
END;

GO
