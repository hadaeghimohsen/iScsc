SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_CBMT_P]
	-- Add the parameters for the stored procedure here
   @Club_Code     BIGINT,
   @Mtod_Code     BIGINT,
   @Coch_File_No   BIGINT,
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
   @Natl_Code    VARCHAR(3)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>45</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 45 سطوح امینتی : شما مجوز اضافه کردن ساعت کلاسی برای سبک های ورزشی را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   --IF EXISTS(SELECT * FROM Club_Method WHERE MTOD_STAT = '002' AND CLUB_CODE = @ClubCode AND DAY_TYPE = @DayType AND (@StrtTime > STRT_TIME AND @StrtTime < END_TIME OR @EndTime > STRT_TIME AND @EndTime < END_TIME))
   --BEGIN
   --   RAISERROR ( N'خطا - تداخل ساعت کلاسی : ساعت کلاسی مربی با دیگر کلاس ها تداخل دارد', -- Message text.
   --            16, -- Severity.
   --            1 -- State.
   --            );
   --   RETURN;   
   --END
   
   /*DECLARE @MtodCode BIGINT;
   SELECT @MtodCode = MTOD_CODE_DNRM
     FROM Fighter
    WHERE FILE_NO = @CochFileNo
      AND CONF_STAT = '002';*/
   
   INSERT Club_Method (CLUB_CODE, MTOD_CODE, COCH_FILE_NO, STRT_TIME, END_TIME, MTOD_STAT, DAY_TYPE, SEX_TYPE, CBMT_DESC, DFLT_STAT, CPCT_NUMB, CPCT_STAT, CBMT_TIME, CBMT_TIME_STAT, CLAS_TIME, AMNT, NATL_CODE)
   VALUES (@Club_Code, @Mtod_Code, @Coch_File_No, @Strt_Time, @End_Time, '002', @Day_Type, @Sex_Type, @Cbmt_Desc, @Dflt_Stat, @Cpct_Numb, @Cpct_Stat, @Cbmt_Time, @Cbmt_Time_Stat, @Clas_Time, @Amnt, @Natl_Code);
END
GO
