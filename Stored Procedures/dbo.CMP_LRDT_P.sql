SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CMP_LRDT_P]
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
   
   IF NOT EXISTS(
      SELECT *
        FROM Campitition
       WHERE RQRO_RQST_RQID = @Rqid
         AND RQRO_RWNO      = @RqroRwno
         AND FIGH_FILE_NO   = @FileNo
         AND RECT_CODE      = '001'
   )
      INSERT INTO Campitition
      (RQRO_RQST_RQID, 
       RQRO_RWNO, 
       FIGH_FILE_NO, 
       RECT_CODE, 
       CAMP_DATE)
      VALUES
      (@Rqid, 
       @RqroRwno, 
       @FileNo, 
       '001', 
       GETDATE());
   
   GOTO NextFromFighter;
   EndFetchFighter:
   CLOSE C$Fighter;
   DEALLOCATE C$Fighter;      
   
END;
GO
