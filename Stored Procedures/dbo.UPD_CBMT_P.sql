SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_CBMT_P]
	-- Add the parameters for the stored procedure here
   @Code     BIGINT,
   @Club_Code     BIGINT,
   @Mtod_Code     BIGINT,
   @Coch_File_No   BIGINT,
   @Mtod_Stat     VARCHAR(3),
   @Day_Type      VARCHAR(3),
   @Strt_Time     TIME(0),
   @End_Time      TIME(0),
   @Sex_Type      VARCHAR(3),
   @Cbmt_Desc     NVARCHAR(250),
   @Dflt_Stat     VARCHAR(3),
   @Cpct_Numb     INT,
   @Cpct_Stat     VARCHAR(3),
   @Cbmt_Time     INT,
   @Cbmt_Time_Stat VARCHAR(3),
   @Clas_Time     INT,
   @Amnt         BIGINT,
   @Natl_Code VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>46</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 46 سطوح امینتی : شما مجوز ویرایش کردن ساعت کلاسی سبک های ورزشی را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   --IF EXISTS(SELECT * FROM Club_Method WHERE MTOD_STAT = '002' AND CODE <> @CbmtCode AND DAY_TYPE = @DayType AND (@StrtTime > STRT_TIME AND @StrtTime < END_TIME OR @EndTime > STRT_TIME AND @EndTime < END_TIME))
   --BEGIN
   --   RAISERROR ( N'خطا - تداخل ساعت کلاسی : ساعت کلاسی مربی با دیگر کلاس ها تداخل دارد', -- Message text.
   --            16, -- Severity.
   --            1 -- State.
   --            );
   --   RETURN;   
   --END

   
   --DECLARE @MtodCode BIGINT;
   --SELECT @MtodCode = MTOD_CODE_DNRM
   --  FROM Fighter
   -- WHERE FILE_NO = @CochFileNo
   --   AND CONF_STAT = '002';

   UPDATE Club_Method
      SET CLUB_CODE = @Club_Code
         ,COCH_FILE_NO = @Coch_File_No
         ,MTOD_CODE = @Mtod_Code
         ,DAY_TYPE = @Day_Type
         ,STRT_TIME = @Strt_Time
         ,END_TIME = @End_Time
         ,MTOD_STAT = @Mtod_Stat
         ,SEX_TYPE = @Sex_Type
         ,CBMT_DESC = @Cbmt_Desc
         ,DFLT_STAT = @Dflt_Stat
         ,CPCT_NUMB = @Cpct_Numb
         ,CPCT_STAT = @Cpct_Stat
         ,CBMT_TIME = @Cbmt_Time
         ,CBMT_TIME_STAT = @Cbmt_Time_Stat
         ,CLAS_TIME = @Clas_Time
         ,AMNT = @Amnt
         ,NATL_CODE = @Natl_Code
    WHERE CODE = @Code;
END
GO
