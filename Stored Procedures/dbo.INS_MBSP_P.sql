SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_MBSP_P]
	@Rqid BIGINT
  ,@RqroRwno SMALLINT
  ,@FileNo BIGINT
  ,@RectCode VARCHAR(3)
  ,@Type     VARCHAR(3)
  ,@StrtDate DATETIME
  ,@EndDate  DATETIME
  ,@PrntCont SMALLINT
  ,@NumbMontOfer INT
  ,@NumbOfAttnMont INT
  ,@NumbOfAttnWeek INT
  ,@AttnDayType VARCHAR(3)  
AS
BEGIN 
   
   DECLARE @ERORMESG  NVARCHAR(250)
          ,@TryValdSbmt VARCHAR(3)
          ,@Days INT
          ,@StrtDateTemp DATE;
   
   SELECT @TryValdSbmt = S.TRY_VALD_SBMT
         ,@Days = (DATEDIFF(DAY, @StrtDate, MBSP_END_DATE))
         ,@StrtDateTemp = F.MBSP_STRT_DATE
     FROM dbo.Fighter F, dbo.Settings S
    WHERE f.CLUB_CODE_DNRM = s.CLUB_CODE
      AND f.FILE_NO = @FileNo;
   
   SET @TryValdSbmt = ISNULL(@TryValdSbmt, '002');
   IF ISNULL(@Days, 0) < 0 SET @Days = 0; ELSE SET @Days = 0;
   --ELSE SET @Days = ISNULL(@Days, 0);
   IF @StrtDate = @StrtDateTemp
      SET @Days = 0;
   
   IF EXISTS(SELECT * FROM Request WHERE RQID = @Rqid AND RQTT_CODE != '004' ) AND 
      (SELECT COUNT(*) 
         FROM Fighter F, Member_Ship Mb 
        WHERE F.FILE_NO = Mb.FIGH_FILE_NO 
          AND Mb.FIGH_FILE_NO = @FileNo 
          AND Mb.RECT_CODE = '004' 
          AND F.MBSP_RWNO_DNRM = Mb.RWNO 
          AND TYPE = @Type 
          AND ( ( ISNULL(Mb.NUMB_OF_ATTN_MONT, 0) = 0 AND END_DATE > @StrtDate ) 
              OR 
                ( ISNULL(Mb.NUMB_OF_ATTN_MONT, 0) > 0 AND Mb.NUMB_OF_ATTN_MONT > ISNULL(Mb.SUM_ATTN_MONT_DNRM, 0) 
                  AND END_DATE > @StrtDate )
          )
      ) >= 1
   BEGIN
      IF @TryValdSbmt = '001'
      BEGIN
         SET @ERORMESG = N' تاریخ اعتبار شماره ردیف ' + CAST(@RqroRwno AS VARCHAR(3)) + N' درخواست همچنان معتبر می باشد. نیازی به تمدید مجدد نیست';      
         RAISERROR(@ERORMESG, 16, 1);
         RETURN;
      END
      ELSE IF @TryValdSbmt = '002' AND @RectCode = '004'
      BEGIN
         SET @EndDate = DATEADD(DAY, @Days, @EndDate);
      END
   END
   ELSE IF EXISTS(SELECT * FROM Request WHERE RQID = @Rqid AND RQTT_CODE != '004' ) AND 
      (SELECT COUNT(*) 
         FROM Fighter F, Member_Ship Mb 
        WHERE F.FILE_NO = Mb.FIGH_FILE_NO 
          AND Mb.FIGH_FILE_NO = @FileNo 
          AND Mb.RECT_CODE = '004' 
          AND F.MBCO_RWNO_DNRM = Mb.RWNO 
          AND TYPE = @Type 
          AND ( ( ISNULL(Mb.NUMB_OF_ATTN_MONT, 0) = 0 AND END_DATE > @StrtDate ) 
              OR 
                ( ISNULL(Mb.NUMB_OF_ATTN_MONT, 0) > 0 AND Mb.NUMB_OF_ATTN_MONT > ISNULL(Mb.SUM_ATTN_MONT_DNRM, 0) 
                  AND END_DATE > @StrtDate )
          )
      ) >= 1
   BEGIN
      IF @TryValdSbmt = '001'
      BEGIN
         SET @ERORMESG = N' تاریخ اعتبار جلسه خصوصی شماره ردیف ' + CAST(@RqroRwno AS VARCHAR(3)) + N' درخواست همچنان معتبر می باشد. نیازی به تمدید مجدد نیست';      
         RAISERROR(@ERORMESG, 16, 1);
         RETURN;
      END 
      ELSE IF @TryValdSbmt = '002' AND @RectCode = '004'
      BEGIN
         SET @EndDate = DATEADD(DAY, @Days, @EndDate);
      END
   END
   INSERT INTO Member_Ship (RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, TYPE, STRT_DATE, END_DATE, PRNT_CONT, NUMB_MONT_OFER, NUMB_OF_ATTN_MONT, NUMB_OF_ATTN_WEEK, ATTN_DAY_TYPE)
   VALUES                  (@Rqid,          @RqroRwno, @FileNo     , @RectCode, @Type, @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, @NumbOfAttnWeek, @AttnDayType);
END
GO
