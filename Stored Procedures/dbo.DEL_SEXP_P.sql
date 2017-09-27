SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DEL_SEXP_P]   
   @X XML
AS 
   /*
      <Request rqid="">
         <Payment cashcode="">
            <Payment_Detail code=""/>
         </Payment>
      </Request>
   */
BEGIN
   BEGIN TRY
   BEGIN TRAN DEL_SEXP_P_T
      DECLARE @Rqid BIGINT
             ,@PymtCashCode BIGINT
             ,@PymtPydtCode BIGINT;
             
      SELECT @Rqid = @X.query('Request').value('(Request/@rqid)[1]', 'BIGINT')
            ,@PymtCashCode = @X.query('Request/Payment').value('(Payment/@cashcode)[1]', 'BIGINT')
            ,@PymtPydtCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@code)[1]', 'BIGINT');
      
      DELETE Payment_Detail
       WHERE PYMT_RQST_RQID = @Rqid
         AND PYMT_CASH_CODE = @PymtCashCode
         AND CODE = @PymtPydtCode;
         
      COMMIT TRAN DEL_SEXP_P_T;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN DEL_SEXP_P_T;
   END CATCH
END
GO
