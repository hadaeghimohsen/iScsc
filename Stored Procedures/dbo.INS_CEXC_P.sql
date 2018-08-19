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
    @Pymt_Stat VARCHAR(3)
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
         --AND CALC_EXPN_TYPE = @Calc_Expn_Type
         --AND CALC_TYPE = @Calc_Type
                        AND MTOD_CODE = @Mtod_Code
                        AND CTGY_CODE = @Ctgy_Code
                        AND COCH_FILE_NO = @Coch_File_No )
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

   
    INSERT  INTO Calculate_Expense_Coach
            ( CODE ,
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
              PYMT_STAT
            )
    VALUES  ( dbo.GNRT_NVID_U() ,
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
              @Rqtt_Code ,
              @Calc_Expn_Type ,
              @Pymt_Stat
            );
   
    IF NOT EXISTS ( SELECT  *
                    FROM    dbo.Calculate_Expense_Coach
                    WHERE   COCH_DEG = @Coch_Deg
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
            INSERT  INTO Calculate_Expense_Coach
                    ( CODE ,
                      EPIT_CODE ,
                      RQTT_CODE ,
                      COCH_DEG ,
                      COCH_FILE_NO ,
                      PRCT_VALU ,
                      STAT ,
                      MTOD_CODE ,
                      CTGY_CODE ,
                      CALC_EXPN_TYPE ,
                      CALC_TYPE ,
                      RQTP_CODE ,
                      PYMT_STAT
                    )
            VALUES  ( dbo.GNRT_NVID_U() ,
                      @Epit_Code ,
                      @Rqtt_Code ,
                      @Coch_Deg ,
                      @Coch_File_No ,
                      @Prct_Valu ,
                      @Stat ,
                      @Mtod_Code ,
                      @Ctgy_Code ,
                      @Calc_Expn_Type ,
                      @Calc_Type ,
                      CASE @Rqtp_Code
                        WHEN '001' THEN '009'
                        WHEN '009' THEN '001'
                      END ,
                      @Pymt_Stat
                    );
        END; 
END;
GO
