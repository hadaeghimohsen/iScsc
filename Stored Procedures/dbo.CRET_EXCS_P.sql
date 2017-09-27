SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_EXCS_P]
	-- Add the parameters for the stored procedure here
	@CashCode BIGINT     = NULL,
	@ReglYear SMALLINT   = NULL,
	@ReglCode INT        = NULL,
	@ExtpCode BIGINT     = NULL,
	@RegnCode VARCHAR(3) = NULL,
	@PrvnCode VARCHAR(3) = NULL,
	@CntyCode VARCHAR(3) = NULL 
AS
BEGIN
   IF @CashCode IS NOT NULL
   BEGIN
      -- اگر صندوق جدیدی ایجاد شده باشد
      BEGIN TRY
         SELECT @ReglCode = CODE
               ,@ReglYear = YEAR
           FROM Regulation
          WHERE TYPE = '002' -- آیین نامه حساب
            AND REGL_STAT = '002'; -- فعال
      END TRY
      BEGIN CATCH
         RAISERROR ( N'آیین نامه حساب فعالی درون سیستم وجود ندارد', -- Message text.
               16, -- Severity.
               1 -- State.
               );
         GOTO L$End;
      END CATCH  
      
      -- آیین نامه فعال پیدا شد
      DECLARE C#REGNS CURSOR FOR
         SELECT CODE
               ,PRVN_CODE
               ,PRVN_CNTY_CODE
           FROM Region
          WHERE CODE <> '999'
       ORDER BY CODE;
      
      DECLARE C#EXTPS CURSOR FOR
         WITH Regl_Expn(YEAR, CODE) AS
         (
            SELECT CODE
                  ,YEAR
              FROM Regulation
             WHERE TYPE = '001' -- آیین نامه هزینه
               AND REGL_STAT = '002' -- فعال 
         )
         SELECT Extp.Code 
           FROM Regulation Regl
               ,Request_Requester Rqrq
               ,Regl_Expn re
               ,Expense_Type Extp
          WHERE Regl.YEAR = Rqrq.REGL_YEAR
            AND Regl.YEAR = re.YEAR
            AND Regl.CODE = Rqrq.REGL_CODE
            AND Regl.CODE = re.CODE
            AND Rqrq.CODE = Extp.RQRQ_CODE 
       ORDER BY RQRQ.Rqtp_Code;
      
      -- بررسی جدول ناحیه 
      OPEN C#REGNS;
      L$NextCashRegn:
      FETCH NEXT FROM C#REGNS 
      INTO @RegnCode
          ,@PrvnCode
          ,@CntyCode;

      IF @@FETCH_STATUS <> 0
         GOTO L$EndCashRegn;
      
      -- بررسی جدول نوع هزینه
      OPEN C#EXTPS;
      L$NextCashExtp:
      FETCH NEXT FROM C#EXTPS
      INTO @ExtpCode;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndCashExtp;

      IF NOT EXISTS(
         SELECT *
           FROM dbo.Expense_Cash ec
          WHERE ec.CASH_CODE           = @CashCode
            AND ec.REGL_YEAR           = @ReglYear
            AND ec.REGL_CODE           = @ReglCode
            AND ec.REGN_CODE           = @RegnCode
            AND ec.REGN_PRVN_CODE      = @PrvnCode
            AND ec.REGN_PRVN_CNTY_CODE = @CntyCode
            AND ec.EXTP_CODE           = @ExtpCode
      )
      BEGIN
         INSERT INTO dbo.Expense_Cash ( CASH_CODE, REGL_YEAR, REGL_CODE, EXTP_CODE, REGN_CODE, REGN_PRVN_CODE, REGN_PRVN_CNTY_CODE, EXCS_STAT)
                               VALUES (@CashCode ,@ReglYear ,@ReglCode ,@ExtpCode ,@RegnCode , @PrvnCode     ,@CntyCode           , '001');
      END
      
      GOTO L$NextCashExtp;
      L$EndCashExtp:
      CLOSE C#EXTPS;      
      -- پایان بررسی نوع هزینه
      
      GOTO L$NextCashRegn;
      L$EndCashRegn:   
      CLOSE C#REGNS;
      
      -- برای خارج کردن تمامی منابعی که برای 
      -- Cursor
      -- مورد استفاده قرار گرفته است
      DEALLOCATE C#EXTPS;      
      DEALLOCATE C#REGNS;      
      -- پایان بررسی جدول ناحیه
      
      GOTO L$End;   
   END
   ELSE IF @ExtpCode IS NOT NULL
   BEGIN
      -- اگر صندوق جدیدی ایجاد شده باشد
      BEGIN TRY
         SELECT @ReglCode = CODE
               ,@ReglYear = YEAR
           FROM Regulation
          WHERE TYPE      = '002'  -- آیین نامه حساب
            AND REGL_STAT = '002'; -- فعال
      END TRY
      BEGIN CATCH
         RAISERROR ( N'آیین نامه حساب فعالی درون سیستم وجود ندارد', -- Message text.
               16, -- Severity.
               1 -- State.
               );
         GOTO L$End;
      END CATCH 

      DECLARE @ExcsStat VARCHAR(3);
      
      DECLARE C#ExtpCash CURSOR FOR
         SELECT CODE, TYPE
         FROM dbo.Cash;
      
      DECLARE C#ExtpRegn CURSOR FOR
         SELECT CODE
               ,PRVN_CODE
               ,PRVN_CNTY_CODE
           FROM dbo.Region;
      
      OPEN C#ExtpRegn;
      L$NextExtpRegn:
      FETCH NEXT FROM C#ExtpRegn 
      INTO @RegnCode
          ,@PrvnCode
          ,@CntyCode;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndExtpRegn;
      
      OPEN C#ExtpCash;
      L$NextExtpCash:
      FETCH NEXT FROM C#ExtpCash 
      INTO @CashCode, @ExcsStat;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndExtpCash;
         
      IF NOT EXISTS(
         SELECT *
           FROM dbo.Expense_Cash ec
          WHERE ec.CASH_CODE           = @CashCode
            AND ec.REGL_YEAR           = @ReglYear
            AND ec.REGL_CODE           = @ReglCode
            AND ec.REGN_CODE           = @RegnCode
            AND ec.REGN_PRVN_CODE      = @PrvnCode
            AND ec.REGN_PRVN_CNTY_CODE = @CntyCode
            AND ec.EXTP_CODE           = @ExtpCode
      )
      BEGIN
         
         INSERT INTO dbo.Expense_Cash ( CASH_CODE, REGL_YEAR, REGL_CODE, EXTP_CODE, REGN_CODE, REGN_PRVN_CODE, REGN_PRVN_CNTY_CODE, EXCS_STAT)
                               VALUES (@CashCode ,@ReglYear ,@ReglCode ,@ExtpCode ,@RegnCode , @PrvnCode     ,@CntyCode,           @ExcsStat);
      END
      GOTO L$NextExtpCash;   
      
      L$EndExtpCash:
      CLOSE C#ExtpCash;
      
      GOTO L$NextExtpRegn;
          
      L$EndExtpRegn:
      CLOSE C#ExtpRegn;
      
      DEALLOCATE C#ExtpCash;
      DEALLOCATE C#ExtpRegn;
      
   END
   ELSE IF @RegnCode IS NOT NULL OR @PrvnCode IS NOT NULL
   BEGIN
	  BEGIN TRY
         SELECT @ReglCode = CODE
               ,@ReglYear = YEAR
           FROM Regulation
          WHERE TYPE = '002' -- آیین نامه حساب
            AND REGL_STAT = '002'; -- فعال
      END TRY
      BEGIN CATCH
         RAISERROR ( N'آیین نامه حساب فعالی درون سیستم وجود ندارد', -- Message text.
               16, -- Severity.
               1 -- State.
               );
         GOTO L$End;
      END CATCH  
      
      -- آیین نامه فعال پیدا شد
      DECLARE C#REGNS CURSOR FOR
         SELECT CODE
               ,PRVN_CODE
               ,PRVN_CNTY_CODE
           FROM Region
          WHERE CODE <> '999'
            AND (@RegnCode IS NULL OR CODE = @RegnCode)
            AND (@PrvnCode IS NULL OR PRVN_CODE = @PrvnCode)
       ORDER BY CODE;
      
      DECLARE C#EXTPS CURSOR FOR
         WITH Regl_Expn(YEAR, CODE) AS
         (
            SELECT YEAR
                  ,CODE
              FROM Regulation
             WHERE TYPE = '001' -- آیین نامه هزینه
               AND REGL_STAT = '002' -- فعال 
         )
         SELECT Extp.Code 
           FROM Regulation Regl
               ,Request_Requester Rqrq
               ,Regl_Expn re
               ,Expense_Type Extp
          WHERE Regl.YEAR IN (Rqrq.REGL_YEAR, re.YEAR)
            AND Regl.CODE IN (Rqrq.REGL_CODE, re.CODE)
            AND Rqrq.CODE = Extp.RQRQ_CODE 
       ORDER BY RQRQ.Rqtp_Code;
      
      DECLARE C#CASHS CURSOR FOR
		SELECT CODE
		  FROM Cash;
		  
      -- بررسی جدول ناحیه 
      OPEN C#REGNS;
      L$NextRegnRegn:
      FETCH NEXT FROM C#REGNS 
      INTO @RegnCode
          ,@PrvnCode
          ,@CntyCode;

      IF @@FETCH_STATUS <> 0
         GOTO L$EndRegnRegn;
      
      -- بررسی جدول نوع هزینه
      OPEN C#EXTPS;
      L$NextRegnExtp:
      FETCH NEXT FROM C#EXTPS
      INTO @ExtpCode;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndRegnExtp;

      OPEN C#CASHS;
      L$NextRegnCash:
      FETCH NEXT FROM C#CASHS INTO @CashCode;
      
      IF @@FETCH_STATUS <> 0
		GOTO L$EndRegnCash;

      IF NOT EXISTS(
         SELECT *
           FROM dbo.Expense_Cash ec
          WHERE ec.CASH_CODE           = @CashCode
            AND ec.REGL_YEAR           = @ReglYear
            AND ec.REGL_CODE           = @ReglCode
            AND ec.REGN_CODE           = @RegnCode
            AND ec.REGN_PRVN_CODE      = @PrvnCode
            AND ec.REGN_PRVN_CNTY_CODE = @CntyCode
            AND ec.EXTP_CODE           = @ExtpCode
      )
      BEGIN
         --WAITFOR DELAY '00:00:00:002';
         INSERT INTO dbo.Expense_Cash ( CASH_CODE, REGL_YEAR, REGL_CODE, EXTP_CODE, REGN_CODE, REGN_PRVN_CODE, REGN_PRVN_CNTY_CODE)
                               VALUES (@CashCode ,@ReglYear ,@ReglCode ,@ExtpCode ,@RegnCode , @PrvnCode     ,@CntyCode);
      END
      GOTO L$NextRegnCash;
      L$EndRegnCash:
      CLOSE C#CASHS;
      
      GOTO L$NextRegnExtp;
      L$EndRegnExtp:
      CLOSE C#EXTPS;      
      -- پایان بررسی نوع هزینه
      
      GOTO L$NextRegnRegn;
      L$EndRegnRegn:   
      CLOSE C#REGNS;
      
      -- برای خارج کردن تمامی منابعی که برای 
      -- Cursor
      -- مورد استفاده قرار گرفته است
      DEALLOCATE C#CASHS;
      DEALLOCATE C#EXTPS;      
      DEALLOCATE C#REGNS;      
      -- پایان بررسی جدول ناحیه
      
      GOTO L$End; 
      END
   ELSE IF @ReglYear IS NOT NULL AND @ReglCode IS NOT NULL
   BEGIN
      -- آیین نامه فعال پیدا شد
      DECLARE C#REGNS CURSOR FOR
         SELECT CODE
               ,PRVN_CODE
               ,PRVN_CNTY_CODE
           FROM Region
          WHERE CODE <> '999'
       ORDER BY CODE;
      
      DECLARE C#EXTPS CURSOR FOR
         WITH Regl_Expn(YEAR, CODE) AS
         (
            SELECT YEAR
                  ,CODE
              FROM Regulation
             WHERE TYPE = '001' -- آیین نامه هزینه
               AND REGL_STAT = '002' -- فعال 
         )
         SELECT Extp.Code 
           FROM Regulation Regl
               ,Request_Requester Rqrq
               ,Regl_Expn re
               ,Expense_Type Extp
          WHERE Regl.YEAR = Rqrq.REGL_YEAR
            AND Regl.YEAR = re.YEAR
            AND Regl.CODE = Rqrq.REGL_CODE
            AND Regl.CODE = re.CODE
            AND Rqrq.CODE = Extp.RQRQ_CODE 
       ORDER BY RQRQ.Rqtp_Code;
      
      DECLARE C#CASHS CURSOR FOR
         SELECT CODE
           FROM Cash
          WHERE CASH_STAT = '002';
      
      -- بررسی جدول ناحیه 
      OPEN C#REGNS;
      L$NextCashRegnAcnt:
      FETCH NEXT FROM C#REGNS 
      INTO @RegnCode
          ,@PrvnCode
          ,@CntyCode;

      IF @@FETCH_STATUS <> 0
         GOTO L$EndCashRegnAcnt;
      
      -- بررسی جدول نوع هزینه
      OPEN C#EXTPS;
      L$NextCashExtpAcnt:
      FETCH NEXT FROM C#EXTPS
      INTO @ExtpCode;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndCashExtpAcnt;
      
      -- بررسی جدول حساب ها
      OPEN C#CASHS;
      L$NextCashAcnt:
      FETCH NEXT FROM C#CASHS
      INTO @CashCode;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndCashAcnt;
      
      IF NOT EXISTS(
         SELECT *
           FROM dbo.Expense_Cash ec
          WHERE ec.CASH_CODE           = @CashCode
            AND ec.REGL_YEAR           = @ReglYear
            AND ec.REGL_CODE           = @ReglCode
            AND ec.REGN_CODE           = @RegnCode
            AND ec.REGN_PRVN_CODE      = @PrvnCode
            AND ec.REGN_PRVN_CNTY_CODE = @CntyCode
            AND ec.EXTP_CODE           = @ExtpCode
      )
      BEGIN
         INSERT INTO dbo.Expense_Cash ( CASH_CODE, REGL_YEAR, REGL_CODE, EXTP_CODE, REGN_CODE, REGN_PRVN_CODE, REGN_PRVN_CNTY_CODE, EXCS_STAT)
                               VALUES (@CashCode ,@ReglYear ,@ReglCode ,@ExtpCode ,@RegnCode , @PrvnCode     ,@CntyCode           , '001');
      END
      
      GOTO L$NextCashAcnt;
      L$EndCashAcnt:
      CLOSE C#CASHS;
      -- پایان بررسی شماره حساب ها
      
      
      GOTO L$NextCashExtpAcnt;
      L$EndCashExtpAcnt:
      CLOSE C#EXTPS;      
      -- پایان بررسی نوع هزینه
      
      GOTO L$NextCashRegnAcnt;
      L$EndCashRegnAcnt:   
      CLOSE C#REGNS;
      
      -- برای خارج کردن تمامی منابعی که برای 
      -- Cursor
      -- مورد استفاده قرار گرفته است
      DEALLOCATE C#EXTPS;      
      DEALLOCATE C#REGNS;      
      -- پایان بررسی جدول ناحیه
      
      IF NOT EXISTS(SELECT * FROM Regulation WHERE TYPE = '002' AND YEAR <> @ReglYear AND CODE <> @ReglCode) OR 
         NOT EXISTS(SELECT * FROM Regulation WHERE TYPE = '002' AND REGL_STAT = '002' AND YEAR <> @ReglYear AND CODE <> @ReglCode)
      BEGIN
         SELECT TOP 1 @CashCode = CODE FROM Cash WHERE CASH_STAT = '002';
         UPDATE Expense_Cash
            SET EXCS_STAT = '002'
          WHERE REGL_YEAR = @ReglYear
            AND REGL_CODE = @ReglCode
            AND CASH_CODE = @CashCode;
      END
      ELSE
      BEGIN
         DECLARE @OldReglYear SMALLINT
                ,@OldReglCode INT;
         
         SELECT @OldReglYear = YEAR
               ,@OldReglCode = CODE
           FROM Regulation
          WHERE TYPE = '002'
            AND REGL_STAT = '002';
         
         PRINT 'SYNC CRET_EXCS_P'
         SELECT @OldReglCode, @OldReglYear;
         EXEC SYNC_RGL2_P @ReglYear, @ReglCode, @OldReglYear, @OldReglCode;
      END
      
      GOTO L$End; 
   END
   L$End:
   RETURN;
END
GO
