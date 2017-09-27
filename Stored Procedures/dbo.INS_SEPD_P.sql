SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_SEPD_P]   
   @X XML
AS 
   /*
      <Request rqid="">
         <Payment cashcode="">
            <Payment_Detail code="" expnpric=""/>
         </Payment>
      </Request>
   */
BEGIN
   BEGIN TRY
   BEGIN TRAN INS_SEPD_P_T
      DECLARE @Rqid BIGINT
             ,@PymtCashCode BIGINT
             ,@PymtPydtExpnCode BIGINT
             ,@ExpnPric BIGINT
             ,@PydtDesc NVARCHAR(250)
             ,@Qnty SMALLINT
             ,@FighFileNo BIGINT;
             
      SELECT @Rqid = @X.query('Request').value('(Request/@rqid)[1]', 'BIGINT')
            ,@PymtCashCode = @X.query('Request/Payment').value('(Payment/@cashcode)[1]', 'BIGINT')
            ,@PymtPydtExpnCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@expncode)[1]', 'BIGINT')
            ,@ExpnPric = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@expnpric)[1]', 'BIGINT')
            ,@PydtDesc = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@pydtdesc)[1]', 'NVARCHAR(250)')
            ,@Qnty = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@qnty)[1]', 'SMALLINT')
            ,@FighFileNo = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@fighfileno)[1]', 'BIGINT');
      
      IF NOT EXISTS(SELECT * FROM Payment_Detail WHERE PYMT_CASH_CODE = @PymtCashCode AND PYMT_RQST_RQID = @Rqid AND EXPN_CODE = @PymtPydtExpnCode)
         INSERT INTO Payment_Detail (PYMT_CASH_CODE, PYMT_RQST_RQID, RQRO_RWNO, EXPN_CODE, EXPN_PRIC, CODE, PYDT_DESC, QNTY, FIGH_FILE_NO)
         VALUES                     (@PymtCashCode, @Rqid, 1, @PymtPydtExpnCode, @ExpnPric, dbo.GNRT_NVID_U(), @PydtDesc, @Qnty, CASE WHEN @FighFileNo = 0 THEN NULL ELSE @FighFileNo END);
      ELSE
         UPDATE Payment_Detail
            SET QNTY += @Qnty
               ,FIGH_FILE_NO = CASE WHEN @FighFileNo = 0 THEN NULL ELSE @FighFileNo END
          WHERE PYMT_CASH_CODE = @PymtCashCode
            AND PYMT_RQST_RQID = @Rqid
            AND EXPN_CODE = @PymtPydtExpnCode;   
          
      COMMIT TRAN INS_SEPD_P_T;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN INS_SEPD_P_T;
   END CATCH
END
GO
