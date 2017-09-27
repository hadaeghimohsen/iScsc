SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[TST_LRDT_P]
   @X XML
AS
BEGIN

   DECLARE @Rqid     BIGINT
          ,@RqroRwno SMALLINT
          ,@FileNo   BIGINT
          ,@MtodCode BIGINT
          ,@CtgyCode BIGINT;
   DECLARE @ErrorMessage  NVARCHAR(MAX);
   
   SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT');
   
   DECLARE C$Fighter CURSOR FOR
      SELECT 
         r.query('.').value('(Fighter/@fileno)[1]', 'BIGINT') --FileNo
      FROM @X.nodes('//Fighter') F(r);
   
   OPEN C$Fighter;
   NextFromFighter:
   FETCH NEXT FROM C$Fighter INTO @FileNo;
   
   IF @@FETCH_STATUS <> 0
      GOTO EndFetchFighter;
   
   SELECT @RqroRwno = RWNO
   FROM Request_Row 
   WHERE RQST_RQID = @Rqid
     AND FIGH_FILE_NO = @FileNo;
   
   SELECT @MtodCode = MTOD_CODE_DNRM
         ,@CtgyCode = CTGY_CODE_DNRM
   FROM Fighter
   WHERE FILE_NO = @FileNo;
   
   SELECT @CtgyCode = CODE
   FROM Category_Belt
   WHERE MTOD_CODE = @MtodCode
     AND ORDR = (
      SELECT ORDR
      FROM Category_Belt
      WHERE MTOD_CODE = @MtodCode
        AND CODE = @CtgyCode
     ) + 1;
   
   IF @CtgyCode IS NULL
   BEGIN
      SET @ErrorMessage  = N'هنرجوي ' + CAST(@FileNo AS VARCHAR(30)) + ' دارای آخرین رده کمربند در سبک خود میباشد';
      RAISERROR(N'هنرجوی', 16, 1);
   END
   
   IF NOT EXISTS(
      SELECT *
        FROM Test
       WHERE RQRO_RQST_RQID = @Rqid
         AND RQRO_RWNO      = @RqroRwno
         AND FIGH_FILE_NO   = @FileNo
         AND RECT_CODE      = '001'
   )
      INSERT INTO Test (RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, CTGY_MTOD_CODE, CTGY_CODE, TEST_DATE)
      VALUES(@Rqid, @RqroRwno, @FileNo, '001', @MtodCode, @CtgyCode, GETDATE());
   
   GOTO NextFromFighter;
   EndFetchFighter:
   CLOSE C$Fighter;
   DEALLOCATE C$Fighter;      
   
END;
GO
