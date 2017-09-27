SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CLC_RQST_P]
	@X XML
AS
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>86</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 86 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>87</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 87 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>88</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 88 سطوح امینتی', -- Message text.
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
	          ,@PrvnCode VARCHAR(3);
      DECLARE @FileNo   BIGINT
             ,@RqroRwno SMALLINT
             ,@Hegh REAL
             ,@Wegh SMALLINT
             ,@TranTime INT;

	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)')
	         ,@FileNo   = @X.query('//Request_Row').value('(Request_Row/@fileno)[1]', 'BIGINT')
	         ,@Hegh     = @X.query('//Calculate_Calorie').value('(Calculate_Calorie/@hegh)[1]', 'REAL')
	         ,@Wegh     = @X.query('//Calculate_Calorie').value('(Calculate_Calorie/@wegh)[1]', 'SMALLINT')
	         ,@TranTime = @X.query('//Calculate_Calorie').value('(Calculate_Calorie/@trantime)[1]', 'INT');
      
      IF @FileNo = 0 OR @FileNo IS NULL BEGIN RAISERROR(N'شماره پرونده برای هنرجو وارد نشده', 16, 1); RETURN; END
      IF LEN(@RqttCode) <> 3 BEGIN RAISERROR(N'نوع متقاضی برای درخواست وارد نشده', 16, 1); RETURN; END
      
      SELECT @RegnCode = Regn_Code, @PrvnCode = Regn_Prvn_Code 
        FROM Fighter
       WHERE FILE_NO = @FileNo;

      	                
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
         FROM OPENXML(@XHandle, '//Request_Row')
         WITH (
            File_No      BIGINT        '@fileno'
         );

      OPEN C$Fighter;
      NextFetchFighter:
      FETCH NEXT FROM C$Fighter INTO @FileNo;
      
      IF @@FETCH_STATUS <> 0
         GOTO EndFetchFighter;
      
      /* ثبت ردیف درخواست */

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
      
      IF NOT EXISTS(
      SELECT *
        FROM Calculate_Calorie
       WHERE FIGH_FILE_NO = @FileNo
         AND RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '001'
      )
      BEGIN
         EXEC INS_CLCL_P 
            @Rqid
           ,@RqroRwno
           ,@FileNo
           ,'001'
           ,@Hegh
           ,@Wegh
           ,@TranTime;
      END
      ELSE
      BEGIN
         EXEC UPD_CLCL_P 
            @Rqid
           ,@RqroRwno
           ,@FileNo
           ,'001'
           ,@Hegh
           ,@Wegh
           ,@TranTime;
      END     
      
      GOTO NextFetchFighter;
         
      EndFetchFighter:
      CLOSE C$Fighter;
      DEALLOCATE C$Fighter;
         
	   EXEC SP_XML_REMOVEDOCUMENT @XHandle;
	   
	   -- اگر در ثبت موقت باشیم و برای نوع درخواست و متقاضی آیین نامه هزینه داری داشته باشیم درخواست را به فرم اعلام هزینه ارسال میکنیم            
            IF EXISTS(
         SELECT *
           FROM Request_Row Rr, Fighter F
          WHERE Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(
                  @PrvnCode, 
                  @RegnCode, 
                  NULL, 
                  @RqtpCode, 
                  @RqttCode, 
                  NULL, 
                  NULL, 
                  F.Mtod_Code_Dnrm , 
                  F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         IF NOT EXISTS(SELECT * FROM Request WHERE RQID = @Rqid AND SSTT_MSTT_CODE = 2 AND SSTT_CODE = 2)
         BEGIN
            SELECT @X = (
               SELECT @Rqid '@rqid'          
                     ,@RqtpCode '@rqtpcode'
                     ,@RqttCode '@rqttcode'
                     ,@RegnCode '@regncode'  
                     ,@PrvnCode '@prvncode'
               FOR XML PATH('Request'), ROOT('Process')
            );
            EXEC INS_SEXP_P @X;             

            UPDATE Request
               SET SEND_EXPN = '002'
                  ,SSTT_MSTT_CODE = 2
                  ,SSTT_CODE = 2
             WHERE RQID = @Rqid;
        END
      END
      ELSE
      BEGIN
         UPDATE Request
            SET SEND_EXPN = '001'
               ,SSTT_MSTT_CODE = 1
               ,SSTT_CODE = 1
          WHERE RQID = @Rqid;                
         
         DELETE Payment_Detail 
          WHERE PYMT_RQST_RQID = @Rqid;          
         DELETE Payment
          WHERE RQST_RQID = @Rqid;            
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
