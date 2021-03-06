SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_BSEX_P]
	-- Add the parameters for the stored procedure here
    @Epit_Code BIGINT ,
    @Rqtt_Code VARCHAR(3) ,
    @Coch_Deg VARCHAR(3) ,
    @Prct_Valu FLOAT ,
    @Stat VARCHAR(3) ,
    @Mtod_Code BIGINT ,
    @Ctgy_Code BIGINT ,
    @Calc_Expn_Type VARCHAR(3) ,
    @Calc_Type VARCHAR(3) ,
    @Rqtp_Code VARCHAR(3) ,
    @Pymt_Stat VARCHAR(3) ,
    @Min_Numb_Attn SMALLINT ,
    @Min_Attn_Stat VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
    DECLARE @AP BIT ,
        @AccessString VARCHAR(250);
    SET @AccessString = N'<AP><UserName>' + SUSER_NAME()
        + '</UserName><Privilege>122</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
    EXEC iProject.dbo.sp_executesql N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',
        N'@P1 ntext, @ap BIT OUTPUT', @AccessString, @ap = @AP OUTPUT;
    IF @AP = 0
        BEGIN
            RAISERROR ( N'خطا - عدم دسترسی به ردیف 122 سطوح امینتی : شما مجوز اضافه کردن درصد درجه مربیگری را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
            RETURN;
        END;
   -- پایان دسترسی
   
    IF EXISTS ( SELECT  *
                FROM    dbo.Base_Calculate_Expense
                WHERE   COCH_DEG = @Coch_Deg
                        AND EPIT_CODE = @Epit_Code
                        AND RQTP_CODE = @Rqtp_Code
                        AND RQTT_CODE = @Rqtt_Code
         --AND CALC_EXPN_TYPE = @Calc_Expn_Type
         --AND CALC_TYPE = @Calc_Type
                        AND MTOD_CODE = @Mtod_Code
                        AND CTGY_CODE = @Ctgy_Code )
        BEGIN
            RAISERROR (N'قبلا این آیتم در جدول های پایه وارد شده، لطفا اصلاح کنید', 16, 1);
            RETURN;
        END;
   
   -- اگر نوع محاسبه تعداد جلسات باشد و نحوه محاسبه مبلغی باشد باید با خطا مواجه شود
    IF @Calc_Expn_Type = '002'
        AND @Calc_Type = '002'
        BEGIN
            RAISERROR (N'اگر نوع محاسبه تعداد جلسات باشد نمی توانید نحوه محاسبه مبلغی را انتخاب کنید، لطفا اصلاح کنید', 16, 1);
            RETURN;
        END;
    
    IF @Calc_Expn_Type IN ('003', '004', '005')
    BEGIN
      SELECT @Rqtp_Code = NULL
            ,@Rqtt_Code = NULL
            ,@Epit_Code = NULL
            ,@Coch_Deg = NULL
            ,@Min_Numb_Attn = CASE @Calc_Expn_Type WHEN '005' THEN @Min_Numb_Attn ELSE NULL END 
            ,@Min_Attn_Stat = CASE @Calc_Expn_Type WHEN '005' THEN @Min_Attn_Stat ELSE NULL END;
    END 
    
    INSERT  INTO Base_Calculate_Expense
            ( CODE ,
              EPIT_CODE ,
              RQTT_CODE ,
              COCH_DEG ,
              PRCT_VALU ,
              STAT ,
              MTOD_CODE ,
              CTGY_CODE ,
              CALC_EXPN_TYPE ,
              CALC_TYPE ,
              RQTP_CODE ,
              PYMT_STAT ,
              MIN_NUMB_ATTN ,
              MIN_ATTN_STAT
            )
    VALUES  ( dbo.GNRT_NVID_U() ,
              @Epit_Code ,
              @Rqtt_Code ,
              @Coch_Deg ,
              @Prct_Valu ,
              @Stat ,
              @Mtod_Code ,
              @Ctgy_Code ,
              @Calc_Expn_Type ,
              @Calc_Type ,
              @Rqtp_Code ,
              @Pymt_Stat ,
              @Min_Numb_Attn ,
              @Min_Attn_Stat
            );
    
    IF @Calc_Expn_Type NOT IN ('003', '004', '005')
    AND NOT EXISTS ( SELECT  *
                    FROM    dbo.Base_Calculate_Expense
                    WHERE   COCH_DEG = @Coch_Deg
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
            INSERT  INTO Base_Calculate_Expense
                    ( CODE ,
                      EPIT_CODE ,
                      RQTT_CODE ,
                      COCH_DEG ,
                      PRCT_VALU ,
                      STAT ,
                      MTOD_CODE ,
                      CTGY_CODE ,
                      CALC_EXPN_TYPE ,
                      CALC_TYPE ,
                      RQTP_CODE ,
                      PYMT_STAT ,
                      MIN_NUMB_ATTN ,
                      MIN_ATTN_STAT
                    )
            VALUES  ( dbo.GNRT_NVID_U() ,
                      @Epit_Code ,
                      @Rqtt_Code ,
                      @Coch_Deg ,
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
                      @Pymt_Stat ,
                      @Min_Numb_Attn ,
                      @Min_Attn_Stat
                    );
        END; 
END;
GO
