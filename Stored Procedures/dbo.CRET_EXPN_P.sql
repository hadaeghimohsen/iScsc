SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_EXPN_P]
	-- Add the parameters for the stored procedure here
	@ExtpCode BIGINT = NULL,
   @MtodCode BIGINT = NULL,
   @CtgyCode BIGINT = NULL
AS
BEGIN
   --PRINT 'CRET_EXPN_P';
	DECLARE @ReglYear INT
	       ,@ReglCode SMALLINT;
	
	DECLARE @Code BIGINT
	       ,@RqtpEpitType VARCHAR(3)
	       ,@MtodEpitType VARCHAR(3)
	       ,@CtgyEpitType VARCHAR(3)
	       ,@CtgyNumbOfAttnMont INT
	       ,@CtgyPrvtCochExpn VARCHAR(3)
	       ,@CtgyNumbCyclDay INT
	       ,@CtgyNumbMontOfer INT
	       ,@CtgyPric INT;
	       
	BEGIN TRY
      SELECT @ReglCode = CODE
            ,@ReglYear = YEAR
        FROM Regulation
       WHERE TYPE = '001' -- آیین نامه هزینه
         AND REGL_STAT = '002'; -- فعال
   END TRY
   BEGIN CATCH
      RAISERROR ( N'آیین نامه هزینه فعالی درون سیستم وجود ندارد', -- Message text.
            16, -- Severity.
            1 -- State.
            );
      GOTO L$End;
   END CATCH  
   
   DECLARE C$EXTPS CURSOR FOR
      SELECT Extp.Code, Rqtp.EPIT_TYPE 
        FROM Regulation Regl
            ,Request_Requester Rqrq
            ,Expense_Type Extp
            ,Request_Type Rqtp
       WHERE Regl.YEAR = Rqrq.REGL_YEAR
         AND Regl.YEAR = @ReglYear
         AND Regl.CODE = Rqrq.REGL_CODE
         AND Regl.CODE = @ReglCode
         AND Rqrq.CODE = Extp.RQRQ_CODE 
         AND Rqrq.RQTP_CODE = Rqtp.Code
         AND ((@ExtpCode IS NULL) OR (Extp.Code = @ExtpCode))
    ORDER BY RQRQ.Rqtp_Code;
   
   DECLARE C$MTODS CURSOR FOR
      SELECT Code, EPIT_TYPE
        FROM dbo.Method
       WHERE ((@MtodCode IS NULL) OR (Code = @MtodCode));

   OPEN C$MTODS;
   L$NextMtod:
   FETCH NEXT FROM C$MTODS INTO @MtodCode, @MtodEpitType;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndMtod;

   DECLARE C$CTGYS CURSOR FOR
      SELECT Code, EPIT_TYPE, NUMB_OF_ATTN_MONT, PRVT_COCH_EXPN, NUMB_CYCL_DAY, NUMB_MONT_OFER, PRIC
        FROM dbo.Category_Belt
       WHERE ((@CtgyCode IS NULL) OR (Code = @CtgyCode))
         AND ((@MtodCode IS NULL) OR (Mtod_Code = @MtodCode))
    ORDER BY Ordr;
         
   OPEN C$CTGYS;
   L$NextCtgy:
   FETCH NEXT FROM C$CTGYS INTO @CtgyCode, @CtgyEpitType, @CtgyNumbOfAttnMont, @CtgyPrvtCochExpn, @CtgyNumbCyclDay, @CtgyNumbMontOfer, @CtgyPric;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndCtgy;
   
   OPEN C$EXTPS;
   L$NextExtp:
   FETCH NEXT FROM C$EXTPS INTO @ExtpCode, @RqtpEpitType;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndExtp;

   IF @RqtpEpitType != @MtodEpitType
      GOTO L$NextExtp;
   
   IF NOT EXISTS(
      SELECT *
        FROM dbo.Expense
       WHERE REGL_YEAR = @ReglYear
         AND REGL_CODE = @ReglCode
         AND CTGY_CODE = @CtgyCode
         AND MTOD_CODE = @MtodCode
         AND EXTP_CODE = @ExtpCode
   )
   BEGIN
      L$GNRTNWID:
      SET @Code = dbo.GNRT_NWID_U();
      IF EXISTS(SELECT * FROM Expense WHERE CODE = @Code)
      BEGIN
         --PRINT 'Duplicate Key';
         GOTO L$GNRTNWID;
      END
      INSERT INTO dbo.Expense (CODE, REGL_YEAR, REGL_CODE, CTGY_CODE, MTOD_CODE, EXTP_CODE, PRIC, EXTR_PRCT, EXPN_STAT, ADD_QUTS, COVR_DSCT, EXPN_TYPE, COVR_TAX, NUMB_OF_ATTN_WEEK, PRVT_COCH_EXPN, NUMB_CYCL_DAY, NUMB_MONT_OFER, NUMB_OF_ATTN_MONT, MIN_NUMB, MIN_TIME)
                        VALUES(@Code, @ReglYear, @ReglCode, @CtgyCode, @MtodCode, @ExtpCode, ISNULL(@CtgyPric, 0), 0, '001', '001', '002', '001', '002', 3, ISNULL(@CtgyPrvtCochExpn,'001'), ISNULL(@CtgyNumbCyclDay, 30), ISNULL(@CtgyNumbMontOfer, 0), ISNULL(@CtgyNumbOfAttnMont, 0), 0, '00:01:00');
   END
   GOTO L$NextExtp;
   L$EndExtp:
   CLOSE C$EXTPS;
   
   GOTO L$NextCtgy;
   L$EndCtgy:
   CLOSE C$CTGYS;      
   DEALLOCATE C$CTGYS;
   SET @CtgyCode = NULL;

   GOTO L$NextMtod;
   L$EndMtod:
   CLOSE C$MTODS;      

   DEALLOCATE C$MTODS;
   DEALLOCATE C$EXTPS;
   
   L$End:
   RETURN;
END
GO
