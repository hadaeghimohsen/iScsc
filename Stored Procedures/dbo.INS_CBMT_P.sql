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
   @ClubCode     BIGINT,
   --@MtodCode     BIGINT,
   @CochFileNo   BIGINT,
   @DayType      VARCHAR(3),
   @StrtTime     TIME(0),
   @EndTime      TIME(0)
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
   
   IF EXISTS(SELECT * FROM Club_Method WHERE MTOD_STAT = '002' AND CLUB_CODE = @ClubCode AND DAY_TYPE = @DayType AND (@StrtTime > STRT_TIME AND @StrtTime < END_TIME OR @EndTime > STRT_TIME AND @EndTime < END_TIME))
   BEGIN
      RAISERROR ( N'خطا - تداخل ساعت کلاسی : ساعت کلاسی مربی با دیگر کلاس ها تداخل دارد', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;   
   END
   
   DECLARE @MtodCode BIGINT;
   SELECT @MtodCode = MTOD_CODE_DNRM
     FROM Fighter
    WHERE FILE_NO = @CochFileNo
      AND CONF_STAT = '002';
   
   INSERT Club_Method (CLUB_CODE, MTOD_CODE, COCH_FILE_NO, STRT_TIME, END_TIME, MTOD_STAT, DAY_TYPE)
   VALUES (@ClubCode, @MtodCode, @CochFileNo, @StrtTime, @EndTime, '002', @DayType);
END
GO
