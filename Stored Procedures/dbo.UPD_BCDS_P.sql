SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_BCDS_P]
	-- Add the parameters for the stored procedure here
	@SUNT_BUNT_DEPT_ORGN_CODE VARCHAR(2),
	@SUNT_BUNT_DEPT_CODE VARCHAR(2),
	@SUNT_BUNT_CODE VARCHAR(2),
	@SUNT_CODE VARCHAR(4),
   @REGL_YEAR SMALLINT,
   @REGL_CODE INT,
   @Rwno INT,
   @EPIT_CODE BIGINT,
   @RQTP_CODE VARCHAR(3),
   @RQTT_CODE VARCHAR(3),
   @AMNT_DSCT INT,
   @PRCT_DSCT INT,
   @DSCT_TYPE VARCHAR(3),
   @Stat VARCHAR(3),
   @ACTN_TYPE VARCHAR(3),
   @DSCT_DESC NVARCHAR(500),
   @FROM_DATE DATE,
   @TO_DATE DATE ,
   @CTGY_CODE BIGINT,
   @EXPN_CODE BIGINT
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>177</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 177 سطوح امینتی : شما مجوز ویرایش کردن تخفیفات سازمان و موسسه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   IF @SUNT_BUNT_DEPT_ORGN_CODE IS NULL
      RAISERROR(N'کد ارگان مشخصی وارد نشده', 16, 1);
      
   IF @SUNT_BUNT_DEPT_CODE IS NULL
      RAISERROR(N'کد سازمان تابعه مشخصی وارد نشده', 16, 1);

   IF @SUNT_BUNT_CODE IS NULL
      RAISERROR(N'کد مجموعه اصلی مشخصی وارد نشده', 16, 1);

   IF @SUNT_CODE IS NULL
      RAISERROR(N'کد مجموعه فرعی مشخصی وارد نشده', 16, 1);
   
   IF @REGL_YEAR IS NULL OR @REGL_CODE IS NULL
      RAISERROR(N'آیین نامه مشخصی وارد نشده مشخصی وارد نشده', 16, 1);
    
   IF @SUNT_BUNT_DEPT_ORGN_CODE IS NULL
      RAISERROR(N'کد ارگان مشخصی وارد نشده', 16, 1);
   
   IF @EPIT_CODE IS NULL
      RAISERROR(N'آیتم درآمدی مشخصی وارد نشده', 16, 1);
   
   IF @DSCT_TYPE IS NULL
      RAISERROR(N'نوع محاسبه تخفیف مشخصی وارد نشده', 16, 1); 
   
   IF @DSCT_TYPE = '001' AND @PRCT_DSCT IS NULL
      RAISERROR(N'میزان درصد تخفیف مشخصی وارد نشده', 16, 1);
   
   IF @DSCT_TYPE = '002' AND @AMNT_DSCT IS NULL 
      RAISERROR(N'میزان مبلغ تخفیف مشخصی وارد نشده', 16, 1);
   
   IF @ACTN_TYPE IS NULL 
      RAISERROR(N'نوع تخفیف مشخصی وارد نشده', 16, 1);
   
   IF @ACTN_TYPE NOT IN ( '001', '004', '005', '009', '010' ) AND @FROM_DATE IS NULL
      RAISERROR(N'فیلد "از تاریخ" وارد نشده', 16, 1);
   
   IF @ACTN_TYPE NOT IN ( '001', '004', '005', '009', '010' ) AND @TO_DATE IS NULL
      RAISERROR(N'فیلد "تا تاریخ" وارد نشده', 16, 1);   
   
   IF @RQTP_CODE IS NULL
      RAISERROR(N'نوع درخواست وارد نشده', 16, 1);
   
   IF @RQTT_CODE IS NULL SET @RQTT_CODE = '001'
      --RAISERROR(N'نوع متقاصی وارد نشده', 16, 1);
      
   IF @CTGY_CODE IS NULL
      RAISERROR(N'نوع زیر گروه وارد نشده', 16, 1);
      
   UPDATE dbo.Basic_Calculate_Discount
      SET EPIT_CODE = @EPIT_CODE
         ,RQTP_CODE = @RQTP_CODE
         ,RQTT_CODE = @RQTT_CODE
         ,AMNT_DSCT = @AMNT_DSCT
         ,PRCT_DSCT = @PRCT_DSCT
         ,DSCT_TYPE = @DSCT_TYPE
         ,STAT = @Stat
         ,ACTN_TYPE = @ACTN_TYPE
         ,DSCT_DESC = @DSCT_DESC
         ,FROM_DATE = @FROM_DATE
         ,TO_DATE = @TO_DATE
         ,CTGY_CODE = @CTGY_CODE
         ,EXPN_CODE = @EXPN_CODE
    WHERE SUNT_BUNT_DEPT_ORGN_CODE = @SUNT_BUNT_DEPT_ORGN_CODE
      AND SUNT_BUNT_DEPT_CODE = @SUNT_BUNT_DEPT_CODE
      AND SUNT_BUNT_CODE = @SUNT_BUNT_CODE
      AND SUNT_CODE = @SUNT_CODE
      AND REGL_YEAR = @REGL_YEAR
      AND REGL_CODE = @REGL_CODE
      AND RWNO = @Rwno;         
END
GO
