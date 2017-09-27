SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[EXM_SAVE_P]
	@X XML
AS
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>97</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 97 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

	DECLARE @ErrorMessage NVARCHAR(MAX);
	
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid BIGINT
	          ,@RqtpCode VARCHAR(3)
	          ,@RqttCode VARCHAR(3)
	          ,@RegnCode VARCHAR(3)
	          ,@PrvnCode VARCHAR(3)
	          ,@Type     VARCHAR(3);
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)')
	         ,@Type     = @X.query('//Exam').value('(Exam/@type)[1]', 'VARCHAR(3)');
      
      --SELECT @X;
      	                
	   /* ثبت شماره درخواست */
      IF @Rqid IS NULL OR @Rqid = 0
      BEGIN
         EXEC dbo.INS_RQST_P
            @PrvnCode,
            @RegnCode,
            NULL,
            @RqtpCode,
            @RqttCode,
            NULL,
            NULL,
            NULL,
            @Rqid OUT;      
      END
/*      ELSE
      BEGIN
         EXEC UPD_RQST_P
            @Rqid,
            @PrvnCode,
            @RegnCode,
            @RqtpCode,
            @RqttCode,
            NULL,
            NULL,
            NULL;            
      END
*/      
      DECLARE @XHandle INT;
      EXEC SP_XML_PREPAREDOCUMENT @XHandle OUTPUT, @X;
      
      DECLARE C$Fighter CURSOR FOR
         SELECT *
         FROM OPENXML(@XHandle, '//Fighter')
         WITH (
            File_No      BIGINT        '@fileno'
         );
      
      DECLARE @FileNo BIGINT;
      
      OPEN C$Fighter;
      NextFetchFighter:
      FETCH NEXT FROM C$Fighter INTO @FileNo;
      
      IF @@FETCH_STATUS <> 0
         GOTO EndFetchFighter;
      
      /* ثبت ردیف درخواست */
      DECLARE @RqroRwno SMALLINT;
      SET @RqroRwno = NULL;
      SELECT @RqroRwno = Rwno
         FROM Request_Row
         WHERE RQST_RQID = @Rqid
           AND FIGH_FILE_NO = @FileNo;
           
      IF @RqroRwno IS NULL
      BEGIN
         EXEC INS_RQRO_P
            @Rqid
           ,@FileNo
           ,@RqroRwno OUT;
      END
      
      DECLARE @Time     SMALLINT
             ,@CachNumb SMALLINT
             ,@StepHegh SMALLINT
             ,@Wegh     SMALLINT;
      
      SELECT @Type = r.query('Exam').value('(Exam/@type)[1]', 'VARCHAR(3)')
            ,@Time = r.query('Exam').value('(Exam/@time)[1]', 'SMALLINT')
            ,@CachNumb = r.query('Exam').value('(Exam/@cachnumb)[1]', 'SMALLINT')
            ,@StepHegh = r.query('Exam').value('(Exam/@stephegh)[1]', 'SMALLINT')
            ,@Wegh = r.query('Exam').value('(Exam/@wegh)[1]', 'SMALLINT')
        FROM @X.nodes('//Fighter') F(r)
       WHERE r.query('.').value('(Fighter/@fileno)[1]', 'BIGINT') = @FileNo;
      
      IF NOT EXISTS(
      SELECT *
        FROM Exam
       WHERE FIGH_FILE_NO = @FileNo
         AND RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '004'         
      )
      BEGIN
         EXEC INS_EXAM_P 
            @Rqid
           ,@RqroRwno
           ,@FileNo
           ,'004'
           ,@Type
           ,@Time
           ,@CachNumb
           ,@StepHegh
           ,@Wegh;
      END
      ELSE
      BEGIN
         EXEC UPD_EXAM_P 
            @Rqid
           ,@RqroRwno
           ,@FileNo
           ,'004'
           ,@Type
           ,@Time
           ,@CachNumb
           ,@StepHegh
           ,@Wegh;
      END     
      
      EXEC UPD_EXAM_P 
            @Rqid
           ,@RqroRwno
           ,@FileNo
           ,'001'
           ,@Type
           ,@Time
           ,@CachNumb
           ,@StepHegh
           ,@Wegh;
      
      /*DECLARE @AttnDate DATE;
      SET @AttnDate = GETDATE();
      
      IF NOT EXISTS(
      SELECT * 
        FROM Attendance A
       WHERE A.FIGH_FILE_NO = @FileNo
         AND CAST(A.ATTN_DATE AS DATE) = CAST(@AttnDate AS DATE)
      )   
         EXEC INS_ATTN_P NULL, @FileNo, @AttnDate;
      */
      
      GOTO NextFetchFighter;         
      EndFetchFighter:
      CLOSE C$Fighter;
      DEALLOCATE C$Fighter;
         
	   EXEC SP_XML_REMOVEDOCUMENT @XHandle;
	   
	   IF (SELECT COUNT(*)
           FROM Request_Row Rr
          WHERE Rr.RQST_RQID = @Rqid            
            AND Rr.RECD_STAT = '002') = 
          (SELECT COUNT(*)
             FROM Exam T
            WHERE T.RQRO_RQST_RQID = @Rqid            
              AND T.RECT_CODE = '004'
              AND ((T.TYPE IN ('001', '002', '003', '005') AND T.TIME <> 1)
                OR (T.TYPE IN ('004') AND T.CACH_NUMB <> 0)
                OR (T.TYPE IN ('005') AND T.STEP_HEGH <> 0 AND T.WEGH <> 0)))            
      BEGIN
         SET @X = '<Process><Request rqid=""/></Process>';
         SET @X.modify(
            'replace value of (//Request/@rqid)[1]
             with sql:variable("@Rqid")'
         );         
         EXEC dbo.END_RQST_P @X;
      END
      
	   COMMIT TRAN T1;
	END TRY
	BEGIN CATCH
 	   IF (SELECT CURSOR_STATUS('global','C$Fighter')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('global','C$Fighter')) > -1
         BEGIN
          CLOSE C$Fighter
         END
       DEALLOCATE C$Fighter
      END
            
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN;

	END CATCH;
END
GO
