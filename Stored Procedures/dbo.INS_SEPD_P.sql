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
             ,@FighFileNo BIGINT
             ,@CbmtCodeDnrm BIGINT
             ,@MbspFilNo BIGINT
             ,@MbspRwno SMALLINT             
             ,@MtodCode BIGINT
             ,@CtgyCode BIGINT
             ,@Exprdate DATETIME
             ,@Cmnt NVARCHAR(500);
             
             
      SELECT @Rqid = @X.query('Request').value('(Request/@rqid)[1]', 'BIGINT')
            ,@PymtCashCode = @X.query('Request/Payment').value('(Payment/@cashcode)[1]', 'BIGINT')
            ,@PymtPydtExpnCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@expncode)[1]', 'BIGINT')
            ,@ExpnPric = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@expnpric)[1]', 'BIGINT')
            ,@PydtDesc = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@pydtdesc)[1]', 'NVARCHAR(250)')
            ,@Qnty = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@qnty)[1]', 'SMALLINT')
            --,@FighFileNo = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@fighfileno)[1]', 'BIGINT')
            ,@CbmtCodeDnrm = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@cbmtcodednrm)[1]', 'BIGINT')
            ,@MbspRwno = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@mbsprwno)[1]', 'SMALLINT')
            ,@Exprdate = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@exprdate)[1]', 'DATETIME')
            ,@Cmnt = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@cmnt)[1]', 'NVARCHAR(500)');
      
      IF @CbmtCodeDnrm = 0 OR @CbmtCodeDnrm IS NULL
      BEGIN
         SET @CbmtCodeDnrm = NULL;
         SET @FighFileNo = NULL;
      END
      ELSE
         SELECT @FighFileNo = COCH_FILE_NO
           FROM dbo.Club_Method
          WHERE code = @CbmtCodeDnrm;
      
      -- 1401/07/23 * روز سرنگونی حکومت کثیف آخوندی
      IF @MbspRwno != 0
      BEGIN      
         SELECT @MbspFilNo = FIGH_FILE_NO
           FROM dbo.Request_Row
          WHERE RQST_RQID = @Rqid;
      END 
      ELSE
      BEGIN
         SET @MbspFilNo = NULL;
         SET @MbspRwno = NULL;
      END 
      
      -- 1397/02/31 
      SELECT @MtodCode = MTOD_CODE
            ,@CtgyCode = CTGY_CODE
        FROM dbo.Expense
       WHERE CODE = @PymtPydtExpnCode;
      
      IF NOT EXISTS(SELECT * FROM Payment_Detail WHERE PYMT_CASH_CODE = @PymtCashCode AND PYMT_RQST_RQID = @Rqid AND EXPN_CODE = @PymtPydtExpnCode)
         INSERT INTO Payment_Detail (PYMT_CASH_CODE, PYMT_RQST_RQID, RQRO_RWNO, EXPN_CODE, EXPN_PRIC, CODE, PYDT_DESC, QNTY, FIGH_FILE_NO, CBMT_CODE_DNRM, EXPR_DATE, MBSP_FIGH_FILE_NO, MBSP_RWNO, MBSP_RECT_CODE)
         VALUES                     (@PymtCashCode, @Rqid, 1, @PymtPydtExpnCode, @ExpnPric, dbo.GNRT_NVID_U(), @PydtDesc, @Qnty, @FighFileNo, @CbmtCodeDnrm, @Exprdate, @MbspFilNo, @MbspRwno, '004');
      ELSE
         UPDATE Payment_Detail
            SET QNTY += @Qnty
               ,FIGH_FILE_NO = @FighFileNo
               ,CBMT_CODE_DNRM = @CbmtCodeDnrm
               ,MTOD_CODE_DNRM = CASE WHEN @CbmtCodeDnrm IS NOT NULL THEN (SELECT MTOD_CODE FROM dbo.Club_Method WHERE CODE = @CbmtCodeDnrm) ELSE @MtodCode END
               ,CTGY_CODE_DNRM = CASE WHEN @CbmtCodeDnrm IS NULL THEN @CtgyCode END
               ,EXPR_DATE = @Exprdate
               ,MBSP_FIGH_FILE_NO = @MbspFilNo
               ,MBSP_RWNO = @MbspRwno
               ,MBSP_RECT_CODE = CASE @MbspRwno WHEN NULL THEN NULL ELSE '004' END
               ,CMNT = @Cmnt
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
