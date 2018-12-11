SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_INST_P]
	@X XML
AS
BEGIN
	BEGIN TRY	   
	   BEGIN TRAN T_CRET_INST_P
	   
	   DECLARE @Rqid BIGINT
	          ,@Day INT
	          ,@Count INT
	          ,@FirstDate DATE;
	   
      SELECT @Rqid = @X.query('.').value('(Installment/@rqid)[1]','BIGINT')
            ,@Day = @X.query('.').value('(Installment/@day)[1]','INT')
            ,@Count = @X.query('.').value('(Installment/@cont)[1]','INT')
            ,@FirstDate = @X.query('.').value('(Installment/@frstdate)[1]','DATE');
      
      IF EXISTS(SELECT * FROM dbo.Payment_Check WHERE AMNT_TYPE = '002' AND PYMT_RQST_RQID = @Rqid)
      BEGIN
         RAISERROR (N'برای این هزینه قبلا ردیف اقساط مشخص شده لطفا ردیف های قسط را حذف کنید تا سیستم دوباره قسط بندی را انجام دهد', 16, 1);
      END
      
      IF @FirstDate IS NULL OR @FirstDate = '1900-01-01' SET @FirstDate = GETDATE();
      
      DECLARE @SumExpnPric BIGINT
             ,@CashCode BIGINT;
      SELECT @SumExpnPric = (SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT) - (SUM_RCPT_EXPN_PRIC + SUM_PYMT_DSCN_DNRM)
            ,@CashCode = CASH_CODE
        FROM dbo.Payment
       WHERE RQST_RQID = @Rqid;
      
      DECLARE @i INT = 1
             ,@AmntInst BIGINT = ROUND(@SumExpnPric / @Count, -3)
             ,@DebtAmntDnrm BIGINT = 0
             ,@InstDate DATE = @FirstDate;           
      
      WHILE @i <= @Count
      BEGIN
         IF @i = @Count
            SET @DebtAmntDnrm = 0;
         ELSE
            SET @DebtAmntDnrm = (@SumExpnPric - @AmntInst * @i);
         
         IF @DebtAmntDnrm < 0 SET @DebtAmntDnrm = 0;
         
         INSERT INTO dbo.Payment_Check( 
            PYMT_CASH_CODE ,PYMT_RQST_RQID ,RQRO_RQST_RQID ,RQRO_RWNO ,
            RWNO ,AMNT , DEBT_AMNT_DNRM,AMNT_TYPE ,CHEK_OWNR ,CHEK_NO ,
            CHEK_DATE ,BANK ,RCPT_DATE ,CHEK_TYPE 
         )
         VALUES(
            @CashCode, @Rqid, @Rqid, 1, 
            0, @AmntInst, @DebtAmntDnrm, '002', NULL, NULL, 
            @InstDate, NULL, NULL, NULL
         );
         
         SELECT @InstDate = DATEADD(DAY, @Day, @InstDate)
               ,@i += 1
               ,@AmntInst = CASE WHEN @i = @Count THEN @DebtAmntDnrm ELSE @AmntInst END;
      END      

	   COMMIT TRAN T_CRET_INST_P;	   
	END TRY
	BEGIN CATCH 
	   DECLARE @ErrorMessage NVARCHAR(MAX);
	   SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
	   ROLLBACK TRAN T_CRET_INST_P;
	END CATCH;
END
GO
