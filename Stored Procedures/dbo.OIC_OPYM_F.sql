SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[OIC_OPYM_F]
   @X XML
AS 
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>164</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 164 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
	DECLARE @ErrorMessage NVARCHAR(MAX);

   BEGIN TRY
      BEGIN TRAN T1;
      
      DECLARE @Rqid BIGINT
             ,@RegnCode VARCHAR(3)
             ,@PrvnCode VARCHAR(3);
      
      SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT');
      SELECT @PrvnCode = REGN_PRVN_CODE
            ,@RegnCode = REGN_CODE
        FROM Request
       WHERE RQID = @Rqid;      
      
      IF EXISTS(
         SELECT *
           FROM Member_Ship M, [Session] S
          WHERE RQRO_RQST_RQID = @Rqid
            AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
            AND M.RECT_CODE = S.MBSP_RECT_CODE
            AND M.RWNO = S.MBSP_RWNO
      )
      BEGIN
         -- ابتدا باید رکورد های مربوط در جدول درآمد و ردیف های درآمد ذخیره گردد
         IF NOT EXISTS(SELECT * FROM Request WHERE RQID = @Rqid AND SSTT_MSTT_CODE = 2 AND SSTT_CODE = 2)
         BEGIN
            SELECT @X = (
               SELECT @Rqid '@rqid'          
                     ,'016' '@rqtpcode'
                     ,'008' '@rqttcode'
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
            
            DECLARE @CashCode BIGINT;
            SELECT @CashCode = CASH_CODE
              FROM Payment
             WHERE RQST_RQID = @Rqid;
            
            DECLARE C$Snmt CURSOR FOR
               SELECT S.EXPN_CODE, E.Pric, E.Extr_Prct, S.Totl_Sesn AS Qnty
                 FROM Member_Ship M, [Session] S, Expense E
                WHERE RQRO_RQST_RQID = @Rqid
                  AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
                  AND M.RECT_CODE = S.MBSP_RECT_CODE
                  AND M.RWNO = S.MBSP_RWNO
                  AND S.Expn_Code = E.Code;
            
            DECLARE @ExpnPric INT
                   ,@ExpnExtrPrct INT
                   ,@ExpnCode BIGINT
                   ,@Qnty SMALLINT;
            
            OPEN C$Snmt;
            L$FetchNextC$Snmt:
            FETCH NEXT FROM C$Snmt INTO @ExpnCode, @ExpnPric, @ExpnExtrPrct, @Qnty;
            
            IF @@FETCH_STATUS <> 0
               GOTO L$EndFetchC$Snmt;
               
            INSERT INTO Payment_Detail(PYMT_CASH_CODE, PYMT_RQST_RQID, RQRO_RWNO, EXPN_CODE, CODE, PAY_STAT, QNTY, EXPN_PRIC, EXPN_EXTR_PRCT)
            VALUES(@CashCode, @Rqid, 1, @ExpnCode, dbo.GNRT_NVID_U(), '001', @Qnty, @ExpnPric, @ExpnExtrPrct);
            
            GOTO L$FetchNextC$Snmt;
            L$EndFetchC$Snmt:
            CLOSE C$Snmt;
            DEALLOCATE C$Snmt;
            
         END
      END
      
      COMMIT TRAN T1;
   END TRY
   BEGIN CATCH
      IF (SELECT CURSOR_STATUS('global','C$Snmt')) >= -1
      BEGIN
         IF (SELECT CURSOR_STATUS('global','C$Snmt')) > -1
            CLOSE C$Snmt
         DEALLOCATE C$Snmt
      END               
      
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH
END;
GO
