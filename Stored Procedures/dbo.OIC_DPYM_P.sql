SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[OIC_DPYM_P]
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
   
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>188</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 188 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   DECLARE @ErrorMessage NVARCHAR(MAX);
   
   BEGIN TRY
      BEGIN TRAN T1;
      
      DECLARE @Rqid BIGINT
             ,@ActnType VARCHAR(3)
             ,@Rlid BIGINT
             ,@DcmtPric BIGINT;
      
      SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT')
            ,@ActnType = @X.query('//Request').value('(Request/@actntype)[1]', 'VARCHAR(3)');
      
      -- برای هنرجویان تک جلسه ای بدون مربی
      IF @ActnType = '001'
      BEGIN
         IF NOT EXISTS(
            SELECT *
              FROM Request_Letter
             WHERE RQST_RQID = @Rqid
               AND REC_STAT = '001'
         )
            INSERT INTO Request_Letter (RLID, RQST_RQID, REC_STAT, LETT_NO, LETT_DATE, RQLT_DESC, RWNO)
            VALUES(dbo.GNRT_NVID_U(), @Rqid, '001', REPLACE(dbo.GET_MTOS_U(GETDATE()), '/', ''), GETDATE(), N'ثبت سند استرداد وجه هزینه مربوط به هنرجوی تک جلسه ای بدون مربی', 0);
         
         SELECT @Rlid = RLID
           FROM Request_Letter
          WHERE RQST_RQID = @Rqid
            AND REC_STAT = '001';
         
         SELECT @DcmtPric = (E.PRIC + ISNULL(E.EXTR_PRCT, 0)) * S.TOTL_SESN
           FROM Fighter F, Member_Ship M, [Session] S, Expense E
          WHERE F.FILE_NO = M.FIGH_FILE_NO
            AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
            AND M.RECT_CODE = S.MBSP_RECT_CODE
            AND M.RWNO = S.MBSP_RWNO
            AND S.EXPN_CODE = E.CODE
            AND F.RQST_RQID = M.RQRO_RQST_RQID
            AND M.RECT_CODE = '001'
            AND F.RQST_RQID = @Rqid;
         
         IF NOT EXISTS(
            SELECT * 
              FROM Finance_Document
             WHERE RQRO_RQST_RQID = @Rqid
               AND RQLT_RLID = @Rlid
               AND RQRO_RWNO = 1
               AND REC_STAT = '001'
         )
            INSERT INTO Finance_Document (FDID, RQRO_RQST_RQID, RQRO_RWNO, RQLT_RLID, RWNO, REC_STAT, DCMT_NO, DCMT_DATE, DCMT_PRIC, DCMT_DESC)
            VALUES(dbo.GNRT_NVID_U(), @Rqid, 1, @Rlid, 0, '001', REPLACE(dbo.GET_MTOS_U(GETDATE()), '/', ''), GETDATE(), ROUND(@DcmtPric, -3), N' مبلغ قابل استرداد ' + CONVERT(VARCHAR(20), ROUND(@DcmtPric, -3)) + N' ریال می باشد' );
         
         UPDATE Request
            SET SSTT_MSTT_CODE = 85
               ,SSTT_CODE = 1
           WHERE RQID = @Rqid;
      END 
      
      -- برای هنرجویان چند جلسه ای با مربی
      ELSE IF @ActnType IN( '002', '003' )
      BEGIN
         IF NOT EXISTS(
            SELECT *
              FROM Request_Letter
             WHERE RQST_RQID = @Rqid
               AND REC_STAT = '001'
         )
            INSERT INTO Request_Letter (RLID, RQST_RQID, REC_STAT, LETT_NO, LETT_DATE, RQLT_DESC, RWNO)
            VALUES(dbo.GNRT_NVID_U(), @Rqid, '001', REPLACE(dbo.GET_MTOS_U(GETDATE()), '/', ''), GETDATE(), N'ثبت سند استرداد وجه هزینه مربوط به هنرجوی چند جلسه ای با مربی', 0);
         
         SELECT @Rlid = RLID
           FROM Request_Letter
          WHERE RQST_RQID = @Rqid
            AND REC_STAT = '001';
         
         SELECT @DcmtPric = SUM((E.PRIC + ISNULL(E.EXTR_PRCT, 0)) * S.TOTL_SESN)
           FROM Fighter F, Member_Ship M, [Session] S, Expense E
          WHERE F.FILE_NO = M.FIGH_FILE_NO
            AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
            AND M.RECT_CODE = S.MBSP_RECT_CODE
            AND M.RWNO = S.MBSP_RWNO
            AND S.EXPN_CODE = E.CODE
            AND F.RQST_RQID = M.RQRO_RQST_RQID
            AND M.RECT_CODE = '001'
            AND F.RQST_RQID = @Rqid;
         
         IF NOT EXISTS(
            SELECT * 
              FROM Finance_Document
             WHERE RQRO_RQST_RQID = @Rqid
               AND RQLT_RLID = @Rlid
               AND RQRO_RWNO = 1
               AND REC_STAT = '001'
         )
            INSERT INTO Finance_Document (FDID, RQRO_RQST_RQID, RQRO_RWNO, RQLT_RLID, RWNO, REC_STAT, DCMT_NO, DCMT_DATE, DCMT_PRIC, DCMT_DESC)
            VALUES(dbo.GNRT_NVID_U(), @Rqid, 1, @Rlid, 0, '001', REPLACE(dbo.GET_MTOS_U(GETDATE()), '/', ''), GETDATE(), ROUND(@DcmtPric, -3), N' مبلغ قابل استرداد ' + CONVERT(VARCHAR(20), ROUND(@DcmtPric, -3)) + N' ریال می باشد' );
         
         UPDATE Request
            SET SSTT_MSTT_CODE = 85
               ,SSTT_CODE = 1
           WHERE RQID = @Rqid;
      END
      
      COMMIT TRAN T1;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH
END
GO
