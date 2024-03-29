SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Procedure [dbo].[PAY_MSAV_P]
   @X XML
AS 
BEGIN
   BEGIN TRY
   BEGIN TRAN PAY_MSAV_P_T1
   DECLARE @ErrorMessage NVARCHAR(MAX);
   
   DECLARE @ActnType VARCHAR(30);
   SELECT @ActnType = @X.query('Payment').value('(Payment/@actntype)[1]', 'VARCHAR(30)');
   
   IF @ActnType = 'Delete'
      DELETE Payment_Method
       WHERE PYMT_CASH_CODE = @X.query('Payment').value('(Payment/@cashcode)[1]', 'BIGINT')
         AND PYMT_RQST_RQID = @X.query('Payment').value('(Payment/@rqstrqid)[1]', 'BIGINT')
         AND RWNO = @X.query('Payment').value('(Payment/@rwno)[1]', 'SMALLINT');
   ELSE IF @ActnType = 'InsertUpdate'
   BEGIN
      INSERT INTO Payment_Method (PYMT_CASH_CODE, PYMT_RQST_RQID, RQRO_RQST_RQID, RQRO_RWNO, RWNO, CODE, AMNT, RCPT_MTOD, TERM_NO, TRAN_NO, CARD_NO, BANK, FLOW_NO, REF_NO, ACTN_DATE, VALD_TYPE, RCPT_TO_OTHR_ACNT, RCPT_FILE_PATH)
      SELECT pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AS CashCode
            ,pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT') AS RqstRqid
            ,pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT') AS RqstRqid
            ,1
            ,0
            ,dbo.GNRT_NVID_U()
            ,pm.query('.').value('(Payment_Method/@amnt)[1]',     'BIGINT') AS Amnt
            ,pm.query('.').value('(Payment_Method/@rcptmtod)[1]', 'VARCHAR(3)') AS RcptMtod
            ,pm.query('.').value('(Payment_Method/@termno)[1]',   'BIGINT') AS TermNo
            ,pm.query('.').value('(Payment_Method/@tranno)[1]',   'BIGINT') AS TranNo
            ,pm.query('.').value('(Payment_Method/@cardno)[1]',   'VARCHAR(16)') AS CardNo
            ,pm.query('.').value('(Payment_Method/@bank)[1]',     'NVARCHAR(100)') AS Bank
            ,pm.query('.').value('(Payment_Method/@flowno)[1]',   'VARCHAR(20)') AS FlowNo
            ,pm.query('.').value('(Payment_Method/@refno)[1]',    'VARCHAR(20)') AS RefNo
            ,pm.query('.').value('(Payment_Method/@actndate)[1]', 'DATE') AS ActnDate
            ,pm.query('.').value('(Payment_Method/@valdtype)[1]', 'VARCHAR(3)') AS ValdType
            ,CASE pm.query('.').value('(Payment_Method/@rcpttoothracnt)[1]', 'BIGINT')
                  WHEN 0 THEN NULL
                  ELSE pm.query('.').value('(Payment_Method/@rcpttoothracnt)[1]', 'BIGINT')
             END AS RcptToOthrAcnt
            ,pm.query('.').value('(Payment_Method/@rcptfilepath)[1]', 'NVARCHAR(260)') AS RcptFilePath
       FROM @X.nodes('//Insert/Payment_Method') T(pm);
      
      WITH Pmmt(CashCode, RqstRqid, RqroRwno, Rwno, Amnt, RcptMtod, TermNo, TranNo, CardNo, Bank, FlowNo, RefNo, ActnDate, ValdType, RcptToOthrAcnt, RcptFilePath)
      AS (
         SELECT pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT')
               ,pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')
               ,1 
               ,pm.query('.').value('(Payment_Method/@rwno)[1]',     'SMALLINT')
               ,pm.query('.').value('(Payment_Method/@amnt)[1]',     'BIGINT') 
               ,pm.query('.').value('(Payment_Method/@rcptmtod)[1]', 'VARCHAR(3)') AS RcptMtod
			      ,pm.query('.').value('(Payment_Method/@termno)[1]',   'BIGINT') AS TermNo
			      ,pm.query('.').value('(Payment_Method/@tranno)[1]',   'BIGINT') AS TranNo
			      ,pm.query('.').value('(Payment_Method/@cardno)[1]',   'VARCHAR(16)') AS CardNo
			      ,pm.query('.').value('(Payment_Method/@bank)[1]',     'NVARCHAR(100)') AS Bank
			      ,pm.query('.').value('(Payment_Method/@flowno)[1]',   'VARCHAR(20)') AS FlowNo
			      ,pm.query('.').value('(Payment_Method/@refno)[1]',    'VARCHAR(20)') AS RefNo
               ,pm.query('.').value('(Payment_Method/@actndate)[1]', 'DATE') AS ActnDate
               ,pm.query('.').value('(Payment_Method/@valdtype)[1]', 'VARCHAR(3)') AS ValdType
               ,CASE pm.query('.').value('(Payment_Method/@rcpttoothracnt)[1]', 'BIGINT') 
                     WHEN 0 THEN NULL
                     ELSE pm.query('.').value('(Payment_Method/@rcpttoothracnt)[1]', 'BIGINT') 
                END AS RcptToOthrAcnt
               ,pm.query('.').value('(Payment_Method/@rcptfilepath)[1]', 'NVARCHAR(260)') AS RcptFilePath
           FROM @X.nodes('//Update/Payment_Method') T(pm)
      )  
      UPDATE Payment_Method
         SET AMNT = Pmmt.Amnt
            ,ACTN_DATE = Pmmt.ActnDate
            ,RCPT_MTOD = Pmmt.RcptMtod
            ,TERM_NO = Pmmt.TermNo
            ,TRAN_NO = Pmmt.TranNo
            ,CARD_NO = Pmmt.CardNo
            ,BANK = Pmmt.Bank
            ,FLOW_NO = Pmmt.FlowNo
            ,REF_NO = Pmmt.RefNo
            ,VALD_TYPE = Pmmt.ValdType
            ,RCPT_TO_OTHR_ACNT = Pmmt.RcptToOthrAcnt
            ,RCPT_FILE_PATH = Pmmt.RcptFilePath
        FROM Payment_Method INNER JOIN Pmmt
        ON PYMT_CASH_CODE = Pmmt.CashCode
         AND PYMT_RQST_RQID = Pmmt.RqstRqid
         AND RQRO_RWNO = Pmmt.RqroRwno
         AND Payment_Method.RWNO = Pmmt.Rwno
         /*AND RCPT_MTOD != '003'*/;
   END
   ELSE IF @ActnType = 'CheckoutWithoutPOS'
   BEGIN
      INSERT INTO Payment_Method (PYMT_CASH_CODE, PYMT_RQST_RQID, RQRO_RQST_RQID, RQRO_RWNO, RWNO, CODE, AMNT, RCPT_MTOD, ACTN_DATE, VALD_TYPE, RCPT_TO_OTHR_ACNT, RCPT_FILE_PATH)
      SELECT pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AS CashCode
            ,pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT') AS RqstRqid
            ,pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT') AS RqstRqid
            ,1 AS RqroRwno
            ,0 AS Rwno
            ,dbo.GNRT_NVID_U()
            --,pm.query('.').value('(Payment_Method/@amnt)[1]',     'BIGINT') AS Amnt
            ,(SELECT SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT FROM Payment WHERE CASH_CODE = pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AND RQST_RQID = pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')) 
             - ( 
                  COALESCE((SELECT SUM(AMNT) FROM Payment_Method WHERE PYMT_CASH_CODE = pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AND PYMT_RQST_RQID = pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')), 0)
               +  COALESCE((SELECT SUM(AMNT) FROM dbo.Payment_Discount WHERE PYMT_CASH_CODE = pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AND PYMT_RQST_RQID = pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')), 0)
               ) AS Amnt
            ,'001' AS RcptMtod
            ,GETDATE() AS ActnDate
            ,pm.query('.').value('(Payment_Method/@valdtype)[1]', 'VARCHAR(3)') AS ValdType
            ,CASE pm.query('.').value('(Payment_Method/@rcpttoothracnt)[1]', 'BIGINT') 
                  WHEN 0 THEN NULL
                  ELSE pm.query('.').value('(Payment_Method/@rcpttoothracnt)[1]', 'BIGINT') 
             END AS RcptToOthrAcnt
            ,pm.query('.').value('(Payment_Method/@rcptfilepath)[1]', 'NVARCHAR(260)') AS RcptFilePath
       FROM @X.nodes('//Insert/Payment_Method') T(pm);
      
      -- تایید پرداخت بعد از بدهکاری وتسویه حساب
      UPDATE dbo.Payment_Detail
         SET PAY_STAT = '002'
       WHERE PYMT_RQST_RQID = @X.query('//Insert/Payment_Method').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')
         AND PYMT_CASH_CODE = @X.query('//Insert/Payment_Method').value('(Payment_Method/@cashcode)[1]', 'BIGINT')
         AND @X.query('//Insert/Payment_Method').value('(Payment_Method/@paystat)[1]', 'VARCHAR(3)') = '002';
      
      -- فراخوانی و بروزرسانی جداول اصلی
      UPDATE dbo.Fighter
         SET Conf_Stat = Conf_Stat
       WHERE File_No = @X.query('//Insert/Payment_Method').value('(Payment_Method/@fileno)[1]', 'BIGINT')
         AND @X.query('//Insert/Payment_Method').value('(Payment_Method/@paystat)[1]', 'VARCHAR(3)') = '002';
   END
   ELSE IF @ActnType = 'CheckoutWithPOS'
   BEGIN
      INSERT INTO Payment_Method (PYMT_CASH_CODE, PYMT_RQST_RQID, RQRO_RQST_RQID, RQRO_RWNO, RWNO, CODE, AMNT, RCPT_MTOD, TERM_NO, TRAN_NO, CARD_NO, BANK, FLOW_NO, REF_NO, ACTN_DATE, VALD_TYPE, RCPT_TO_OTHR_ACNT, RCPT_FILE_PATH)
      SELECT pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AS CashCode
            ,pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT') AS RqstRqid
            ,pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT') AS RqstRqid
            ,1
            ,0
            ,dbo.GNRT_NVID_U()
            ,CASE ISNULL(pm.query('.').value('(Payment_Method/@amnt)[1]', 'BIGINT'), 0)
                 WHEN 0 THEN 
                  (SELECT SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT FROM Payment WHERE CASH_CODE = pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AND RQST_RQID = pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')) 
                   - ( 
                        COALESCE((SELECT SUM(AMNT) FROM Payment_Method WHERE PYMT_CASH_CODE = pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AND PYMT_RQST_RQID = pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')), 0)
                     +  COALESCE((SELECT SUM(AMNT) FROM dbo.Payment_Discount WHERE PYMT_CASH_CODE = pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AND PYMT_RQST_RQID = pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')), 0)
                     )
                  ELSE 
                   pm.query('.').value('(Payment_Method/@amnt)[1]', 'BIGINT')
            END  AS Amnt            
            ,'003'--pm.query('.').value('(Payment_Method/@rcptmtod)[1]', 'VARCHAR(3)') AS RcptMtod
            ,pm.query('.').value('(Payment_Method/@termno)[1]',   'BIGINT') AS TermNo
            ,pm.query('.').value('(Payment_Method/@tranno)[1]',   'BIGINT') AS TranNo
            ,pm.query('.').value('(Payment_Method/@cardno)[1]',   'VARCHAR(16)') AS CardNo
            ,pm.query('.').value('(Payment_Method/@bank)[1]',     'NVARCHAR(100)') AS Bank
            ,pm.query('.').value('(Payment_Method/@flowno)[1]',   'VARCHAR(20)') AS FlowNo
            ,pm.query('.').value('(Payment_Method/@refno)[1]',    'VARCHAR(20)') AS RefNo
            ,GETDATE()
            ,pm.query('.').value('(Payment_Method/@valdtype)[1]', 'VARCHAR(3)') AS ValdType
            ,CASE pm.query('.').value('(Payment_Method/@rcpttoothracnt)[1]', 'BIGINT') 
                  WHEN 0 THEN NULL
                  ELSE pm.query('.').value('(Payment_Method/@rcpttoothracnt)[1]', 'BIGINT') 
             END AS RcptToOthrAcnt
            ,pm.query('.').value('(Payment_Method/@rcptfilepath)[1]', 'NVARCHAR(260)') AS RcptFilePath
       FROM @X.nodes('//Insert/Payment_Method') T(pm);
      
      -- تایید پرداخت بعد از بدهکاری وتسویه حساب
      UPDATE dbo.Payment_Detail
         SET PAY_STAT = '002'
       WHERE PYMT_RQST_RQID = @X.query('//Insert/Payment_Method').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')
         AND PYMT_CASH_CODE = @X.query('//Insert/Payment_Method').value('(Payment_Method/@cashcode)[1]', 'BIGINT')
         AND @X.query('//Insert/Payment_Method').value('(Payment_Method/@paystat)[1]', 'VARCHAR(3)') = '002';
      
      -- فراخوانی و بروزرسانی جداول اصلی
      UPDATE dbo.Fighter
         SET Conf_Stat = Conf_Stat
       WHERE File_No = @X.query('//Insert/Payment_Method').value('(Payment_Method/@fileno)[1]', 'BIGINT')
         AND @X.query('//Insert/Payment_Method').value('(Payment_Method/@paystat)[1]', 'VARCHAR(3)') = '002';
         
   END
   ELSE IF @ActnType = 'CheckoutWithPOS4Agop'
   BEGIN
      INSERT INTO Payment_Row_Type (APDT_AGOP_CODE, APDT_RWNO, CODE, AMNT, RCPT_MTOD, TERM_NO, TRAN_NO, CARD_NO, BANK, FLOW_NO, REF_NO, ACTN_DATE)
      SELECT pm.query('.').value('(Payment_Method/@apdtagopcode)[1]', 'BIGINT') AS ApdtAgopCode
            ,pm.query('.').value('(Payment_Method/@apdtrwno)[1]', 'BIGINT') AS ApdtRwno            
            ,0
            ,pm.query('.').value('(Payment_Method/@amnt)[1]', 'BIGINT') AS Amnt            
            ,'003'--pm.query('.').value('(Payment_Method/@rcptmtod)[1]', 'VARCHAR(3)') AS RcptMtod
            ,pm.query('.').value('(Payment_Method/@termno)[1]',   'BIGINT') AS TermNo
            ,pm.query('.').value('(Payment_Method/@tranno)[1]',   'BIGINT') AS TranNo
            ,pm.query('.').value('(Payment_Method/@cardno)[1]',   'VARCHAR(16)') AS CardNo
            ,pm.query('.').value('(Payment_Method/@bank)[1]',     'NVARCHAR(100)') AS Bank
            ,pm.query('.').value('(Payment_Method/@flowno)[1]',   'VARCHAR(20)') AS FlowNo
            ,pm.query('.').value('(Payment_Method/@refno)[1]',    'VARCHAR(20)') AS RefNo
            ,GETDATE()
       FROM @X.nodes('//Insert/Payment_Method') T(pm);
   END
   ELSE IF @ActnType = 'CheckoutWithDeposit'
   BEGIN
      INSERT INTO Payment_Method (PYMT_CASH_CODE, PYMT_RQST_RQID, RQRO_RQST_RQID, RQRO_RWNO, RWNO, CODE, AMNT, RCPT_MTOD, ACTN_DATE, VALD_TYPE)
      SELECT pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AS CashCode
            ,pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT') AS RqstRqid
            ,pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT') AS RqstRqid
            ,1 AS RqroRwno
            ,0 AS Rwno
            ,dbo.GNRT_NVID_U()
            ,pm.query('.').value('(Payment_Method/@amnt)[1]',     'BIGINT') AS Amnt
            --,(SELECT SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT FROM Payment WHERE CASH_CODE = pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AND RQST_RQID = pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')) 
            -- - ( 
            --      COALESCE((SELECT SUM(AMNT) FROM Payment_Method WHERE PYMT_CASH_CODE = pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AND PYMT_RQST_RQID = pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')), 0)
            --   +  COALESCE((SELECT SUM(AMNT) FROM dbo.Payment_Discount WHERE PYMT_CASH_CODE = pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AND PYMT_RQST_RQID = pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')), 0)
            --   ) AS Amnt
            ,'005' AS RcptMtod
            ,GETDATE() AS ActnDate
            ,pm.query('.').value('(Payment_Method/@valdtype)[1]', 'VARCHAR(3)') AS ValdType
       FROM @X.nodes('//Insert/Payment_Method') T(pm);
      
      -- تایید پرداخت بعد از بدهکاری وتسویه حساب
      UPDATE dbo.Payment_Detail
         SET PAY_STAT = '002'
       WHERE PYMT_RQST_RQID = @X.query('//Insert/Payment_Method').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')
         AND PYMT_CASH_CODE = @X.query('//Insert/Payment_Method').value('(Payment_Method/@cashcode)[1]', 'BIGINT')
         AND @X.query('//Insert/Payment_Method').value('(Payment_Method/@paystat)[1]', 'VARCHAR(3)') = '002';
      
      -- فراخوانی و بروزرسانی جداول اصلی
      UPDATE dbo.Fighter
         SET Conf_Stat = Conf_Stat
       WHERE File_No = @X.query('//Insert/Payment_Method').value('(Payment_Method/@fileno)[1]', 'BIGINT')
         AND @X.query('//Insert/Payment_Method').value('(Payment_Method/@paystat)[1]', 'VARCHAR(3)') = '002';
   END
   ELSE IF @ActnType = 'CheckoutWithCard2Card'
   BEGIN
      INSERT INTO Payment_Method (PYMT_CASH_CODE, PYMT_RQST_RQID, RQRO_RQST_RQID, RQRO_RWNO, RWNO, CODE, AMNT, RCPT_MTOD, ACTN_DATE, VALD_TYPE, RCPT_TO_OTHR_ACNT, RCPT_FILE_PATH)
      SELECT pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AS CashCode
            ,pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT') AS RqstRqid
            ,pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT') AS RqstRqid
            ,1 AS RqroRwno
            ,0 AS Rwno
            ,dbo.GNRT_NVID_U()
            --,pm.query('.').value('(Payment_Method/@amnt)[1]',     'BIGINT') AS Amnt
            ,(SELECT SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT FROM Payment WHERE CASH_CODE = pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AND RQST_RQID = pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')) 
             - ( 
                  COALESCE((SELECT SUM(AMNT) FROM Payment_Method WHERE PYMT_CASH_CODE = pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AND PYMT_RQST_RQID = pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')), 0)
               +  COALESCE((SELECT SUM(AMNT) FROM dbo.Payment_Discount WHERE PYMT_CASH_CODE = pm.query('.').value('(Payment_Method/@cashcode)[1]', 'BIGINT') AND PYMT_RQST_RQID = pm.query('.').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')), 0)
               ) AS Amnt
            ,'009' AS RcptMtod
            ,GETDATE() AS ActnDate
            ,pm.query('.').value('(Payment_Method/@valdtype)[1]', 'VARCHAR(3)') AS ValdType
            ,CASE pm.query('.').value('(Payment_Method/@rcpttoothracnt)[1]', 'BIGINT') 
                  WHEN 0 THEN NULL
                  ELSE pm.query('.').value('(Payment_Method/@rcpttoothracnt)[1]', 'BIGINT') 
             END AS RcptToOthrAcnt
            ,pm.query('.').value('(Payment_Method/@rcptfilepath)[1]', 'NVARCHAR(260)') AS RcptFilePath
       FROM @X.nodes('//Insert/Payment_Method') T(pm);
      
      -- تایید پرداخت بعد از بدهکاری وتسویه حساب
      UPDATE dbo.Payment_Detail
         SET PAY_STAT = '002'
       WHERE PYMT_RQST_RQID = @X.query('//Insert/Payment_Method').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')
         AND PYMT_CASH_CODE = @X.query('//Insert/Payment_Method').value('(Payment_Method/@cashcode)[1]', 'BIGINT')
         AND @X.query('//Insert/Payment_Method').value('(Payment_Method/@paystat)[1]', 'VARCHAR(3)') = '002';
      
      -- فراخوانی و بروزرسانی جداول اصلی
      UPDATE dbo.Fighter
         SET Conf_Stat = Conf_Stat
       WHERE File_No = @X.query('//Insert/Payment_Method').value('(Payment_Method/@fileno)[1]', 'BIGINT')
         AND @X.query('//Insert/Payment_Method').value('(Payment_Method/@paystat)[1]', 'VARCHAR(3)') = '002';
   END

   COMMIT TRAN PAY_MSAV_P_T1
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN PAY_MSAV_P_T1;
   END CATCH
   
END
   
GO
