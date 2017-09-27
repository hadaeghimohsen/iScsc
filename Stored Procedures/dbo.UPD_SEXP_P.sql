SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPD_SEXP_P]   
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
   BEGIN TRAN UPD_SEXP_P_T
      DECLARE @Rqid BIGINT
             ,@PymtCashCode BIGINT
             ,@PymtPydtCode BIGINT
             ,@ExpnPric BIGINT
             ,@PydtDesc NVARCHAR(250)
             ,@Qnty SMALLINT
             ,@FighFileNo BIGINT;
             
      SELECT @Rqid = @X.query('Request').value('(Request/@rqid)[1]', 'BIGINT')
            ,@PymtCashCode = @X.query('Request/Payment').value('(Payment/@cashcode)[1]', 'BIGINT')
            ,@PymtPydtCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@code)[1]', 'BIGINT')
            ,@ExpnPric = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@expnpric)[1]', 'BIGINT')
            ,@PydtDesc = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@pydtdesc)[1]', 'NVARCHAR(250)')
            ,@Qnty = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@qnty)[1]', 'SMALLINT')
            ,@FighFileNo = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@fighfileno)[1]', 'BIGINT');
      
      UPDATE Payment_Detail
         SET EXPN_PRIC = @ExpnPric
            ,PYDT_DESC = @PydtDesc
            ,QNTY = @Qnty  
            ,FIGH_FILE_NO = CASE WHEN @FighFileNo = 0 THEN NULL ELSE @FighFileNo END          
       WHERE PYMT_RQST_RQID = @Rqid
         AND PYMT_CASH_CODE = @PymtCashCode
         AND CODE = @PymtPydtCode;
         
      COMMIT TRAN UPD_SEXP_P_T;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN UPD_SEXP_P_T;
   END CATCH
END
GO
