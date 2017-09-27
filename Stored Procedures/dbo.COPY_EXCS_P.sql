SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[COPY_EXCS_P]
	@REGL_YEAR SMALLINT,
	@REGL_CODE SMALLINT
AS
BEGIN
	-- بررسی اینکه آیا آیین نامه حساب فعالی درون سیستم هست که بتوان از اطلاعات حساب آن کپی برداری کرد یا خیر؟
   IF NOT EXISTS(
      SELECT *
        FROM Regulation
       WHERE TYPE = '002' -- آیین نامه حساب
         AND REGL_STAT = '002' -- فعال
   )   
      GOTO L$End;
   
   -- اگر آیین نامه حساب فعال درون سیستم وجود داشته باشد
   DECLARE C$RegulationAccount CURSOR FOR
   SELECT * FROM V#Regulation_Account
   WHERE TYPE = '002'
     AND REGL_STAT = '002';
   
   DECLARE @ReglYear SMALLINT
          ,@ReglCode INT
          ,@SubSys SMALLINT
          ,@Type   VARCHAR(3)
          ,@ReglStat VARCHAR(3)
          ,@RegnPrvnCntyCode VARCHAR(3)
          ,@RegnPrvnCode VARCHAR(3)
          ,@RegnCode VARCHAR(3)
          ,@ExtpCode BIGINT
          ,@CashCode BIGINT
          ,@ExcsStat VARCHAR(3);
   
   OPEN C$RegulationAccount;
   L$NextRARow:
   FETCH NEXT FROM C$RegulationAccount
   INTO @ReglYear
       ,@ReglCode
       ,@SubSys
       ,@Type
       ,@ReglStat
       ,@RegnPrvnCntyCode
       ,@RegnPrvnCode
       ,@RegnCode
       ,@ExtpCode
       ,@CashCode
       ,@ExcsStat;
       
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetchRA;
   
   IF NOT EXISTS(
      SELECT * 
      FROM V#Regulation_Account
      WHERE YEAR = @REGL_YEAR
        AND CODE = @REGL_CODE
        AND SUB_SYS = @SubSys
        AND TYPE    = @Type
        AND REGL_STAT = @ReglStat
        AND REGN_PRVN_CNTY_CODE = @RegnPrvnCntyCode
        AND REGN_PRVN_CODE = @RegnPrvnCode
        AND REGN_CODE = @RegnCode
        AND EXTP_CODE = @ExtpCode
        AND CASH_CODE = @CashCode
        AND EXCS_STAT = @ExcsStat
   )
   INSERT INTO Expense_Cash (REGL_YEAR,  REGL_CODE,  REGN_PRVN_CNTY_CODE, REGN_PRVN_CODE, REGN_CODE, EXTP_CODE, CASH_CODE, EXCS_STAT)
   VALUES                  (@REGL_YEAR, @REGL_CODE, @RegnPrvnCntyCode,   @RegnPrvnCode,  @RegnCode, @ExtpCode, @CashCode, @ExcsStat);

   GOTO L$NextRARow;
   L$EndFetchRA:
   CLOSE C$RegulationAccount;
   DEALLOCATE C$RegulationAccount;
   
   L$End:
   RETURN;
END
GO
