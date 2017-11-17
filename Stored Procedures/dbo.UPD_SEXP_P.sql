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
             ,@FighFileNo BIGINT
             ,@CbmtCodeDnrm BIGINT
             ,@TranStat VARCHAR(3)
             ,@TranBy VARCHAR(250)
             ,@TranDate DATE
             ,@TranCbmtCode BIGINT
             ,@TranMtodCode BIGINT
             ,@TranCtgyCode BIGINT
             ,@TranExpnCode BIGINT;
             
      SELECT @Rqid = @X.query('Request').value('(Request/@rqid)[1]', 'BIGINT')
            ,@PymtCashCode = @X.query('Request/Payment').value('(Payment/@cashcode)[1]', 'BIGINT')
            ,@PymtPydtCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@code)[1]', 'BIGINT')
            ,@ExpnPric = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@expnpric)[1]', 'BIGINT')
            ,@PydtDesc = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@pydtdesc)[1]', 'NVARCHAR(250)')
            ,@Qnty = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@qnty)[1]', 'SMALLINT')
            --,@FighFileNo = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@fighfileno)[1]', 'BIGINT')
            ,@CbmtCodeDnrm = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@cbmtcodednrm)[1]', 'BIGINT')
            ,@TranStat = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@transtat)[1]', 'VARCHAR(3)')
            ,@TranBy = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@tranby)[1]', 'VARCHAR(250)')
            ,@TranDate = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@trandate)[1]', 'DATE')
            ,@TranCbmtCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@trancbmtcode)[1]', 'BIGINT')
            ,@TranMtodCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@tranmtodcode)[1]', 'BIGINT')
            ,@TranCtgyCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@tranctgycode)[1]', 'BIGINT')
            ,@TranExpnCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@tranexpncode)[1]', 'BIGINT');

      IF @CbmtCodeDnrm = 0 OR @CbmtCodeDnrm IS NULL
      BEGIN
         SET @CbmtCodeDnrm = NULL;
         SET @FighFileNo = NULL;
      END
      ELSE
         SELECT @FighFileNo = COCH_FILE_NO
           FROM dbo.Club_Method
          WHERE code = @CbmtCodeDnrm;
      
      IF @TranStat IS NULL
      BEGIN
         SELECT @TranBy = NULL
               ,@TranDate = NULL
               ,@TranCbmtCode = NULL
               ,@TranMtodCode = NULL
               ,@TranCtgyCode = NULL
               ,@TranExpnCode = NULL;                      
      END
      
      UPDATE Payment_Detail
         SET EXPN_PRIC = @ExpnPric
            ,PYDT_DESC = @PydtDesc
            ,QNTY = @Qnty  
            ,FIGH_FILE_NO = @FighFileNo
            ,CBMT_CODE_DNRM = @CbmtCodeDnrm
            ,TRAN_STAT = @TranStat
            ,TRAN_BY = @TranBy
            ,TRAN_DATE = @TranDate
            ,TRAN_CBMT_CODE = @TranCbmtCode
            ,TRAN_MTOD_CODE = @TranMtodCode
            ,TRAN_CTGY_CODE = @TranCtgyCode
            ,TRAN_EXPN_CODE = @TranExpnCode
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
