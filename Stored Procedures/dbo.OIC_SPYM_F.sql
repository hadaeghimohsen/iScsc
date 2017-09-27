SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[OIC_SPYM_F]
   @X XML
AS
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>160</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 160 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
	DECLARE @ErrorMessage NVARCHAR(MAX);

   BEGIN TRY
      BEGIN TRAN OCI_SSAVE_F_T;
      
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
           FROM Member_Ship M, [Session] S, Session_Meeting Sm
          WHERE RQRO_RQST_RQID = @Rqid
            AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
            AND M.RECT_CODE = S.MBSP_RECT_CODE
            AND M.RWNO = S.MBSP_RWNO
            AND S.SNID = Sm.SESN_SNID
            AND S.MBSP_FIGH_FILE_NO = Sm.MBSP_FIGH_FILE_NO
            AND S.MBSP_RECT_CODE = Sm.MBSP_RECT_CODE
            AND S.MBSP_RWNO = Sm.MBSP_RWNO
            AND Sm.EXPN_PRIC > 0
      )
      BEGIN
         -- ابتدا باید رکورد های مربوط در جدول درآمد و ردیف های درآمد ذخیره گردد
         IF NOT EXISTS(SELECT * FROM Request WHERE RQID = @Rqid AND SSTT_MSTT_CODE = 2 AND SSTT_CODE = 2)
         BEGIN
            SELECT @X = (
               SELECT @Rqid '@rqid'          
                     ,'016' '@rqtpcode'
                     ,'007' '@rqttcode'
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
               SELECT Sm.EXPN_CODE, SUM(Sm.EXPN_PRIC), SUM(Sm.EXPN_EXTR_PRCT)
                 FROM Member_Ship M, [Session] S, Session_Meeting Sm
                WHERE RQRO_RQST_RQID = @Rqid
                  AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
                  AND M.RECT_CODE = S.MBSP_RECT_CODE
                  AND M.RWNO = S.MBSP_RWNO
                  AND S.SNID = Sm.SESN_SNID
                  AND S.MBSP_FIGH_FILE_NO = Sm.MBSP_FIGH_FILE_NO
                  AND S.MBSP_RECT_CODE = Sm.MBSP_RECT_CODE
                  AND S.MBSP_RWNO = Sm.MBSP_RWNO
                  AND Sm.VALD_TYPE = '002'
                  AND Sm.EXPN_PRIC > 0
             GROUP BY Sm.EXPN_CODE;
            
            DECLARE @ExpnPric INT
                   ,@ExpnExtrPrct INT
                   ,@ExpnCode BIGINT;
            
            OPEN C$Snmt;
            L$FetchNextC$Snmt:
            FETCH NEXT FROM C$Snmt INTO @ExpnCode, @ExpnPric, @ExpnExtrPrct;
            
            IF @@FETCH_STATUS <> 0
               GOTO L$EndFetchC$Snmt;
               
            INSERT INTO Payment_Detail(PYMT_CASH_CODE, PYMT_RQST_RQID, RQRO_RWNO, EXPN_CODE, CODE, PAY_STAT, QNTY, EXPN_PRIC, EXPN_EXTR_PRCT)
            VALUES(@CashCode, @Rqid, 1, @ExpnCode, dbo.GNRT_NVID_U(), '001', 1, @ExpnPric, @ExpnExtrPrct);
            
            GOTO L$FetchNextC$Snmt;
            L$EndFetchC$Snmt:
            CLOSE C$Snmt;
            DEALLOCATE C$Snmt;
            
         END
      END
      
      COMMIT TRAN OCI_SSAV_F_T;
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
